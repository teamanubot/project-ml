from sqlalchemy import Column, Integer, String, DateTime, Float, ForeignKey, func
from sqlalchemy.orm import relationship
from app.database import Base

class Analysis(Base):
    __tablename__ = "analyses"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    image_path = Column(String, nullable=True)
    angle = Column(Float, nullable=True)
    analysis_date = Column(DateTime, server_default=func.current_timestamp())
    notes = Column(String, nullable=True)

    user = relationship("User", back_populates="analyses")
