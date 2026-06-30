# ============================================================
# Script de arreglo automatico - SmartTech Store
# Ejecutar UNA VEZ desde la raiz del proyecto, con PowerShell.
# Como ejecutarlo: clic derecho en la carpeta del proyecto ->
# "Abrir en Terminal" (o "Abrir ventana de PowerShell aqui"),
# luego: .\fix_smarttech.ps1
# ============================================================

$ErrorActionPreference = "Stop"
Write-Host "Iniciando arreglos automaticos..." -ForegroundColor Cyan

if (-not (Test-Path ".\Backend") -or -not (Test-Path ".\Frontend")) {
    Write-Host "ERROR: Este script debe correrse desde la raiz del proyecto (donde estan las carpetas Backend y Frontend)." -ForegroundColor Red
    exit 1
}

# ------------------------------------------------------------
# 1. Backend/app/database.py
# ------------------------------------------------------------
Write-Host "1/7 Arreglando database.py..." -ForegroundColor Yellow
@'
import os
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from dotenv import load_dotenv

load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL")
if not DATABASE_URL:
    raise RuntimeError(
        "Falta DATABASE_URL en las variables de entorno. "
        "Crea un archivo .env (ver .env.example) o configuralo en Railway."
    )

engine = create_engine(
    DATABASE_URL,
    echo=False
)

SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine
)

Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
'@ | Set-Content -Path ".\Backend\app\database.py" -Encoding UTF8

# ------------------------------------------------------------
# 2. Backend/app/core/security.py
# ------------------------------------------------------------
Write-Host "2/7 Arreglando core/security.py..." -ForegroundColor Yellow
@'
import os
from jose import JWTError, jwt
from datetime import datetime, timedelta
from dotenv import load_dotenv

load_dotenv()

SECRET_KEY = os.getenv("JWT_SECRET_KEY")
if not SECRET_KEY:
    raise RuntimeError(
        "Falta JWT_SECRET_KEY en las variables de entorno. "
        "Crea un archivo .env (ver .env.example) o configuralo en Railway."
    )
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60


def create_access_token(data: dict):
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)


def verify_token(token: str):
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        return payload
    except JWTError:
        return None
'@ | Set-Content -Path ".\Backend\app\core\security.py" -Encoding UTF8

# ------------------------------------------------------------
# 3. Backend/app/services/email_service.py (solo el encabezado)
# ------------------------------------------------------------
Write-Host "3/7 Arreglando email_service.py..." -ForegroundColor Yellow
$emailFile = ".\Backend\app\services\email_service.py"
$content = Get-Content -Path $emailFile -Raw

$oldHeader = @'
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

# ═══════════════════════════════════════════════════════════════════
# CONFIGURA TU GMAIL AQUÍ
# 1. Ve a https://myaccount.google.com/apppasswords
# 2. Crea una "Contraseña de aplicación" (necesitas 2FA activado)
# 3. Pega la contraseña de 16 caracteres abajo
# ═══════════════════════════════════════════════════════════════════
SMTP_EMAIL    = "smart.tech6913@gmail.com"
SMTP_PASSWORD = "jpjv hjev eies wqnx"
SMTP_HOST     = "smtp.gmail.com"
SMTP_PORT     = 587
'@

$newHeader = @'
import os
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from dotenv import load_dotenv

load_dotenv()

SMTP_EMAIL    = os.getenv("SMTP_EMAIL")
SMTP_PASSWORD = os.getenv("SMTP_PASSWORD")
SMTP_HOST     = os.getenv("SMTP_HOST", "smtp.gmail.com")
SMTP_PORT     = int(os.getenv("SMTP_PORT", "587"))
'@

if ($content.Contains("smart.tech6913@gmail.com")) {
    $content = $content.Replace($oldHeader, $newHeader)
    Set-Content -Path $emailFile -Value $content -Encoding UTF8 -NoNewline
    Write-Host "   -> email_service.py actualizado." -ForegroundColor Green
} else {
    Write-Host "   -> AVISO: email_service.py ya parece modificado, no se toco. Revisalo a mano." -ForegroundColor Magenta
}

