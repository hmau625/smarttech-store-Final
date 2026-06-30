import 'package:smarttech_store/config/api_config.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AdminService {
  final String baseUrl = ApiConfig.baseUrl;
  final String token;

  AdminService({required this.token});

  Map<String, String> get headers => {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      };

  Future<Map<String, dynamic>> getStats() async {
    final res = await http.get(Uri.parse("$baseUrl/admin/stats"), headers: headers);
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception("Error stats: ${res.body}");
  }

  Future<List<dynamic>> getTopProducts({int limit = 6}) async {
    final res = await http.get(Uri.parse("$baseUrl/admin/products/top?limit=$limit"), headers: headers);
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception("Error top products: ${res.body}");
  }

  Future<List<dynamic>> getStock({String filter = "all"}) async {
    final res = await http.get(Uri.parse("$baseUrl/admin/stock?filter=$filter"), headers: headers);
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception("Error stock: ${res.body}");
  }

  Future<List<dynamic>> getTopClients({int limit = 5}) async {
    final res = await http.get(Uri.parse("$baseUrl/admin/clients/top?limit=$limit"), headers: headers);
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception("Error clients: ${res.body}");
  }

  Future<List<dynamic>> getOrders({String? estado}) async {
    final url = estado != null ? "$baseUrl/admin/orders?estado=$estado" : "$baseUrl/admin/orders";
    final res = await http.get(Uri.parse(url), headers: headers);
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception("Error orders: ${res.body}");
  }

  Future<Map<String, dynamic>> getOrderDetail(int pedidoId) async {
    final res = await http.get(Uri.parse("$baseUrl/admin/orders/$pedidoId"), headers: headers);
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception("Error order detail: ${res.body}");
  }

  Future<bool> updateOrderStatus(int pedidoId, String nuevoEstado) async {
    final res = await http.patch(
      Uri.parse("$baseUrl/admin/orders/$pedidoId/status"),
      headers: headers,
      body: jsonEncode({"estado": nuevoEstado}),
    );
    return res.statusCode == 200;
  }

  // â”€â”€ Reponer stock â”€â”€
  Future<bool> restockProduct(int productId, int units) async {
    final res = await http.patch(
      Uri.parse("$baseUrl/admin/stock/$productId/restock"),
      headers: headers,
      body: jsonEncode({"units": units}),
    );
    return res.statusCode == 200;
  }
}