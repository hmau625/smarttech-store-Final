import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

class UserService {
  final String baseUrl = "http://localhost:8000";

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

  // ================= DELETE =================
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

  // ================= UPLOAD IMAGE (FIX 🔥) =================
  Future<String?> uploadProfileImage(String token, XFile file) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/auth/upload-profile'),
    );

    request.headers['Authorization'] = 'Bearer $token';

    // 🔥 IMPORTANTE: usar bytes (funciona en web y PC)
    Uint8List bytes = await file.readAsBytes();

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: file.name,
      ),
    );

    var response = await request.send();

    if (response.statusCode == 200) {
      final respStr = await response.stream.bytesToString();
      final data = jsonDecode(respStr);

      print("UPLOAD OK: $data");

      return data['url'];
    } else {
      print("ERROR UPLOAD: ${response.statusCode}");
      return null;
    }
  }
}