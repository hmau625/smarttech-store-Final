import re
import jwt
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import SessionLocal
from app.models.user import User
from passlib.context import CryptContext
from pydantic import BaseModel, EmailStr
from jose import JWTError
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from fastapi import UploadFile, File
import shutil
import os

router = APIRouter(prefix="/auth", tags=["Auth"])

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

SECRET_KEY = "mi_super_secreto"
ALGORITHM = "HS256"

security = HTTPBearer()

# ================= SCHEMAS =================
class UserCreate(BaseModel):
    nombre: str
    correo: EmailStr
    password: str

class UserLogin(BaseModel):
    correo: EmailStr
    password: str

# ================= DB =================
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# ================= AUTH =================
def validar_password(password: str):
    if len(password) < 8:
        return False
    if not re.search(r"[A-Z]", password):
        return False
    if not re.search(r"[a-z]", password):
        return False
    if not re.search(r"[0-9]", password):
        return False
    if not re.search(r"[!@#$%^&*(),.?\":{}|<>]", password):
        return False
    return True

def hash_password(password: str):
    return pwd_context.hash(password[:72])

def verify_password(plain, hashed):
    return pwd_context.verify(plain, hashed)

# ================= REGISTER =================
@router.post("/register")
def register(user: UserCreate, db: Session = Depends(get_db)):

    if not validar_password(user.password):
        raise HTTPException(
            status_code=400,
            detail={
                "error": "password",
                "message": "La contraseña es débil (usa mayúscula, número y símbolo)"
            }
        )

    exists = db.query(User).filter(User.correo == user.correo).first()
    if exists:
        raise HTTPException(
            status_code=400,
            detail={
                "error": "correo",
                "message": "Este correo ya está registrado"
            }
        )

    hashed = hash_password(user.password)

    rol = "admin" if user.correo == "haroldmontenegro84@gmail.com" else "cliente"

    new_user = User(
        nombre=user.nombre,
        correo=user.correo,
        contraseña=hashed,
        rol=rol
    )

    db.add(new_user)
    db.commit()
    db.refresh(new_user)

    return {"message": "Usuario creado"}
# ================= LOGIN =================
@router.post("/login")
def login(user: UserLogin, db: Session = Depends(get_db)):

    db_user = db.query(User).filter(User.correo == user.correo).first()

    if not db_user:
        raise HTTPException(
            status_code=400,
            detail={"error": "correo", "message": "El correo no está registrado"}
        )

    if not verify_password(user.password, db_user.contraseña):
        raise HTTPException(
            status_code=400,
            detail={"error": "password", "message": "La contraseña es incorrecta"}
        )

    token = jwt.encode(
        {"sub": db_user.correo, "role": db_user.rol},
        SECRET_KEY,
        algorithm=ALGORITHM
    )

    return {
        "access_token": token,
        "token_type": "bearer"
    }
# ================= CURRENT USER =================
def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: Session = Depends(get_db)
):

    token = credentials.credentials

    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        correo = payload.get("sub")

        if not correo:
            raise HTTPException(status_code=401, detail="Token inválido")

    except JWTError:
        raise HTTPException(status_code=401, detail="Token inválido")

    user = db.query(User).filter(User.correo == correo).first()

    if not user:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")

    return user

# ================= PROFILE =================
@router.get("/me")
def get_me(current_user: User = Depends(get_current_user)):
    return {
        "id": current_user.id or 0,
        "nombre": current_user.nombre or "",
        "correo": current_user.correo or "",
        "rol": current_user.rol or "cliente",
        "imagen": current_user.imagen or ""
    }

# ================= DELETE ACCOUNT =================
@router.delete("/delete")
def delete_account(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):

    db.delete(current_user)
    db.commit()

    return {"message": "Cuenta eliminada"}

@router.post("/upload-profile")
def upload_profile_image(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    folder = "static/users"

    if not os.path.exists(folder):
        os.makedirs(folder)

    file_path = f"{folder}/user_{current_user.id}.jpg"

    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)

    # guardar ruta en DB
    current_user.imagen = f"http://localhost:8000/{file_path}"
    db.commit()

    return {
        "message": "Imagen subida",
        "url": f"http://localhost:8000/{file_path}"
    }