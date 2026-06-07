import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/product.dart';
import '../services/api_service.dart';
import 'cart_screen.dart';
import 'edit_product_screen.dart';
import 'nathalia_chat_screen.dart';

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

  // ── Reseñas ──
  List<dynamic> reviews = [];
  bool loadingReviews = true;
  int? currentUserId;
  double _newRating = 0;
  final _commentCtrl = TextEditingController();
  final _replyCtrl   = TextEditingController();
  int? _replyingTo;
  bool _submitting = false;

  static const _bg      = Color(0xFF060D17);
  static const _surface = Color(0xFF0D1F33);
  static const _card    = Color(0xFF111E2E);
  static const _accent  = Color(0xFF00D4FF);
  static const _textPri = Color(0xFFEFF6FF);
  static const _textSec = Color(0xFF7A9BB5);
  static const _divider = Color(0xFF1A2E44);

  final String _baseUrl = "http://localhost:8000";

  @override
  void initState() {
    super.initState();
    checkAdmin();
    _loadReviews();
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    _replyCtrl.dispose();
    super.dispose();
  }

  // ── Formato precio ────────────────────────────────────────────────────────
  String _formatPrice(dynamic raw) {
    if (raw == null) return '\$0';
    final value = (raw is num) ? raw.toDouble() : double.tryParse(raw.toString()) ?? 0.0;
    final intPart = value.toInt();
    final decimals = value - intPart;
    final buf = StringBuffer();
    final digits = intPart.toString();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buf.write('.');
      buf.write(digits[i]);
    }
    return decimals > 0.001
        ? '\$${buf.toString()},${(decimals * 100).round().toString().padLeft(2, '0')}'
        : '\$${buf.toString()}';
  }

  Future<void> checkAdmin() async {
    final response = await http.get(
      Uri.parse("$_baseUrl/auth/me"),
      headers: {"Authorization": "Bearer ${widget.token}"},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        isAdmin = data['rol'] == "admin";
        currentUserId = data['id'];
      });
    }
  }

  // ── Reseñas CRUD ──────────────────────────────────────────────────────────

  Future<void> _loadReviews() async {
    try {
      final res = await http.get(Uri.parse("$_baseUrl/reviews/${widget.product.id}"));
      if (res.statusCode == 200) {
        setState(() { reviews = jsonDecode(res.body); loadingReviews = false; });
      } else {
        setState(() => loadingReviews = false);
      }
    } catch (_) {
      setState(() => loadingReviews = false);
    }
  }

  Future<void> _submitReview() async {
    if (_newRating < 0.5) return _msg("Selecciona al menos media estrella", true);
    if (_commentCtrl.text.trim().isEmpty) return _msg("Escribe un comentario", true);
    setState(() => _submitting = true);
    try {
      final res = await http.post(
        Uri.parse("$_baseUrl/reviews/"),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer ${widget.token}"},
        body: jsonEncode({"product_id": widget.product.id, "rating": _newRating, "comment": _commentCtrl.text.trim()}),
      );
      if (res.statusCode == 200) {
        _commentCtrl.clear(); _newRating = 0;
        _msg("Reseña publicada"); _loadReviews();
      } else {
        final data = jsonDecode(res.body);
        _msg(data['detail'] ?? "Error al publicar", true);
      }
    } catch (_) { _msg("Error de conexión", true); }
    setState(() => _submitting = false);
  }

  Future<void> _submitReply(int reviewId) async {
    if (_replyCtrl.text.trim().isEmpty) return _msg("Escribe una respuesta", true);
    setState(() => _submitting = true);
    try {
      final res = await http.post(
        Uri.parse("$_baseUrl/reviews/$reviewId/reply"),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer ${widget.token}"},
        body: jsonEncode({"comment": _replyCtrl.text.trim()}),
      );
      if (res.statusCode == 200) {
        _replyCtrl.clear(); _replyingTo = null;
        _msg("Respuesta publicada"); _loadReviews();
      } else { _msg("Error al responder", true); }
    } catch (_) { _msg("Error de conexión", true); }
    setState(() => _submitting = false);
  }

  Future<void> _deleteReview(int reviewId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("¿Eliminar reseña?", style: TextStyle(color: _textPri)),
        content: const Text("Esta acción no se puede deshacer", style: TextStyle(color: _textSec)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancelar", style: TextStyle(color: _textSec))),
          TextButton(onPressed: () => Navigator.pop(context, true),
              child: const Text("Eliminar", style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      final res = await http.delete(
        Uri.parse("$_baseUrl/reviews/$reviewId"),
        headers: {"Authorization": "Bearer ${widget.token}"},
      );
      if (res.statusCode == 200) { _msg("Reseña eliminada"); _loadReviews(); }
      else { _msg("Error al eliminar", true); }
    } catch (_) { _msg("Error de conexión", true); }
  }

  // ── Producto CRUD ─────────────────────────────────────────────────────────

  Future<void> addToCart(int productId) async {
    final url = Uri.parse("$_baseUrl/cart/add?product_id=$productId&token=${widget.token}");
    await http.post(url);
  }

  Future<void> addMultipleToCart() async {
    final stock = widget.product.stock ?? 0;
    if (stock <= 0) { _msg("Sin stock", true); return; }
    if (quantity > stock) { _msg("Solo hay $stock disponibles", true); return; }
    for (int i = 0; i < quantity; i++) await addToCart(widget.product.id!);
    _msg("Añadido al carrito");
  }

  Future<void> deleteProduct() async {
    setState(() => isDeleting = true);
    try {
      final response = await http.delete(
        Uri.parse("$_baseUrl/products/${widget.product.id}"),
        headers: {"Authorization": "Bearer ${widget.token}"},
      );
      if (response.statusCode == 200) {
        _msg("Producto eliminado");
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) Navigator.pop(context);
      } else { _msg("Error al eliminar", true); }
    } catch (e) { _msg("Error de conexión", true); }
    setState(() => isDeleting = false);
  }

  void showDeleteSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Eliminar producto",
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text("Esta acción no se puede deshacer", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancelar"))),
              const SizedBox(width: 10),
              Expanded(child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: isDeleting ? null : () { Navigator.pop(context); deleteProduct(); },
                  child: isDeleting
                      ? const SizedBox(height: 18, width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text("Eliminar"))),
            ])
          ],
        ),
      ),
    );
  }

  void _msg(String msg, [bool error = false]) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: error ? Colors.red : Colors.green),
    );
  }

  // ── Widgets base ──────────────────────────────────────────────────────────

  Widget _section(Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _divider),
      ),
      child: child,
    );
  }

  Widget _specRow(String key, String value, {bool last = false}) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          SizedBox(width: 110, child: Text(key, style: const TextStyle(color: _textSec, fontSize: 11))),
          Expanded(child: Text(value, style: const TextStyle(color: _textPri, fontSize: 12, fontWeight: FontWeight.w600))),
        ]),
      ),
      if (!last) Divider(color: _divider.withOpacity(0.4), thickness: 0.5),
    ]);
  }

  // ── Estrellas ─────────────────────────────────────────────────────────────

  Widget _stars(double rating, {double size = 16, bool interactive = false, Function(double)? onTap}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final starValue = i + 1.0;
        final halfValue = i + 0.5;
        IconData icon;
        Color color;
        if (rating >= starValue) { icon = Icons.star_rounded; color = const Color(0xFFFFCA28); }
        else if (rating >= halfValue) { icon = Icons.star_half_rounded; color = const Color(0xFFFFCA28); }
        else { icon = Icons.star_outline_rounded; color = _textSec.withOpacity(0.4); }

        if (!interactive) {
          return Padding(padding: const EdgeInsets.only(right: 2), child: Icon(icon, color: color, size: size));
        }
        return GestureDetector(
          onTapDown: (details) {
            if (onTap == null) return;
            onTap(details.localPosition.dx < size / 2 ? halfValue : starValue);
          },
          child: Padding(padding: const EdgeInsets.only(right: 2),
              child: SizedBox(width: size, height: size, child: Icon(icon, color: color, size: size))),
        );
      }),
    );
  }

  Widget _ratingHeader() {
    if (reviews.isEmpty) {
      return const Text("Sin reseñas aún", style: TextStyle(color: _textSec, fontSize: 13));
    }
    final avg = reviews.fold<double>(0, (s, r) => s + (r['rating'] as num).toDouble()) / reviews.length;
    return Row(children: [
      _stars(avg),
      const SizedBox(width: 8),
      Text(avg.toStringAsFixed(1), style: const TextStyle(color: _accent, fontWeight: FontWeight.w800, fontSize: 18)),
      const SizedBox(width: 6),
      Text("(${reviews.length})", style: const TextStyle(color: _textSec, fontSize: 12)),
    ]);
  }

  Widget _reviewCard(Map<String, dynamic> review, {bool isReply = false}) {
    final canDelete = isAdmin || review['user_id'] == currentUserId;
    final replies = review['replies'] as List? ?? [];

    return Container(
      margin: EdgeInsets.only(bottom: 12, left: isReply ? 24 : 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isReply ? const Color(0xFF0D1926) : _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isReply ? _divider.withOpacity(0.5) : _divider),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFF1A2E44),
            backgroundImage: review['user_image'] != null && review['user_image'].toString().startsWith('http')
                ? NetworkImage(review['user_image']) : null,
            child: review['user_image'] == null || !review['user_image'].toString().startsWith('http')
                ? const Icon(Icons.person, size: 16, color: _textSec) : null,
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(review['user_name'] ?? 'Usuario',
                style: const TextStyle(color: _textPri, fontWeight: FontWeight.w700, fontSize: 13)),
            if (!isReply) _stars((review['rating'] as num?)?.toDouble() ?? 0, size: 14),
          ])),
          if (canDelete)
            GestureDetector(
              onTap: () => _deleteReview(review['id']),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 16),
              ),
            ),
        ]),
        if (review['comment'] != null && review['comment'].toString().isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(review['comment'], style: const TextStyle(color: _textPri, fontSize: 13, height: 1.4)),
        ],
        const SizedBox(height: 8),
        if (!isReply)
          GestureDetector(
            onTap: () => setState(() {
              _replyingTo = _replyingTo == review['id'] ? null : review['id'];
              _replyCtrl.clear();
            }),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.reply_rounded, color: _accent.withOpacity(0.7), size: 16),
              const SizedBox(width: 4),
              Text(_replyingTo == review['id'] ? "Cancelar" : "Responder",
                  style: TextStyle(color: _accent.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.w600)),
            ]),
          ),
        if (_replyingTo == review['id']) ...[
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: TextField(
              controller: _replyCtrl,
              style: const TextStyle(color: _textPri, fontSize: 13),
              decoration: InputDecoration(
                hintText: "Escribe una respuesta...",
                hintStyle: TextStyle(color: _textSec.withOpacity(0.5), fontSize: 12),
                filled: true, fillColor: const Color(0xFF0A1929),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            )),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _submitting ? null : () => _submitReply(review['id']),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: _accent, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.send_rounded, color: Colors.black, size: 18),
              ),
            ),
          ]),
        ],
        if (replies.isNotEmpty) ...[
          const SizedBox(height: 10),
          ...replies.map<Widget>((r) => _reviewCard(r as Map<String, dynamic>, isReply: true)),
        ],
      ]),
    );
  }

  Widget _newReviewForm() {
    final ratingLabel = _newRating == 0
        ? "Toca una estrella"
        : "${_newRating.toStringAsFixed(1)} de 5.0";

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text("Tu reseña", style: TextStyle(color: _textPri, fontWeight: FontWeight.w700, fontSize: 14)),
      const SizedBox(height: 10),
      Row(children: [
        _stars(_newRating, size: 32, interactive: true, onTap: (v) => setState(() => _newRating = v)),
        const SizedBox(width: 10),
        Flexible(child: Text(ratingLabel, style: const TextStyle(color: _textSec, fontSize: 11))),
      ]),
      const SizedBox(height: 10),
      TextField(
        controller: _commentCtrl,
        maxLines: 3,
        style: const TextStyle(color: _textPri, fontSize: 13),
        decoration: InputDecoration(
          hintText: "¿Qué opinas de este producto?",
          hintStyle: TextStyle(color: _textSec.withOpacity(0.5), fontSize: 12),
          filled: true, fillColor: const Color(0xFF0A1929),
          contentPadding: const EdgeInsets.all(14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
      ),
      const SizedBox(height: 10),
      GestureDetector(
        onTap: _submitting ? null : _submitReview,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: _submitting ? _accent.withOpacity(0.5) : _accent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: _submitting
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                : const Text("Publicar reseña",
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 14)),
          ),
        ),
      ),
    ]);
  }

  // ── AppBar personalizado ──────────────────────────────────────────────────
  Widget _buildAppBar() {
    return Container(
      color: _surface,
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Fila logo + carrito
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Row(
                children: [
                  // Logo → vuelve al list
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Row(children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _accent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _accent.withOpacity(0.30), width: 1.5),
                        ),
                        child: const Icon(Icons.memory, color: _accent, size: 20),
                      ),
                      const SizedBox(width: 8),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                        Text("SmartTech",
                            style: TextStyle(color: _textPri, fontWeight: FontWeight.w800,
                                fontSize: 16, letterSpacing: 0.8)),
                        Text("STORE",
                            style: TextStyle(color: _accent, fontWeight: FontWeight.w600,
                                fontSize: 8, letterSpacing: 4.0)),
                      ]),
                    ]),
                  ),
                  const Spacer(),
                  // Carrito
                  GestureDetector(
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const CartScreen())),
                    child: Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: _accent.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(color: _accent.withOpacity(0.18), width: 1),
                      ),
                      child: const Icon(Icons.shopping_cart_outlined, color: _textPri, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            // Botón volver
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.arrow_back_ios_new_rounded, color: _textSec, size: 13),
                    const SizedBox(width: 6),
                    const Text("Volver",
                        style: TextStyle(color: _textSec, fontSize: 13, fontWeight: FontWeight.w500)),
                  ]),
                ),
              ),
            ),
            Container(height: 1, color: _divider),
          ],
        ),
      ),
    );
  }

  // ── Footer ────────────────────────────────────────────────────────────────
  Widget _buildFooter() {
    return Container(
      color: _bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(height: 1, color: _divider),
          // Mini stats
          Container(
            color: _surface,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            child: Row(children: [
              _footerStat("24/7", "Soporte IA"),
              _footerDiv(),
              _footerStat("48h", "Envío express"),
              _footerDiv(),
              _footerStat("100%", "Garantía"),
              _footerDiv(),
              _footerStat("SSL", "Seguro"),
            ]),
          ),
          Container(height: 1, color: _divider),
          // Info + Nathalia
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: LayoutBuilder(builder: (ctx, constraints) {
              final isWide = constraints.maxWidth > 480;
              if (isWide) {
                return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(flex: 5, child: _colInfo()),
                  const SizedBox(width: 20),
                  Expanded(flex: 4, child: _colNathalia()),
                ]);
              }
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _colInfo(),
                const SizedBox(height: 16),
                _colNathalia(),
              ]);
            }),
          ),
          Container(height: 1, color: _divider),
          // Seguridad
          Container(
            color: _accent.withOpacity(0.03),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                _secItem(Icons.shield_outlined, "Compra 100% segura"),
                const SizedBox(width: 20),
                _secItem(Icons.lock_outline, "SSL cifrado"),
                const SizedBox(width: 20),
                _secItem(Icons.local_shipping_outlined, "Envío garantizado"),
                const SizedBox(width: 20),
                _secItem(Icons.replay_outlined, "Devolución fácil"),
                const SizedBox(width: 20),
                _secItem(Icons.verified_outlined, "Productos certificados"),
              ]),
            ),
          ),
          Container(height: 1, color: _divider),
          // Copyright
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            child: LayoutBuilder(builder: (ctx, constraints) {
              final isWide = constraints.maxWidth > 520;
              if (isWide) {
                return Row(children: [
                  const Text("© 2025 SmartTech Store · Todos los derechos reservados",
                      style: TextStyle(color: _textSec, fontSize: 10)),
                  const Spacer(),
                  _socialBtn(Icons.camera_alt_outlined),
                  const SizedBox(width: 8),
                  _socialBtn(Icons.facebook_outlined),
                  const SizedBox(width: 8),
                  _socialBtn(Icons.music_note_outlined),
                  const SizedBox(width: 8),
                  _socialBtn(Icons.chat_bubble_outline),
                ]);
              }
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  _socialBtn(Icons.camera_alt_outlined),
                  const SizedBox(width: 8),
                  _socialBtn(Icons.facebook_outlined),
                  const SizedBox(width: 8),
                  _socialBtn(Icons.music_note_outlined),
                  const SizedBox(width: 8),
                  _socialBtn(Icons.chat_bubble_outline),
                ]),
                const SizedBox(height: 10),
                const Text("© 2025 SmartTech Store · Todos los derechos reservados",
                    style: TextStyle(color: _textSec, fontSize: 10)),
              ]);
            }),
          ),
        ],
      ),
    );
  }

  Widget _footerStat(String value, String label) {
    return Expanded(child: Column(children: [
      Text(value, style: const TextStyle(color: _accent, fontSize: 14, fontWeight: FontWeight.w800)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(color: _textSec, fontSize: 9)),
    ]));
  }

  Widget _footerDiv() => Container(width: 1, height: 26, color: _divider);

  Widget _colInfo() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text("SMARTTECH STORE",
          style: TextStyle(color: _textSec, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      const Text("Tu tienda de tecnología de confianza.",
          style: TextStyle(color: _textSec, fontSize: 11, height: 1.5)),
      const SizedBox(height: 10),
      _infoRow(Icons.location_on_outlined, "Colombia · Envíos a todo el país"),
      const SizedBox(height: 4),
      _infoRow(Icons.mail_outline, "smart.tech6913@gmail.com"),
      const SizedBox(height: 4),
      _infoRow(Icons.phone_outlined, "+57 311 506 4196"),
    ]);
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(children: [
      Icon(icon, color: _accent, size: 12),
      const SizedBox(width: 6),
      Flexible(child: Text(text, style: const TextStyle(color: _textSec, fontSize: 10))),
    ]);
  }

  Widget _colNathalia() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF7C3AED).withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF7C3AED).withOpacity(0.28), width: 1),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withOpacity(0.25),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFA78BFA).withOpacity(0.40), width: 1),
            ),
            child: const Icon(Icons.auto_awesome, color: Color(0xFFA78BFA), size: 14),
          ),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text("Nathalia", style: TextStyle(color: Color(0xFFA78BFA), fontSize: 12, fontWeight: FontWeight.w700)),
            Row(children: [
              Container(width: 5, height: 5, decoration: const BoxDecoration(color: Color(0xFF34D399), shape: BoxShape.circle)),
              const SizedBox(width: 4),
              const Text("En línea ahora", style: TextStyle(color: Color(0xFF34D399), fontSize: 9, fontWeight: FontWeight.w600)),
            ]),
          ]),
        ]),
        const SizedBox(height: 8),
        const Text("Asistente de compras 24/7. Resuelvo tus dudas al instante.",
            style: TextStyle(color: Color(0xFFC4B5FD), fontSize: 10, height: 1.4)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => showNathaliaChat(context, widget.token),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withOpacity(0.20),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFA78BFA).withOpacity(0.35), width: 1),
            ),
            child: const Text("Chatear con Nathalia ✦",
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFFA78BFA), fontSize: 11, fontWeight: FontWeight.w700)),
          ),
        ),
      ]),
    );
  }

  Widget _secItem(IconData icon, String label) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: const Color(0xFF34D399), size: 12),
      const SizedBox(width: 5),
      Text(label, style: const TextStyle(color: _textSec, fontSize: 10)),
    ]);
  }

  Widget _socialBtn(IconData icon) {
    return Container(
      width: 28, height: 28,
      decoration: BoxDecoration(
        color: _accent.withOpacity(0.07),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: _accent.withOpacity(0.18), width: 1),
      ),
      child: Icon(icon, color: _textSec, size: 14),
    );
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final stock = product.stock ?? 0;

    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          // AppBar personalizado con buscador
          _buildAppBar(),

          // Contenido scrolleable
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // ── Imagen con borde ────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Container(
                      height: 240,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A1929),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _accent.withOpacity(0.25), width: 1.5),
                        boxShadow: [
                          BoxShadow(color: _accent.withOpacity(0.08), blurRadius: 20, spreadRadius: 2),
                          BoxShadow(color: Colors.black.withOpacity(0.30), blurRadius: 12, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.network(
                          ApiService.resolveImage(product.image),
                          fit: BoxFit.contain,
                          loadingBuilder: (_, child, progress) =>
                              progress == null ? child : const Center(child: CircularProgressIndicator(color: _accent, strokeWidth: 2)),
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(Icons.broken_image_outlined, color: _textSec, size: 40),
                          ),
                        ),
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // ── INFO ──────────────────────────────────────────
                        _section(
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(product.name,
                                style: const TextStyle(color: _textPri, fontSize: 17, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            // Precio formateado con decimales
                            Text(
                              _formatPrice(product.price),
                              style: const TextStyle(color: _accent, fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Row(children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: stock > 0 ? Colors.greenAccent.withOpacity(0.10) : Colors.redAccent.withOpacity(0.10),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: stock > 0 ? Colors.greenAccent.withOpacity(0.35) : Colors.redAccent.withOpacity(0.35),
                                  ),
                                ),
                                child: Text(
                                  stock > 0 ? "$stock disponibles" : "Sin stock",
                                  style: TextStyle(
                                    color: stock > 0 ? Colors.greenAccent : Colors.redAccent,
                                    fontSize: 11, fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ]),
                          ]),
                        ),

                        const SizedBox(height: 12),

                        // ── QUANTITY ──────────────────────────────────────
                        _section(
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            const Text("Cantidad", style: TextStyle(color: _textPri, fontSize: 14)),
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF0A1929),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: _divider),
                              ),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                _qtyBtn(Icons.remove, () { if (quantity > 1) setState(() => quantity--); }),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text("$quantity",
                                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                                ),
                                _qtyBtn(Icons.add, () { if (quantity < stock) setState(() => quantity++); }),
                              ]),
                            ),
                          ]),
                        ),

                        const SizedBox(height: 12),

                        // ── SPECS ─────────────────────────────────────────
                        if (product.specs != null && product.specs!.isNotEmpty)
                          _section(
                            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              const Text("Especificaciones",
                                  style: TextStyle(color: _textPri, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              ...product.specs!.entries.toList().asMap().entries.map((entry) => _specRow(
                                    entry.value.key, entry.value.value.toString(),
                                    last: entry.key == product.specs!.length - 1)),
                            ]),
                          ),

                        const SizedBox(height: 16),

                        // ── ADMIN BUTTONS ─────────────────────────────────
                        if (isAdmin)
                          Row(mainAxisAlignment: MainAxisAlignment.start, children: [
                            _actionBtn(
                              icon: Icons.edit_rounded,
                              label: "Editar",
                              color: Colors.blueAccent,
                              onTap: () async {
                                final result = await Navigator.push(context,
                                    MaterialPageRoute(builder: (_) => EditProductScreen(product: product)));
                                if (result == true && mounted) Navigator.pop(context, true);
                              },
                            ),
                            const SizedBox(width: 10),
                            _actionBtn(
                              icon: Icons.delete_rounded,
                              label: "Eliminar",
                              color: Colors.redAccent,
                              onTap: showDeleteSheet,
                            ),
                          ]),

                        if (isAdmin) const SizedBox(height: 12),

                        // ── BOTONES ACCIÓN ────────────────────────────────
                        Row(mainAxisAlignment: MainAxisAlignment.start, children: [
                          // Carrito
                          _actionBtn(
                            icon: Icons.shopping_cart_rounded,
                            label: "Añadir al carrito",
                            color: _accent,
                            textColor: Colors.black,
                            onTap: addMultipleToCart,
                            wide: true,
                          ),
                          const SizedBox(width: 10),
                          // Nathalia
                          _actionBtn(
                            icon: Icons.auto_awesome,
                            label: "Nathalia",
                            color: const Color(0xFF7C3AED),
                            textColor: const Color(0xFFA78BFA),
                            borderColor: const Color(0xFF7C3AED).withOpacity(0.40),
                            filled: false,
                            onTap: () => showNathaliaChat(
                              context, widget.token,
                              initialMessage: "Háblame sobre el ${product.name} de ${product.brand ?? 'esta marca'}. "
                                  "¿Vale la pena por \$${product.price}? ¿Qué opinan los usuarios?",
                            ),
                          ),
                        ]),

                        const SizedBox(height: 24),

                        // ── RESEÑAS ───────────────────────────────────────
                        _section(
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              const Icon(Icons.rate_review_rounded, color: _accent, size: 20),
                              const SizedBox(width: 8),
                              const Text("Reseñas",
                                  style: TextStyle(color: _textPri, fontWeight: FontWeight.bold, fontSize: 16)),
                            ]),
                            const SizedBox(height: 12),
                            _ratingHeader(),
                            const SizedBox(height: 16),
                            _newReviewForm(),
                            const SizedBox(height: 16),
                            if (loadingReviews)
                              const Center(child: CircularProgressIndicator(color: _accent, strokeWidth: 2))
                            else if (reviews.isEmpty)
                              const Center(child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 20),
                                child: Text("Sé el primero en opinar",
                                    style: TextStyle(color: _textSec, fontSize: 13)),
                              ))
                            else
                              ...reviews.map<Widget>((r) => _reviewCard(r as Map<String, dynamic>)),
                          ]),
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),

                  // ── FOOTER ───────────────────────────────────────────────
                  _buildFooter(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Botón cantidad ────────────────────────────────────────────────────────
  Widget _qtyBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, color: _accent, size: 18),
      ),
    );
  }

  // ── Botón acción compacto ─────────────────────────────────────────────────
  Widget _actionBtn({
    required IconData icon,
    required String label,
    required Color color,
    Color? textColor,
    Color? borderColor,
    bool filled = true,
    bool wide = false,
    required VoidCallback onTap,
  }) {
    final tc = textColor ?? Colors.white;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: wide ? 20 : 16, vertical: 11),
        decoration: BoxDecoration(
          color: filled ? color : color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor ?? color.withOpacity(0.0), width: 1),
          boxShadow: filled ? [BoxShadow(color: color.withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 3))] : [],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: tc, size: 16),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: tc, fontWeight: FontWeight.w700, fontSize: 13)),
        ]),
      ),
    );
  }
}