# ------------------------------------------------------------
# 4. Backend/requirements.txt
# ------------------------------------------------------------
Write-Host "4/7 Arreglando requirements.txt..." -ForegroundColor Yellow
@'
fastapi==0.135.1
uvicorn[standard]==0.42.0
pydantic==2.12.5
pydantic_core==2.41.5
email-validator==2.2.0
python-dotenv==1.0.1

SQLAlchemy==2.0.36
mysql-connector-python==9.1.0

python-jose[cryptography]==3.3.0
PyJWT==2.10.1
passlib[bcrypt]==1.7.4
bcrypt==4.0.1

httpx==0.28.1
python-multipart==0.0.20
'@ | Set-Content -Path ".\Backend\requirements.txt" -Encoding UTF8

# ------------------------------------------------------------
# 5. Backend/.env.example y Backend/.env
# ------------------------------------------------------------
Write-Host "5/7 Creando .env.example y .env..." -ForegroundColor Yellow
$jwtKey = -join ((1..32) | ForEach-Object { "{0:x2}" -f (Get-Random -Maximum 256) })

@"
DATABASE_URL=mysql+mysqlconnector://root:TU_PASSWORD_NUEVO@127.0.0.1/smarttech_store
JWT_SECRET_KEY=$jwtKey
SMTP_EMAIL=tu_correo@gmail.com
SMTP_PASSWORD=tu_nueva_contrasena_de_aplicacion_de_16_caracteres
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
AI_API_KEY=tu_api_key_de_google_ai_studio
"@ | Set-Content -Path ".\Backend\.env.example" -Encoding UTF8

if (-not (Test-Path ".\Backend\.env")) {
    Copy-Item ".\Backend\.env.example" ".\Backend\.env"
    Write-Host "   -> Backend\.env creado con una JWT_SECRET_KEY nueva ya generada." -ForegroundColor Green
    Write-Host "   -> ABRELO Y RELLENA: DATABASE_URL (password de MySQL), SMTP_PASSWORD (password de Gmail), AI_API_KEY si la usas." -ForegroundColor Magenta
} else {
    Write-Host "   -> Backend\.env ya existia, no se toco." -ForegroundColor Magenta
}

# ------------------------------------------------------------
# 6. Frontend: centralizar la URL del backend
# ------------------------------------------------------------
Write-Host "6/7 Centralizando URL del backend en Flutter..." -ForegroundColor Yellow

New-Item -ItemType Directory -Force -Path ".\Frontend\lib\config" | Out-Null
@'
/// Configuracion centralizada de la URL del backend.
/// Para cambiar de entorno (local vs produccion), modifica SOLO esta linea.
class ApiConfig {
  // PRODUCCION: reemplaza por tu URL real de Railway cuando despliegues, ej:
  // static const String baseUrl = "https://smarttech-backend.up.railway.app";
  static const String baseUrl = "http://localhost:8000";
}
'@ | Set-Content -Path ".\Frontend\lib\config\api_config.dart" -Encoding UTF8

$importLine = "import 'package:smarttech_store/config/api_config.dart';"

