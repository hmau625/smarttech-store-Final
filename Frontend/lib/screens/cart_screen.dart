import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List cartItems = [];
  bool isLoading = true;

  double totalPrice = 0;
  int totalItems = 0;

  final String baseUrl = "http://127.0.0.1:8000";

  // 🎨 PALETA PRO
  static const _bg = Color(0xFF060D17);
  static const _card = Color(0xFF111E2E);
  static const _accent = Color(0xFF00D4FF);
  static const _textPri = Color(0xFFEFF6FF);
  static const _textSec = Color(0xFF7A9BB5);
  static const _divider = Color(0xFF1A2E44);

  @override
  void initState() {
    super.initState();
    fetchCart();
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  void showMessage(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor:
            error ? Colors.redAccent : Colors.green,
      ),
    );
  }

  int safeInt(dynamic v) =>
      v == null ? 0 : int.tryParse(v.toString()) ?? 0;

  double safeDouble(dynamic v) =>
      v == null ? 0 : double.tryParse(v.toString()) ?? 0;

  Future<void> fetchCart() async {
    final token = await getToken();

    try {
      final res = await http.get(
        Uri.parse("$baseUrl/cart/?token=$token"),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        double total = 0;
        int items = 0;

        for (var item in data) {
          final price = safeDouble(item['price']);
          final qty = safeInt(item['quantity']);

          total += price * qty;
          items += qty;
        }

        setState(() {
          cartItems = data;
          totalPrice = total;
          totalItems = items;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);

      showMessage(
        "Error cargando carrito",
        error: true,
      );
    }
  }

  Future<void> addOne(
    int productId,
    int qty,
    int stock,
  ) async {
    final token = await getToken();

    if (qty >= stock) {
      showMessage(
        "Solo hay $stock disponibles",
        error: true,
      );
      return;
    }

    await http.post(
      Uri.parse(
        "$baseUrl/cart/add?product_id=$productId&token=$token",
      ),
    );

    fetchCart();
  }

  Future<void> removeOne(int productId) async {
    final token = await getToken();

    await http.delete(
      Uri.parse(
        "$baseUrl/cart/remove?product_id=$productId&token=$token",
      ),
    );

    fetchCart();
  }

  Future<void> removeItem(int productId) async {
    final token = await getToken();

    await http.delete(
      Uri.parse(
        "$baseUrl/cart/remove?product_id=$productId&token=$token",
      ),
    );

    fetchCart();
  }

  // 🔥 CARD ITEM PRO
  Widget _cartItem(item) {
    final qty = safeInt(item['quantity']);
    final stock = safeInt(item['stock']);
    final maxStock = qty >= stock;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _divider),
      ),
      child: Row(
        children: [

          // 🖼️ IMAGEN
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: const Color(0xFF0F2A44),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Image.network(
              item['image'] ?? '',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) =>
                  const Icon(
                Icons.image,
                color: Colors.white,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // 📦 INFO
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [

                Text(
                  item['name'] ?? '',
                  style: const TextStyle(
                    color: _textPri,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  "\$${item['price']}",
                  style: const TextStyle(
                    color: _accent,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  "Stock: $stock",
                  style: const TextStyle(
                    color: _textSec,
                  ),
                ),

                if (stock == 0)
                  const Text(
                    "AGOTADO",
                    style: TextStyle(
                      color: Colors.redAccent,
                    ),
                  ),

                if (maxStock && stock > 0)
                  const Text(
                    "Límite alcanzado",
                    style: TextStyle(
                      color: Colors.orangeAccent,
                    ),
                  ),
              ],
            ),
          ),

          // 🔢 CONTADOR PRO
          Row(
            children: [

              _qtyButton(
                icon: Icons.remove,
                onTap: () {
                  if (qty > 1) {
                    removeOne(item['product_id']);
                  } else {
                    removeItem(item['product_id']);
                  }
                },
              ),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                ),
                child: Text(
                  "$qty",
                  style: const TextStyle(
                    color: _textPri,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              _qtyButton(
                icon: Icons.add,
                disabled:
                    maxStock || stock == 0,
                onTap: () {
                  addOne(
                    item['product_id'],
                    qty,
                    stock,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 🔘 BOTÓN CANTIDAD
  Widget _qtyButton({
    required IconData icon,
    required VoidCallback onTap,
    bool disabled = false,
  }) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: disabled
              ? Colors.white.withOpacity(0.05)
              : _accent.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 16,
          color: disabled
              ? _textSec
              : _accent,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,

      // 🔥 APPBAR PRO
      appBar: AppBar(
        backgroundColor:
            const Color(0xFF0F2A44),
        elevation: 0,
        title: Text(
          "Carrito ($totalItems)",
          style: const TextStyle(
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),

      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: _accent,
              ),
            )
          : cartItems.isEmpty
              ? const Center(
                  child: Text(
                    "Carrito vacío 🛒",
                    style: TextStyle(
                      color: Colors.white70,
                    ),
                  ),
                )
              : ListView.builder(
                  padding:
                      const EdgeInsets.all(12),
                  itemCount: cartItems.length,
                  itemBuilder:
                      (context, index) {
                    return _cartItem(
                      cartItems[index],
                    );
                  },
                ),

      // 🔥 FOOTER PRO
      bottomNavigationBar: cartItems.isEmpty
          ? null
          : Container(
              padding:
                  const EdgeInsets.all(16),
              decoration:
                  const BoxDecoration(
                color: _card,
                border: Border(
                  top: BorderSide(
                    color: _divider,
                  ),
                ),
              ),
              child: Column(
                mainAxisSize:
                    MainAxisSize.min,
                children: [

                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .spaceBetween,
                    children: [

                      const Text(
                        "Total",
                        style: TextStyle(
                          color: _textSec,
                        ),
                      ),

                      Text(
                        "\$${totalPrice.toStringAsFixed(2)}",
                        style:
                            const TextStyle(
                          color: _accent,
                          fontWeight:
                              FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style:
                          ElevatedButton.styleFrom(
                        backgroundColor:
                            _accent,
                        padding:
                            const EdgeInsets
                                .symmetric(
                          vertical: 14,
                        ),
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(
                            12,
                          ),
                        ),
                      ),

                      // 🔥 CORREGIDO
                      onPressed: () async {
                        final token =
                            await getToken();

                        if (token == null) {
                          showMessage(
                            "Token inválido",
                            error: true,
                          );
                          return;
                        }

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                CheckoutScreen(
                              total:
                                  totalPrice,
                              token: token,
                            ),
                          ),
                        );
                      },

                      child: const Text(
                        "Finalizar compra",
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}