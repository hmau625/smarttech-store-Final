import 'package:smarttech_store/config/api_config.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class UserService {
  final String baseUrl = ApiConfig.baseUrl;

  // ================= GET USER =================
  Future<Map<String, dynamic>?> getMe(String token) async {
    final response = await http.get(
      Uri.parse("$baseUrl/auth/me"),
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    print("ME STATUS: ${response.statusCode}");
    print("ME BODY: ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return null;
    }
  }

  // ================= DELETE ACCOUNT =================
  Future<bool> deleteAccount(String token) async {
    final response = await http.delete(
      Uri.parse("$baseUrl/auth/delete"),
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    print("DELETE STATUS: ${response.statusCode}");
    print("DELETE BODY: ${response.body}");

    return response.statusCode == 200;
  }

  // ================= UPLOAD PROFILE IMAGE =================
  Future<String?> uploadProfileImage(
    String token,
    Uint8List bytes,
    String fileName,
  ) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/auth/upload-profile'),
      );

      request.headers['Authorization'] = 'Bearer $token';

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: fileName,
        ),
      );

      var response = await request.send();

      print("UPLOAD STATUS: ${response.statusCode}");

      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();

        print("UPLOAD BODY: $respStr");

        final data = jsonDecode(respStr);

        // ðŸ”¥ devuelve la URL de la imagen
        return data['url'];
      } else {
        print("ERROR UPLOAD: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("UPLOAD EXCEPTION: $e");
      return null;
    }
  }

  // ================= REMOVE PROFILE IMAGE =================
  Future<bool> removeProfileImage(String token) async {
    try {
      final response = await http.delete(
        Uri.parse("$baseUrl/auth/remove-profile"),
        headers: {
          "Authorization": "Bearer $token",
        },
      );

      print("REMOVE IMAGE STATUS: ${response.statusCode}");
      print("REMOVE IMAGE BODY: ${response.body}");

      return response.statusCode == 200;
    } catch (e) {
      print("REMOVE IMAGE EXCEPTION: $e");
      return false;
    }
  }
}