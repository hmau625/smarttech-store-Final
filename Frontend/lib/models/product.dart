class Product {
  final int? id;
  final String name;
  final double price;
  final String? category;
  final String? brand;
  final int? stock;
  final String? image;
  final Map<String, dynamic>? specs;

  // ✅ CORRECTO - todos los parámetros nombrados dentro de {}
  Product({
    this.id,
    required this.name,
    required this.price,
    this.category,
    this.brand,
    this.stock,
    this.image,
    this.specs,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json["id"],
      name: json["name"],
      price: (json["price"] as num).toDouble(),
      category: json["category"],
      brand: json["brand"],
      stock: json["stock"],
      image: json["image"],
      specs: json["specs"] is Map
          ? Map<String, dynamic>.from(json["specs"])
          : null, // ✅ cast seguro
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "price": price,
      "category": category,
      "brand": brand,
      "stock": stock,
      "image": image,
      "specs": specs,
    };
  }
}