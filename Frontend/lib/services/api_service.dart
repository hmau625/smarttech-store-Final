import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';

class ApiService {
  final String baseUrl = "http://localhost:8000"; // 🔥 importante para web
  final String? token;

  ApiService({this.token});

  // 🔐 HEADERS
  Map<String, String> get headers => {
        "Content-Type": "application/json",
        if (token != null) "Authorization": "Bearer $token",
      };

  // 📦 OBTENER PRODUCTOS
  Future<List<Product>> getProducts() async {
    final response = await http.get(
      Uri.parse("$baseUrl/products/"), // 🔥 IMPORTANTE /
      headers: headers,
    );

    print("GET PRODUCTS => ${response.body}");

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Product.fromJson(e)).toList();
    } else {
      throw Exception("Error al cargar productos: ${response.body}");
    }
  }

  // ➕ CREAR PRODUCTO
  Future<void> createProduct(Product product) async {
    final response = await http.post(
      Uri.parse("$baseUrl/products/"),
      headers: headers,
      body: jsonEncode(product.toJson()),
    );

    print("CREATE => ${response.body}");

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception("Error al crear producto: ${response.body}");
    }
  }

  // ✏️ ACTUALIZAR PRODUCTO
  Future<void> updateProduct(Product product) async {
    final response = await http.put(
      Uri.parse("$baseUrl/products/${product.id}"),
      headers: headers,
      body: jsonEncode(product.toJson()),
    );

    print("UPDATE => ${response.body}");

    if (response.statusCode != 200) {
      throw Exception("Error al actualizar producto: ${response.body}");
    }
  }

  // 🗑 ELIMINAR PRODUCTO
  Future<void> deleteProduct(int id) async {
    final response = await http.delete(
      Uri.parse("$baseUrl/products/$id"),
      headers: headers,
    );

    print("DELETE => ${response.body}");

    if (response.statusCode != 200) {
      throw Exception("Error al eliminar producto: ${response.body}");
    }
  }
  // ❤️ FAVORITOS - OBTENER
Future<List<dynamic>> getFavorites(String token) async {
  final res = await http.get(
    Uri.parse("$baseUrl/favorites/"),
    headers: {
      "Authorization": "Bearer $token",
    },
  );

  return jsonDecode(res.body);
}

// ❤️ AGREGAR FAVORITO
Future<bool> addFavorite(String token, int productId) async {
  final res = await http.post(
    Uri.parse("$baseUrl/favorites/$productId"),
    headers: {
      "Authorization": "Bearer $token",
    },
  );

  return res.statusCode == 200;
}

// 💔 QUITAR FAVORITO
Future<bool> removeFavorite(String token, int productId) async {
  final res = await http.delete(
    Uri.parse("$baseUrl/favorites/$productId"),
    headers: {
      "Authorization": "Bearer $token",
    },
  );

  return res.statusCode == 200;
}
}
