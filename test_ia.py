import numpy as np
import pandas as pd
from sklearn.linear_model import LinearRegression

# Datos de prueba
X = np.array([[1], [2], [3]])
y = np.array([2, 4, 6])

# Crear y entrenar modelo
modelo = LinearRegression()
modelo.fit(X, y)

# Predicción
print("Predicción para 4:", modelo.predict([[4]]))