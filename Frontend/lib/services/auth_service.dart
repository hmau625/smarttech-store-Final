import 'package:smarttech_store/config/api_config.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  final String baseUrl = ApiConfig.baseUrl;

  Future<Map<String, dynamic>> login(String correo, String password) async {
  final url = Uri.parse("$baseUrl/auth/login");

  final response = await http.post(
    url,
    headers: {
      "Content-Type": "application/json",
    },
    body: jsonEncode({
      "correo": correo,
      "password": password,
    }),
  );

  print("LOGIN STATUS: ${response.statusCode}");
  print("LOGIN BODY: ${response.body}");

  final data = jsonDecode(response.body);

  if (response.statusCode == 200) {
    return {
      "success": true,
      "token": data["access_token"],
    };
  } else {
    return {
      "success": false,
      "message": data["detail"]["message"],
    };
  }
}
  // ðŸ”¥ REGISTER (ESTO ES LO QUE TE FALTA O ESTÃ MAL)
  Future<Map<String, dynamic>> register(
    String nombre, String correo, String password) async {

  final response = await http.post(
    Uri.parse("$baseUrl/auth/register"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({
      "nombre": nombre,
      "correo": correo,
      "password": password,
    }),
  );

  print("REGISTER STATUS: ${response.statusCode}");
  print("REGISTER BODY: ${response.body}");

  final data = jsonDecode(response.body);

  if (response.statusCode == 200 || response.statusCode == 201) {
    return {
      "success": true,
      "message": "Cuenta creada correctamente",
    };
  } else {
    return {
      "success": false,
      "message": data["detail"]["message"],
    };
  }
}
}