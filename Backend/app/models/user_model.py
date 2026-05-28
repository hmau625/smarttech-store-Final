from sqlalchemy import Column, Integer, String
from app.database import Base

class User(Base):
    __tablename__ = "usuarios"

    id = Column(Integer, primary_key=True, index=True)
    nombre = Column(String)
    correo = Column(String, unique=True, index=True)
    contraseña = Column(String)
    rol = Column(String)
    imagen = Column(String, nullable=True)