$targets = @(
    @{ Path = ".\Frontend\lib\services\api_service.dart";        Old = 'static const String _host = "http://localhost:8000";'; New = 'static const String _host = ApiConfig.baseUrl;' },
    @{ Path = ".\Frontend\lib\services\checkout_service.dart";   Old = 'static const String baseUrl = "http://127.0.0.1:8000";'; New = 'static const String baseUrl = ApiConfig.baseUrl;' },
    @{ Path = ".\Frontend\lib\services\admin_service.dart";      Old = 'final String baseUrl = "http://localhost:8000";';        New = 'final String baseUrl = ApiConfig.baseUrl;' },
    @{ Path = ".\Frontend\lib\services\product_service.dart";    Old = 'final String baseUrl = "http://localhost:8000";';        New = 'final String baseUrl = ApiConfig.baseUrl;' },
    @{ Path = ".\Frontend\lib\services\favorite_service.dart";   Old = 'final String baseUrl = "http://localhost:8000";';        New = 'final String baseUrl = ApiConfig.baseUrl;' },
    @{ Path = ".\Frontend\lib\services\auth_service.dart";       Old = 'final String baseUrl = "http://localhost:8000"; // 🔥 WEB'; New = 'final String baseUrl = ApiConfig.baseUrl;' },
    @{ Path = ".\Frontend\lib\services\user_service.dart";       Old = 'final String baseUrl = "http://localhost:8000";';        New = 'final String baseUrl = ApiConfig.baseUrl;' },
    @{ Path = ".\Frontend\lib\screens\cart_screen.dart";             Old = 'final String baseUrl = "http://127.0.0.1:8000";'; New = 'final String baseUrl = ApiConfig.baseUrl;' },
    @{ Path = ".\Frontend\lib\screens\orders_screen.dart";           Old = 'final String baseUrl = "http://localhost:8000";'; New = 'final String baseUrl = ApiConfig.baseUrl;' },
    @{ Path = ".\Frontend\lib\screens\product_detail_screen.dart";   Old = 'final String _baseUrl = "http://localhost:8000";'; New = 'final String _baseUrl = ApiConfig.baseUrl;' },
    @{ Path = ".\Frontend\lib\screens\nathalia_chat_screen.dart";    Old = 'final String _baseUrl = "http://localhost:8000";'; New = 'final String _baseUrl = ApiConfig.baseUrl;' },
    @{ Path = ".\Frontend\lib\screens\payment_detail_screen.dart";   Old = 'final baseUrl = "http://127.0.0.1:8000";';         New = 'final baseUrl = ApiConfig.baseUrl;' }
)

foreach ($t in $targets) {
    if (Test-Path $t.Path) {
        $c = Get-Content -Path $t.Path -Raw
        if ($c.Contains($t.Old)) {
            $c = $c.Replace($t.Old, $t.New)
            if (-not $c.Contains($importLine)) {
                $c = "$importLine`r`n$c"
            }
            Set-Content -Path $t.Path -Value $c -Encoding UTF8 -NoNewline
            Write-Host "   -> $($t.Path) actualizado." -ForegroundColor Green
        } else {
            Write-Host "   -> AVISO: no se encontro el texto esperado en $($t.Path), revisalo a mano." -ForegroundColor Magenta
        }
    } else {
        Write-Host "   -> AVISO: no existe $($t.Path), se omite." -ForegroundColor Magenta
    }
}

# ------------------------------------------------------------
# 7. .gitignore
# ------------------------------------------------------------
Write-Host "7/7 Actualizando .gitignore..." -ForegroundColor Yellow
@'
# Entornos virtuales de Python (NO se suben a git)
venv/
entorno_ia/
*/venv/
.venv/

# Cache de Python
__pycache__/
*.pyc
*.pyo

# Variables de entorno con secretos (NO se suben a git)
.env
Backend/.env

# Flutter
Frontend/build/
Frontend/.dart_tool/
Frontend/.flutter-plugins
Frontend/.flutter-plugins-dependencies

# Sistema
.DS_Store
Thumbs.db
'@ | Set-Content -Path ".\.gitignore" -Encoding UTF8

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "LISTO. Siguientes pasos manuales:" -ForegroundColor Cyan
Write-Host "1. Abre Backend\.env y rellena DATABASE_URL, SMTP_PASSWORD y AI_API_KEY con tus valores reales." -ForegroundColor White
Write-Host "2. Corre: git rm -r --cached Backend/venv entorno_ia Backend/app/__pycache__" -ForegroundColor White
Write-Host "3. Corre: git add -A" -ForegroundColor White
Write-Host "4. Corre: git commit -m 'Seguridad: variables de entorno + limpieza de repo'" -ForegroundColor White
Write-Host "5. Corre: git push" -ForegroundColor White
Write-Host "================================================" -ForegroundColor Cyan
