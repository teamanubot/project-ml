from fastapi import FastAPI, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError
from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime

from app.database import get_db
from app.models.user import User
from app.models.analysis import Analysis

app = FastAPI(title="SpineAnalyzer API")


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
    return {"message": "SpineAnalyzer FastAPI backend ready (SQLite)"}


@app.post("/api/register", response_model=UserOut)
def register(req: RegisterRequest, db: Session = Depends(get_db)):
    user = User(name=req.name, email=req.email, password=req.password)
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
    if not user or user.password != req.password:
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