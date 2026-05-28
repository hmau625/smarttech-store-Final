from app.database import get_connection
from app.utils.security import hash_password, verify_password

def create_user(name, email, password):
    conn = get_connection()
    cursor = conn.cursor()

    hashed_password = hash_password(password)

    cursor.execute(
        "INSERT INTO users (name, email, password) VALUES (%s, %s, %s)",
        (name, email, hashed_password)
    )

    conn.commit()
    conn.close()

    return {"message": "Usuario creado"}

def login_user(email, password):
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)

    cursor.execute("SELECT * FROM users WHERE email=%s", (email,))
    user = cursor.fetchone()

    conn.close()

    if user and verify_password(password, user["password"]):
        return {"message": "Login exitoso"}
    else:
        return {"error": "Credenciales incorrectas"}