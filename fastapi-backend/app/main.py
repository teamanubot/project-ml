from fastapi import FastAPI, Depends, HTTPException, File, UploadFile
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError
from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime


from app.database import get_db
from app.models.user import User
from app.models.analysis import Analysis
from app.utils import hash_password, verify_password
from app.ml.analysis import SpineAnalyzer
import numpy as np
from PIL import Image
import io


from app.database import Base, engine

app = FastAPI(title="SpineAnalyzer API")

# Inisialisasi SpineAnalyzer ML pipeline
spine_analyzer = SpineAnalyzer()
from fastapi.responses import JSONResponse
@app.post("/api/analyze-spine")
async def analyze_spine(file: UploadFile = File(...)):
    # Baca file gambar
    contents = await file.read()
    image = Image.open(io.BytesIO(contents))
    # 1. Klasifikasi kondisi tulang belakang
    klasifikasi = spine_analyzer.classify_spine(image)
    nama_kelas = klasifikasi['class']
    probabilitas = klasifikasi['probs']
    kepercayaan = klasifikasi['confidence']
    # 2. Deteksi keypoint
    hasil_keypoint = spine_analyzer.detect_keypoints(image)
    # 3. Deteksi kelurusan tulang belakang (opsional, bisa dipakai untuk analisis tambahan)
    hasil_lurus = spine_analyzer.detect_straight_spine(image)
    # 4. Hitung derajat kemiringan (Cobb angle, dll) jika keypoint valid
    if hasil_keypoint.get('coordinates'):
        angles = spine_analyzer.calculate_angles([v for pair in hasil_keypoint['coordinates'] for v in pair])
    else:
        angles = None
    # 5. Respons dalam Bahasa Indonesia
    response = {
        "kelas_prediksi": nama_kelas,
        "kepercayaan": kepercayaan,
        "probabilitas_kelas": probabilitas,
        "keypoints": hasil_keypoint.get('coordinates'),
        "jumlah_keypoint_valid": hasil_keypoint.get('valid_keypoints') if 'valid_keypoints' in hasil_keypoint else None,
        "confidences": hasil_keypoint.get('confidences'),
        "catatan_keypoint": hasil_keypoint.get('note') if 'note' in hasil_keypoint else hasil_keypoint.get('error'),
        "sudut": angles,
        "analisis_lurus": {
            "penilaian": hasil_lurus['assessment'],
            "skor_kelurusan": hasil_lurus['straightness_score'],
            "cobb_angle": hasil_lurus['cobb_angle'],
            "kepercayaan": hasil_lurus['confidence']
        }
    }
    return JSONResponse(response)

@app.post("/api/debug-keypoint")
async def debug_keypoint(file: UploadFile = File(...)):
    """
    Endpoint debug: print output mentah model keypoint (shape, nilai, thresholding)
    """
    contents = await file.read()
    image = Image.open(io.BytesIO(contents))
    img = image.convert('RGB').resize((256, 256))
    arr = np.array(img, dtype=np.float32)
    # Histogram equalization (per channel, sama seperti pipeline utama)
    for c in range(3):
        hist, bins = np.histogram(arr[..., c].flatten(), 256, [0,256])
        cdf = hist.cumsum()
        cdf_m = np.ma.masked_equal(cdf,0)
        cdf_m = (cdf_m - cdf_m.min())*255/(cdf_m.max()-cdf_m.min())
        cdf = np.ma.filled(cdf_m,0).astype('float32')
        arr[..., c] = cdf[arr[..., c].astype('uint8')]
    arr = arr / 255.0
    arr = np.expand_dims(arr, axis=0)
    interpreter = spine_analyzer.keypoint_detector.get_interpreter()
    interpreter.allocate_tensors()
    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()
    interpreter.set_tensor(input_details[0]['index'], arr)
    interpreter.invoke()
    output = interpreter.get_tensor(output_details[0]['index'])[0]
    # Info shape dan nilai
    info = {
        "output_shape": str(output.shape),
        "output_raw": output.tolist(),
        "output_len": len(output),
    }
    # Jika output >=34, pisahkan koordinat dan confidence
    if len(output) >= 34:
        coords = output[:34].reshape((17, 2)).tolist()
        confs = output[34:34+17].tolist()
        valid = sum([1 for c in confs if c > 0.2])
        info["coords"] = coords
        info["confidences"] = confs
        info["valid_keypoints"] = valid
    elif len(output) == 17:
        info["confidences"] = output.tolist()
        info["note"] = "Model hanya mengembalikan confidence, tidak ada koordinat"
    else:
        info["error"] = f"Output keypoints tidak sesuai, panjang: {len(output)}"
    return JSONResponse(info)

# Inisialisasi tabel otomatis saat startup
@app.on_event("startup")
def on_startup():
    Base.metadata.create_all(bind=engine)


class RegisterRequest(BaseModel):
    name: str
    email: str
    password: str


class LoginRequest(BaseModel):
    email: str
    password: str


class UserOut(BaseModel):
    id: int
    name: str
    email: str
    created_at: Optional[datetime] = None

    class Config:
        from_attributes = True


class AnalysisOut(BaseModel):
    id: int
    user_id: int
    image_path: Optional[str] = None
    angle: Optional[float] = None
    analysis_date: Optional[datetime] = None
    notes: Optional[str] = None

    class Config:
        from_attributes = True


@app.get("/")
def root():
    return {"message": "SpineAnalyzer FastAPI backend ready (Mysql)"}


@app.post("/api/register", response_model=UserOut)
def register(req: RegisterRequest, db: Session = Depends(get_db)):
    hashed_pw = hash_password(req.password)
    user = User(name=req.name, email=req.email, password=hashed_pw)
    db.add(user)
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(status_code=400, detail="Email already registered")
    db.refresh(user)
    return user


@app.post("/api/login", response_model=UserOut)
def login(req: LoginRequest, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == req.email).first()
    if not user or not verify_password(req.password, user.password):
        raise HTTPException(status_code=401, detail="Invalid credentials")
    return user


@app.get("/api/users", response_model=List[UserOut])
def get_users(db: Session = Depends(get_db)):
    return db.query(User).all()


@app.get("/api/analyses", response_model=List[AnalysisOut])
def get_analyses(db: Session = Depends(get_db)):
    return db.query(Analysis).all()

@app.get("/api/history/{user_id}", response_model=List[AnalysisOut])
def get_user_history(user_id: int, db: Session = Depends(get_db)):
    return db.query(Analysis).filter(Analysis.user_id == user_id).order_by(Analysis.analysis_date.desc()).all()