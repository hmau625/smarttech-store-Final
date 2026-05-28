import 'package:jwt_decoder/jwt_decoder.dart';

class AuthUtils {

  // 🔓 Decodificar token seguro
  static Map<String, dynamic> decodeToken(String? token) {
    try {
      if (token == null || token.isEmpty) {
        return {};
      }
      return JwtDecoder.decode(token);
    } catch (e) {
      print("ERROR DECODING TOKEN => $e");
      return {};
    }
  }

  // 👤 Obtener rol
  static String? getRole(String? token) {
    final decoded = decodeToken(token);
    return decoded["role"];
  }

  // 👑 Verificar si es admin
  static bool isAdmin(String? token) {
    return getRole(token) == "admin";
  }

  // ⏳ Verificar expiración
  static bool isExpired(String? token) {
    try {
      if (token == null || token.isEmpty) return true;
      return JwtDecoder.isExpired(token);
    } catch (e) {
      return true;
    }
  }
}