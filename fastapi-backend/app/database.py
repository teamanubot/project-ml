from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base

DATABASE_URL = "sqlite:///./spine_analyzer.db"
# Kalau path absolut, formatnya:
# DATABASE_URL = "sqlite:////root/project-ml/fastapi-backend/spine_analyzer.db"

engine = create_engine(
    DATABASE_URL,
    connect_args={"check_same_thread": False},  # khusus SQLite
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
