import 'package:smarttech_store/config/api_config.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ProductService {
  final String baseUrl = ApiConfig.baseUrl;

  Future<List<dynamic>> getProducts() async {
    final response = await http.get(
      Uri.parse("$baseUrl/products/"),
    );

    print("PRODUCTS STATUS: ${response.statusCode}");
    print("PRODUCTS BODY: ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Error al cargar productos");
    }
  }
}