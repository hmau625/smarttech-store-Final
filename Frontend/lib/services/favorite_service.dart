import 'dart:convert';
import 'package:http/http.dart' as http;

class FavoriteService {
  final String baseUrl = "http://localhost:8000";

  Future<bool> addFavorite(String token, int productId) async {
    final res = await http.post(
      Uri.parse("$baseUrl/favorites/$productId"),
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    return res.statusCode == 200;
  }

  Future<bool> removeFavorite(String token, int productId) async {
    final res = await http.delete(
      Uri.parse("$baseUrl/favorites/$productId"),
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    return res.statusCode == 200;
  }

  Future<List<dynamic>> getFavorites(String token) async {
    final res = await http.get(
      Uri.parse("$baseUrl/favorites"),
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }

    return [];
  }
}