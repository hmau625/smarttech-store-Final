class Product {
  final int? id;
  final String name;
  final double price;

  final String? category;
  final String? brand;
  final int? stock;
  final String? image;
  final Map<String, dynamic>? specs; // 🔥 CAMBIO AQUÍ

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
      specs: json["specs"], // 🔥 YA NO ES STRING
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
      "specs": specs, // 🔥 ENVÍA COMO JSON
    };
  }
}