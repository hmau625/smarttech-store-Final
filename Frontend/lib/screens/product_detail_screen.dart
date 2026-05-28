import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/product.dart';
import 'cart_screen.dart';
import 'edit_product_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  final String token;

  const ProductDetailScreen({
    super.key,
    required this.product,
    required this.token,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int quantity = 1;
  bool isAdmin = false;
  bool isDeleting = false;

  static const _bg = Color(0xFF060D17);
  static const _card = Color(0xFF111E2E);
  static const _accent = Color(0xFF00D4FF);
  static const _textPri = Color(0xFFEFF6FF);
  static const _textSec = Color(0xFF7A9BB5);
  static const _divider = Color(0xFF1A2E44);

  @override
  void initState() {
    super.initState();
    checkAdmin();
  }

  Future<void> checkAdmin() async {
    final response = await http.get(
      Uri.parse("http://localhost:8000/auth/me"),
      headers: {"Authorization": "Bearer ${widget.token}"},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() => isAdmin = data['rol'] == "admin");
    }
  }

  Future<void> addToCart(int productId) async {
    final url = Uri.parse(
      "http://localhost:8000/cart/add?product_id=$productId&token=${widget.token}",
    );

    await http.post(url);
  }

  Future<void> addMultipleToCart() async {
    final stock = widget.product.stock ?? 0;

    if (stock <= 0) {
      _msg("Sin stock", true);
      return;
    }

    if (quantity > stock) {
      _msg("Solo hay $stock disponibles", true);
      return;
    }

    for (int i = 0; i < quantity; i++) {
      await addToCart(widget.product.id!);
    }

    _msg("Añadido al carrito");
  }

  Future<void> deleteProduct() async {
    setState(() => isDeleting = true);

    final url = Uri.parse(
      "http://localhost:8000/products/${widget.product.id}",
    );

    try {
      final response = await http.delete(
        url,
        headers: {"Authorization": "Bearer ${widget.token}"},
      );

      if (response.statusCode == 200) {
        _msg("Producto eliminado");

        await Future.delayed(const Duration(milliseconds: 300));

        if (mounted) Navigator.pop(context);
      } else {
        _msg("Error al eliminar", true);
      }
    } catch (e) {
      _msg("Error de conexión", true);
    }

    setState(() => isDeleting = false);
  }

  void showDeleteSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Eliminar producto",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Esta acción no se puede deshacer",
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancelar"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      onPressed: isDeleting
                          ? null
                          : () {
                              Navigator.pop(context);
                              deleteProduct();
                            },
                      child: isDeleting
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text("Eliminar"),
                    ),
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  void _msg(String msg, [bool error = false]) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? Colors.red : Colors.green,
      ),
    );
  }

  Widget _section(Widget child) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _divider),
      ),
      child: child,
    );
  }

  Widget _specRow(String key, String value, {bool last = false}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              SizedBox(
                width: 110,
                child: Text(
                  key,
                  style: const TextStyle(
                    color: _textSec,
                    fontSize: 11,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    color: _textPri,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!last)
          Divider(color: _divider.withOpacity(0.4), thickness: 0.5),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final stock = product.stock ?? 0;

    return Scaffold(
      backgroundColor: _bg,

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CartScreen()),
              );
            },
          )
        ],
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [
            // IMAGE
            SizedBox(
              height: 260,
              child: Image.network(product.image ?? "", fit: BoxFit.contain),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // INFO
                  _section(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: const TextStyle(
                            color: _textPri,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "\$${product.price}",
                          style: const TextStyle(
                            color: _accent,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          stock > 0 ? "$stock disponibles" : "Sin stock",
                          style: TextStyle(
                            color: stock > 0
                                ? Colors.greenAccent
                                : Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // QUANTITY
                  _section(
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Cantidad",
                            style: TextStyle(color: _textPri)),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () {
                                if (quantity > 1) {
                                  setState(() => quantity--);
                                }
                              },
                              icon: const Icon(Icons.remove,
                                  color: Colors.white),
                            ),
                            Text("$quantity",
                                style: const TextStyle(color: Colors.white)),
                            IconButton(
                              onPressed: () {
                                if (quantity < stock) {
                                  setState(() => quantity++);
                                }
                              },
                              icon: const Icon(Icons.add,
                                  color: Colors.white),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // SPECS
                  if (product.specs != null &&
                      product.specs!.isNotEmpty)
                    _section(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Especificaciones",
                            style: TextStyle(
                              color: _textPri,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...product.specs!.entries
                              .toList()
                              .asMap()
                              .entries
                              .map((entry) => _specRow(
                                    entry.value.key,
                                    entry.value.value.toString(),
                                    last: entry.key ==
                                        product.specs!.length - 1,
                                  )),
                        ],
                      ),
                    ),

                  const SizedBox(height: 12),

                  // 🔥 ADMIN BUTTONS
                  if (isAdmin)
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                            ),
                            icon: const Icon(Icons.edit),
                            label: const Text("Editar"),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      EditProductScreen(product: product),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            icon: const Icon(Icons.delete),
                            label: const Text("Eliminar"),
                            onPressed: showDeleteSheet,
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 20),

                  // CART BUTTON
                  GestureDetector(
                    onTap: addMultipleToCart,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: _accent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          "Añadir al carrito",
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}