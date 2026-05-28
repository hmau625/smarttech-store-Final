import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CheckoutService {
  static const String baseUrl = "http://127.0.0.1:8000";

  Future<bool> realizarCheckout({
    required String metodoPago,
    required String nombre,
    required String apellido,
    required String tipoDocumento,
    required String documento,
    required String pais,
    required String ciudad,
    required String direccion,
    required String fechaEntrega,
    required String referenciaPago,
  }) async {

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse("$baseUrl/checkout/");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "token": token, // 🔥 CLAVE
        "metodo_pago": metodoPago,

        "nombre": nombre,
        "apellido": apellido,
        "tipo_documento": tipoDocumento,
        "documento": documento,

        "pais": pais,
        "departamento": "",
        "ciudad": ciudad,
        "direccion": direccion,

        "fecha_entrega": fechaEntrega,
        "referencia_pago": referenciaPago
      }),
    );

    print("RESP: ${response.body}");

    return response.statusCode == 200;
  }
}