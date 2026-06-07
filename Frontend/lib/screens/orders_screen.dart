import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List _orders = [];
  bool _loading = true;
  final String baseUrl = "http://localhost:8000";

  static const _bg      = Color(0xFF060D17);
  static const _surface = Color(0xFF0D1F33);
  static const _card    = Color(0xFF111E2E);
  static const _accent  = Color(0xFF00D4FF);
  static const _textPri = Color(0xFFEFF6FF);
  static const _textSec = Color(0xFF7A9BB5);
  static const _divider = Color(0xFF1A2E44);

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  Future<void> _fetchOrders() async {
    setState(() => _loading = true);
    final token = await _getToken();
    if (token == null) { setState(() => _loading = false); return; }

    final res = await http.get(
      Uri.parse("$baseUrl/orders/?token=$token"),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      setState(() {
        _orders  = (data['orders'] as List).reversed.toList();
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  // ── colores y labels de estado ──
  Color _statusColor(String s) {
    switch (s) {
      case "pagado":         return const Color(0xFF00D4FF);
      case "en_preparacion": return const Color(0xFFFFCA28);
      case "enviado":        return const Color(0xFFAB47BC);
      case "entregado":      return const Color(0xFF4CAF50);
      case "cancelado":      return const Color(0xFFFF5252);
      default:               return _textSec;
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case "pagado":         return "Pagado";
      case "en_preparacion": return "En preparación";
      case "enviado":        return "En camino";
      case "entregado":      return "Entregado";
      case "cancelado":      return "Cancelado";
      default:               return s;
    }
  }

  IconData _statusIcon(String s) {
    switch (s) {
      case "pagado":         return Icons.payment_outlined;
      case "en_preparacion": return Icons.inventory_2_outlined;
      case "enviado":        return Icons.local_shipping_outlined;
      case "entregado":      return Icons.check_circle_outline;
      case "cancelado":      return Icons.cancel_outlined;
      default:               return Icons.help_outline;
    }
  }

  String _statusMessage(String s) {
    switch (s) {
      case "pagado":         return "Tu pago fue confirmado. Pronto empezaremos a preparar tu pedido.";
      case "en_preparacion": return "Estamos preparando tu pedido con cuidado. ¡Ya casi está listo!";
      case "enviado":        return "Tu pedido está en camino. El transportista lo entregará pronto.";
      case "entregado":      return "¡Tu pedido llegó! Esperamos que disfrutes tu compra.";
      case "cancelado":      return "Este pedido fue cancelado. Contáctanos si tienes dudas.";
      default:               return "";
    }
  }

  String _fmtPrice(dynamic v) {
    final amount = (v as num).toDouble();
    final parts  = amount.toStringAsFixed(2).split('.');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
    return '\$$intPart.${parts[1]}';
  }

  void _showOrderDetail(Map order) {
    final status = order['status'] as String? ?? 'pagado';
    final color  = _statusColor(status);
    final items  = order['items'] as List? ?? [];
    final stepEstados = ["pagado", "en_preparacion", "enviado", "entregado"];
    final currentIdx  = stepEstados.indexOf(status);
    final isCancelado = status == "cancelado";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        expand: false,
        builder: (_, scrollCtrl) => SingleChildScrollView(
          controller: scrollCtrl,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // drag handle
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: _divider, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),

              // ── Header ──
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_statusIcon(status), color: color, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Pedido #${order['order_id']}",
                          style: const TextStyle(color: _textPri, fontWeight: FontWeight.w800, fontSize: 17)),
                      Text(_statusLabel(status),
                          style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Stepper ──
              if (!isCancelado)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _card, borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _divider),
                  ),
                  child: Row(
                    children: List.generate(stepEstados.length * 2 - 1, (i) {
                      if (i.isOdd) {
                        final done = i ~/ 2 < currentIdx;
                        return Expanded(child: Container(height: 2,
                            color: done ? _accent : _divider));
                      }
                      final idx    = i ~/ 2;
                      final done   = idx <= currentIdx;
                      final active = idx == currentIdx;
                      return Column(
                        children: [
                          Container(
                            width: 26, height: 26,
                            decoration: BoxDecoration(
                              color: done ? _accent.withOpacity(0.18) : _card,
                              shape: BoxShape.circle,
                              border: Border.all(color: done ? _accent : _divider, width: done ? 2 : 1),
                              boxShadow: active ? [BoxShadow(color: _accent.withOpacity(0.4), blurRadius: 8)] : [],
                            ),
                            child: done ? const Icon(Icons.check_rounded, color: _accent, size: 13) : null,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            ["Pagado","Preparando","Enviado","Entregado"][idx],
                            style: TextStyle(
                                fontSize: 8,
                                fontWeight: active ? FontWeight.w800 : FontWeight.w400,
                                color: active ? _accent : _textSec),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      );
                    }),
                  ),
                ),

              const SizedBox(height: 12),

              // ── Mensaje estado ──
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.25)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: color, size: 16),
                    const SizedBox(width: 10),
                    Expanded(child: Text(_statusMessage(status),
                        style: TextStyle(color: color, fontSize: 12, height: 1.4))),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Info pedido ──
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _card, borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _divider),
                ),
                child: Column(
                  children: [
                    _infoRow("Método de pago", order['payment_method'] ?? ''),
                    _infoRow("Fecha", _formatDate(order['created_at'] ?? '')),
                    _infoRow("Total", _fmtPrice(order['total_price'])),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Productos ──
              Text("Productos (${items.length})",
                  style: const TextStyle(color: _textPri, fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: 10),
              ...items.map((item) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _card, borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _divider),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: (item['image'] ?? '').isNotEmpty
                          ? Image.network(item['image'], width: 48, height: 48, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _imgPlaceholder())
                          : _imgPlaceholder(),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['product_name'] ?? '',
                              style: const TextStyle(color: _textPri, fontWeight: FontWeight.w600, fontSize: 13)),
                          Text("x${item['quantity']}  —  ${_fmtPrice(item['price'])} c/u",
                              style: const TextStyle(color: _textSec, fontSize: 11)),
                        ],
                      ),
                    ),
                    Text(_fmtPrice(item['subtotal']),
                        style: const TextStyle(color: _accent, fontWeight: FontWeight.w700, fontSize: 13)),
                  ],
                ),
              )),

              const SizedBox(height: 16),

              // ── Recomendaciones ──
              if (status == "entregado") ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withOpacity(0.07),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.30)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(children: [
                        Icon(Icons.star_rounded, color: Color(0xFF4CAF50), size: 18),
                        SizedBox(width: 8),
                        Text("Recomendaciones", style: TextStyle(color: Color(0xFF4CAF50), fontWeight: FontWeight.w700, fontSize: 14)),
                      ]),
                      const SizedBox(height: 10),
                      _recomRow(Icons.replay_rounded,        "¿Te gustó? Vuelve a comprar en SmartTech"),
                      _recomRow(Icons.support_agent_rounded, "¿Algún problema? Contáctanos"),
                      _recomRow(Icons.share_rounded,         "Comparte tu experiencia con amigos"),
                    ],
                  ),
                ),
              ],

              if (status == "enviado") ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFAB47BC).withOpacity(0.07),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFAB47BC).withOpacity(0.30)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(children: [
                        Icon(Icons.tips_and_updates_rounded, color: Color(0xFFAB47BC), size: 18),
                        SizedBox(width: 8),
                        Text("Consejos", style: TextStyle(color: Color(0xFFAB47BC), fontWeight: FontWeight.w700, fontSize: 14)),
                      ]),
                      const SizedBox(height: 10),
                      _recomRow(Icons.home_rounded,          "Asegúrate de estar en casa al momento de la entrega"),
                      _recomRow(Icons.phone_rounded,         "Ten tu número de contacto disponible"),
                      _recomRow(Icons.inventory_rounded,     "Revisa el paquete antes de firmar"),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            SizedBox(width: 120, child: Text(label, style: const TextStyle(color: _textSec, fontSize: 12))),
            Expanded(child: Text(value, style: const TextStyle(color: _textPri, fontSize: 12, fontWeight: FontWeight.w600))),
          ],
        ),
      );

  Widget _recomRow(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Icon(icon, size: 15, color: _textSec),
            const SizedBox(width: 8),
            Expanded(child: Text(text, style: const TextStyle(color: _textSec, fontSize: 12))),
          ],
        ),
      );

  Widget _imgPlaceholder() => Container(
        width: 48, height: 48,
        decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(8)),
        child: const Icon(Icons.image_outlined, color: _textSec, size: 20),
      );

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw);
      return "${dt.day}/${dt.month}/${dt.year}";
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        elevation: 0,
        leading: const BackButton(color: _accent),
        title: ShaderMask(
          shaderCallback: (b) => const LinearGradient(
            colors: [Color(0xFF7AE8FF), Color(0xFF00D4FF)],
          ).createShader(b),
          child: const Text("Mis compras",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20)),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _divider),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _accent, strokeWidth: 2))
          : _orders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: _card, shape: BoxShape.circle,
                          border: Border.all(color: _accent.withOpacity(0.20)),
                        ),
                        child: Icon(Icons.receipt_long_outlined, size: 48, color: _accent.withOpacity(0.5)),
                      ),
                      const SizedBox(height: 20),
                      const Text("Sin compras aún",
                          style: TextStyle(color: _textPri, fontSize: 18, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      const Text("Tus pedidos aparecerán aquí",
                          style: TextStyle(color: _textSec, fontSize: 13)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: _accent,
                  backgroundColor: _card,
                  onRefresh: _fetchOrders,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _orders.length,
                    itemBuilder: (_, i) {
                      final o      = _orders[i];
                      final status = o['status'] as String? ?? 'pagado';
                      final color  = _statusColor(status);
                      final items  = o['items'] as List? ?? [];

                      return GestureDetector(
                        onTap: () => _showOrderDetail(o),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: _card,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: _divider),
                          ),
                          child: Column(
                            children: [
                              // ── Header card ──
                              Padding(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44, height: 44,
                                      decoration: BoxDecoration(
                                        color: color.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: color.withOpacity(0.35)),
                                      ),
                                      child: Icon(_statusIcon(status), color: color, size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text("Pedido #${o['order_id']}",
                                              style: const TextStyle(color: _textPri, fontWeight: FontWeight.w700, fontSize: 14)),
                                          Text(_formatDate(o['created_at'] ?? ''),
                                              style: const TextStyle(color: _textSec, fontSize: 11)),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(_fmtPrice(o['total_price']),
                                            style: const TextStyle(color: _textPri, fontWeight: FontWeight.w800, fontSize: 14)),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: color.withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(color: color.withOpacity(0.35)),
                                          ),
                                          child: Text(_statusLabel(status),
                                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // ── Mini productos ──
                              if (items.isNotEmpty) ...[
                                Divider(color: _divider, height: 1),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                                  child: Row(
                                    children: [
                                      // fotos apiladas
                                      SizedBox(
                                        width: items.length > 3 ? 80.0 : items.length * 30.0,
                                        height: 30,
                                        child: Stack(
                                          children: List.generate(
                                            items.length > 3 ? 3 : items.length,
                                            (idx) => Positioned(
                                              left: idx * 22.0,
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(6),
                                                child: (items[idx]['image'] ?? '').isNotEmpty
                                                    ? Image.network(items[idx]['image'],
                                                        width: 30, height: 30, fit: BoxFit.cover,
                                                        errorBuilder: (_, __, ___) => _miniPlaceholder())
                                                    : _miniPlaceholder(),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          items.length == 1
                                              ? items[0]['product_name']
                                              : "${items[0]['product_name']} y ${items.length - 1} más",
                                          style: const TextStyle(color: _textSec, fontSize: 12),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const Icon(Icons.chevron_right_rounded, color: _textSec, size: 18),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _miniPlaceholder() => Container(
        width: 30, height: 30,
        color: _surface,
        child: const Icon(Icons.image_outlined, color: _textSec, size: 14),
      );
}