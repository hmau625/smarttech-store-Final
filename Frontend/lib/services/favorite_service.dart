import 'package:smarttech_store/config/api_config.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class FavoriteService {
  final String baseUrl = ApiConfig.baseUrl;

  Future<bool> addFavorite(String token, int productId) async {
    final res = await http.post(
      Uri.parse("$baseUrl/favorites/$productId"),
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    print('>>> POST favorites/$productId â†’ status: ${res.statusCode} | body: ${res.body}');
    return res.statusCode == 200 || res.statusCode == 201;
  }

  Future<bool> removeFavorite(String token, int productId) async {
    final res = await http.delete(
      Uri.parse("$baseUrl/favorites/$productId"),
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    // ðŸ” TEMPORAL: ver quÃ© responde el servidor exactamente
    print('>>> DELETE favorites/$productId â†’ status: ${res.statusCode} | body: ${res.body}');

    // Acepta cualquier cÃ³digo 2xx como Ã©xito
    return res.statusCode >= 200 && res.statusCode < 300;
  }

  Future<List<dynamic>> getFavorites(String token) async {
    final res = await http.get(
      Uri.parse("$baseUrl/favorites"),
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    print('>>> GET favorites â†’ status: ${res.statusCode}');

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }

    return [];
  }
}