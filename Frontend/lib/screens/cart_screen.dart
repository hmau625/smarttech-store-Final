import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smarttech_store/services/api_service.dart';
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

  static const _bg      = Color(0xFF060D17);
  static const _surface = Color(0xFF0D1F33);
  static const _card    = Color(0xFF111E2E);
  static const _accent  = Color(0xFF00D4FF);
  static const _textPri = Color(0xFFEFF6FF);
  static const _textSec = Color(0xFF7A9BB5);
  static const _divider = Color(0xFF1A2E44);

  String _fmtPrice(dynamic v) {
    final amount = (v as num).toDouble();
    final parts = amount.toStringAsFixed(2).split('.');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return '\$$intPart.${parts[1]}';
  }

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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(error ? Icons.error_outline : Icons.check_circle_outline,
            color: error ? Colors.redAccent : const Color(0xFF4CAF50), size: 16),
        const SizedBox(width: 8),
        Text(msg, style: const TextStyle(color: _textPri, fontSize: 13)),
      ]),
      backgroundColor: _surface,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
            color: (error ? Colors.redAccent : const Color(0xFF4CAF50)).withOpacity(0.35)),
      ),
      duration: const Duration(seconds: 2),
    ));
  }

  int safeInt(dynamic v) => v == null ? 0 : int.tryParse(v.toString()) ?? 0;
  double safeDouble(dynamic v) => v == null ? 0 : double.tryParse(v.toString()) ?? 0;

  Future<void> fetchCart() async {
    final token = await getToken();
    try {
      final res = await http.get(Uri.parse("$baseUrl/cart/?token=$token"));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        double total = 0;
        int items = 0;
        for (var item in data) {
          total += safeDouble(item['price']) * safeInt(item['quantity']);
          items += safeInt(item['quantity']);
        }
        setState(() {
          cartItems  = data;
          totalPrice = total;
          totalItems = items;
          isLoading  = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
      showMessage("Error cargando carrito", error: true);
    }
  }

  Future<void> addOne(int productId, int qty, int stock) async {
    if (qty >= stock) { showMessage("Solo hay $stock disponibles", error: true); return; }
    final token = await getToken();
    await http.post(Uri.parse("$baseUrl/cart/add?product_id=$productId&token=$token"));
    fetchCart();
  }

  Future<void> removeOne(int productId) async {
    final token = await getToken();
    await http.delete(Uri.parse("$baseUrl/cart/remove?product_id=$productId&token=$token"));
    fetchCart();
  }

  Future<void> removeItem(int productId) async {
    final token = await getToken();
    await http.delete(Uri.parse("$baseUrl/cart/remove?product_id=$productId&token=$token"));
    fetchCart();
  }

  // ── Resumen antes de pagar ──
  void _showOrderSummary(String token) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: _divider, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            const Text("Resumen del pedido",
                style: TextStyle(color: _textPri, fontWeight: FontWeight.w800, fontSize: 17)),
            const SizedBox(height: 16),
            ...cartItems.map((item) {
              final qty      = safeInt(item['quantity']);
              final price    = safeDouble(item['price']);
              final subtotal = qty * price;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(ApiService.resolveImage(item['image']),
                          width: 44, height: 44, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(8)),
                              child: const Icon(Icons.image_outlined, color: _textSec, size: 18))),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['name'] ?? '',
                              style: const TextStyle(color: _textPri, fontWeight: FontWeight.w600, fontSize: 13),
                              overflow: TextOverflow.ellipsis),
                          Text("x$qty  —  ${_fmtPrice(price)} c/u",
                              style: const TextStyle(color: _textSec, fontSize: 11)),
                        ],
                      ),
                    ),
                    Text(_fmtPrice(subtotal),
                        style: const TextStyle(color: _accent, fontWeight: FontWeight.w700, fontSize: 13)),
                  ],
                ),
              );
            }),
            Divider(color: _divider),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Total", style: TextStyle(color: _textPri, fontWeight: FontWeight.w700, fontSize: 15)),
                Text(_fmtPrice(totalPrice),
                    style: const TextStyle(color: _accent, fontWeight: FontWeight.w800, fontSize: 20)),
              ],
            ),
            const SizedBox(height: 20),

            // ── Botón Confirmar (MEJORADO) ──
            Center(
              child: GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => CheckoutScreen(total: totalPrice, token: token),
                  ));
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00D4FF), Color(0xFF0090B8)],
                    ),
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(color: _accent.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.check_circle_outline, color: Colors.black, size: 18),
                      SizedBox(width: 8),
                      Text("Confirmar y pagar",
                          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: 0.3)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cartItem(dynamic item, int index) {
    final qty      = safeInt(item['quantity']);
    final stock    = safeInt(item['stock']);
    final maxStock = qty >= stock;
    final subtotal = safeDouble(item['price']) * qty;

    return Dismissible(
      key: Key("cart_${item['product_id']}_$index"),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.redAccent.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.redAccent.withOpacity(0.40)),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 24),
            SizedBox(height: 4),
            Text("Eliminar", style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          barrierColor: Colors.black.withOpacity(0.60),
          builder: (_) => Dialog(
            backgroundColor: _surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.10),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.redAccent.withOpacity(0.30)),
                    ),
                    child: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 28),
                  ),
                  const SizedBox(height: 16),
                  const Text("¿Eliminar producto?",
                      style: TextStyle(color: _textPri, fontWeight: FontWeight.w800, fontSize: 16)),
                  const SizedBox(height: 8),
                  const Text("Se quitará del carrito",
                      style: TextStyle(color: _textSec, fontSize: 13)),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context, false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _divider, borderRadius: BorderRadius.circular(12)),
                            child: const Text("Cancelar",
                                textAlign: TextAlign.center,
                                style: TextStyle(color: _textSec, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context, true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withOpacity(0.14),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.redAccent.withOpacity(0.40)),
                            ),
                            child: const Text("Eliminar",
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ) ?? false;
      },
      onDismissed: (_) {
        removeItem(item['product_id']);
        showMessage("Producto eliminado del carrito");
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: stock == 0 ? Colors.redAccent.withOpacity(0.35) : _divider),
        ),
        child: Row(
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFF0F2A44),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Image.network(ApiService.resolveImage(item['image']), fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.image_outlined, color: _textSec, size: 26)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['name'] ?? '',
                      style: const TextStyle(color: _textPri, fontWeight: FontWeight.w700, fontSize: 14),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text("${_fmtPrice(safeDouble(item['price']))} c/u",
                          style: const TextStyle(color: _textSec, fontSize: 12)),
                      const SizedBox(width: 8),
                      Text("= ${_fmtPrice(subtotal)}",
                          style: const TextStyle(color: _accent, fontWeight: FontWeight.w700, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (stock == 0)
                    const Text("AGOTADO",
                        style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.w700))
                  else if (maxStock)
                    Text("Límite: $stock uds",
                        style: const TextStyle(color: Colors.orangeAccent, fontSize: 11))
                  else
                    Text("Stock: $stock",
                        style: const TextStyle(color: _textSec, fontSize: 11)),
                ],
              ),
            ),
            Column(
              children: [
                _qtyButton(
                  icon: Icons.add,
                  disabled: maxStock || stock == 0,
                  onTap: () => addOne(item['product_id'], qty, stock),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text("$qty",
                      style: const TextStyle(color: _textPri, fontWeight: FontWeight.w800, fontSize: 16)),
                ),
                _qtyButton(
                  icon: Icons.remove,
                  onTap: () => qty > 1
                      ? removeOne(item['product_id'])
                      : removeItem(item['product_id']),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _qtyButton({required IconData icon, required VoidCallback onTap, bool disabled = false}) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: disabled ? Colors.white.withOpacity(0.04) : _accent.withOpacity(0.14),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: disabled ? _divider : _accent.withOpacity(0.35)),
        ),
        child: Icon(icon, size: 15, color: disabled ? _textSec : _accent),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        elevation: 0,
        leading: const BackButton(color: _accent),
        title: Text(
          totalItems > 0 ? "Carrito  ($totalItems)" : "Carrito",
          style: const TextStyle(color: _textPri, fontWeight: FontWeight.w800, fontSize: 20),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _divider),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: _accent, strokeWidth: 2))
          : cartItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: _card, shape: BoxShape.circle,
                          border: Border.all(color: _accent.withOpacity(0.20)),
                          boxShadow: [BoxShadow(color: _accent.withOpacity(0.08), blurRadius: 24, spreadRadius: 4)],
                        ),
                        child: Icon(Icons.shopping_cart_outlined, size: 52, color: _accent.withOpacity(0.5)),
                      ),
                      const SizedBox(height: 22),
                      const Text("Carrito vacío",
                          style: TextStyle(color: _textPri, fontSize: 20, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      const Text("Agrega productos para empezar",
                          style: TextStyle(color: _textSec, fontSize: 13)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: _accent,
                  backgroundColor: _card,
                  onRefresh: fetchCart,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: cartItems.length,
                    itemBuilder: (_, i) => _cartItem(cartItems[i], i),
                  ),
                ),
      bottomNavigationBar: cartItems.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              decoration: BoxDecoration(
                color: _card,
                border: Border(top: BorderSide(color: _divider)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Total", style: TextStyle(color: _textSec, fontSize: 13)),
                          Text(_fmtPrice(totalPrice),
                              style: const TextStyle(
                                  color: _accent, fontWeight: FontWeight.w800, fontSize: 22)),
                        ],
                      ),
                      Text("$totalItems ${totalItems == 1 ? 'producto' : 'productos'}",
                          style: const TextStyle(color: _textSec, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // ── Botón Finalizar (MEJORADO) ──
                  Center(
                    child: GestureDetector(
                      onTap: () async {
                        final token = await getToken();
                        if (token == null) { showMessage("Token inválido", error: true); return; }
                        _showOrderSummary(token);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00D4FF), Color(0xFF0090B8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(50),
                          boxShadow: [
                            BoxShadow(color: _accent.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.shopping_bag_outlined, color: Colors.black, size: 18),
                            SizedBox(width: 8),
                            Text("Finalizar compra",
                                style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: 0.3)),
                          ],
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