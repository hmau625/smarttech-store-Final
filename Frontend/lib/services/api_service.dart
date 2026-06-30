import 'package:smarttech_store/config/api_config.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../models/product.dart';

class ApiService {
  // ðŸ”¥ CAMBIAR ESTA LÃNEA AL SUBIR A PRODUCCIÃ“N
  static const String _host = ApiConfig.baseUrl;

  final String baseUrl = _host;
  final String? token;

  ApiService({this.token});

  Map<String, String> get headers => {
        "Content-Type": "application/json",
        if (token != null) "Authorization": "Bearer $token",
      };

  // ðŸ”¥ RESOLVER URL DE IMAGEN
  // /static/products/xxx.jpg â†’ http://localhost:8000/static/products/xxx.jpg
  // https://ejemplo.com/img.jpg â†’ se queda igual
  static String resolveImage(String? image) {
    if (image == null || image.isEmpty) return '';
    if (image.startsWith('http')) return image;
    return '$_host$image';
  }

  // ðŸ“¦ OBTENER PRODUCTOS
  Future<List<Product>> getProducts() async {
    final response = await http.get(
      Uri.parse("$baseUrl/products/"),
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

  // âž• CREAR PRODUCTO
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

  // âœï¸ ACTUALIZAR PRODUCTO
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

  // ðŸ—‘ ELIMINAR PRODUCTO
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

  // ðŸ–¼ SUBIR IMAGEN â€” recibe bytes para compatibilidad web
  Future<String?> uploadProductImage(
      Uint8List fileBytes, String fileName) async {
    final uri = Uri.parse("$baseUrl/products/upload-image");

    final request = http.MultipartRequest("POST", uri);

    // Agrega token si existe
    if (token != null) {
      request.headers["Authorization"] = "Bearer $token";
    }

    // Adjunta el archivo como bytes (funciona en web y mÃ³vil)
    request.files.add(http.MultipartFile.fromBytes(
      "file",
      fileBytes,
      filename: fileName,
    ));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    print("UPLOAD IMAGE => ${response.statusCode} | ${response.body}");

    if (response.statusCode == 200) {
      // El backend puede devolver la URL como string o dentro de un JSON
      final body = response.body.trim();
      // Si viene como JSON: {"url": "http://..."} o {"image_url": "/static/..."}
      if (body.startsWith('{')) {
        final json = jsonDecode(body);
        return json['url'] ?? json['image_url'] ?? json['filename'];
      }
      // Si viene como string directo
      return body.replaceAll('"', '');
    }
    return null;
  }

  // â¤ï¸ FAVORITOS
  Future<List<dynamic>> getFavorites(String token) async {
    final res = await http.get(
      Uri.parse("$baseUrl/favorites/"),
      headers: {"Authorization": "Bearer $token"},
    );
    return jsonDecode(res.body);
  }

  Future<bool> addFavorite(String token, int productId) async {
    final res = await http.post(
      Uri.parse("$baseUrl/favorites/$productId"),
      headers: {"Authorization": "Bearer $token"},
    );
    return res.statusCode == 200 || res.statusCode == 201;
  }

  Future<bool> removeFavorite(String token, int productId) async {
    final res = await http.delete(
      Uri.parse("$baseUrl/favorites/$productId"),
      headers: {"Authorization": "Bearer $token"},
    );
    return res.statusCode >= 200 && res.statusCode < 300;
  }
}