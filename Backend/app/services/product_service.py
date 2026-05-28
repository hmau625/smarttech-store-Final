from app.database import get_connection

def create_product(name, price):
    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute(
        "INSERT INTO products (name, price) VALUES (%s, %s)",
        (name, price)
    )

    conn.commit()
    conn.close()

    return {"message": "Producto creado"}

def get_products():
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)

    cursor.execute("SELECT * FROM products")
    products = cursor.fetchall()

    conn.close()

    return products

def update_product(product_id, name, price):
    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute(
        "UPDATE products SET name=%s, price=%s WHERE id=%s",
        (name, price, product_id)
    )

    conn.commit()
    conn.close()

    return {"message": "Producto actualizado"}

def delete_product(product_id):
    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute("DELETE FROM products WHERE id=%s", (product_id,))

    conn.commit()
    conn.close()

    return {"message": "Producto eliminado"}