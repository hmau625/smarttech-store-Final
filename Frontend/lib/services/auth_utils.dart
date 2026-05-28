import 'dart:convert';

class AuthUtils {

  static Map<String, dynamic> decodeToken(String token) {
    final parts = token.split('.');
    final payload = parts[1];

    final normalized = base64Url.normalize(payload);
    final decoded = utf8.decode(base64Url.decode(normalized));

    return jsonDecode(decoded);
  }

  static bool isAdmin(String token) {
    final data = decodeToken(token);
    return data['role'] == 'admin';
  }
}