import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import 'admin_order_detail_screen.dart';

class AdminOrdersScreen extends StatefulWidget {
  final String token;
  const AdminOrdersScreen({super.key, required this.token});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  late AdminService _service;
  List<dynamic> _orders = [];
  bool _loading = true;
  String? _filterEstado;

  static const _bg      = Color(0xFF060D17);
  static const _surface = Color(0xFF0D1F33);
  static const _card    = Color(0xFF111E2E);
  static const _accent  = Color(0xFF00D4FF);
  static const _textPri = Color(0xFFEFF6FF);
  static const _textSec = Color(0xFF7A9BB5);
  static const _divider = Color(0xFF1A2E44);

  final _estados = [
    {"key": null,             "label": "Todos"},
    {"key": "pagado",         "label": "Pagado"},
    {"key": "en_preparacion", "label": "Preparando"},
    {"key": "enviado",        "label": "Enviado"},
    {"key": "entregado",      "label": "Entregado"},
    {"key": "cancelado",      "label": "Cancelado"},
  ];

  @override
  void initState() {
    super.initState();
    _service = AdminService(token: widget.token);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _service.getOrders(estado: _filterEstado);
      setState(() { _orders = data; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Color _estadoColor(String e) {
    switch (e) {
      case "pagado":         return const Color(0xFF00D4FF);
      case "en_preparacion": return const Color(0xFFFFCA28);
      case "enviado":        return const Color(0xFFAB47BC);
      case "entregado":      return const Color(0xFF4CAF50);
      case "cancelado":      return const Color(0xFFFF5252);
      default:               return _textSec;
    }
  }

  String _estadoLabel(String e) {
    switch (e) {
      case "pagado":         return "Pagado";
      case "en_preparacion": return "En preparación";
      case "enviado":        return "Enviado";
      case "entregado":      return "Entregado";
      case "cancelado":      return "Cancelado";
      default:               return e;
    }
  }

  Widget _buildChip(Map<String, dynamic> e) {
    final active = _filterEstado == e['key'];
    final color  = e['key'] == null ? _accent : _estadoColor(e['key'] as String);
    return GestureDetector(
      onTap: () { setState(() => _filterEstado = e['key'] as String?); _load(); },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: active ? color.withOpacity(0.18) : _card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? color.withOpacity(0.60) : _divider),
        ),
        child: Text(e['label'] as String,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700,
                color: active ? color : _textSec)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // 600px es el breakpoint — encima es "pantalla grande"
    final isWide = screenWidth >= 600;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        elevation: 0,
        leading: const BackButton(color: _accent),
        title: const Text("Pedidos",
            style: TextStyle(color: _textPri, fontWeight: FontWeight.w800, fontSize: 20)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _divider),
        ),
      ),
      body: Column(
        children: [
          // ── Filtros ──
          Container(
            color: _surface,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: isWide
                // Pantalla grande: una fila, alineadas a la izquierda
                ? Row(
                    children: _estados
                        .map((e) => _buildChip(e as Map<String, dynamic>))
                        .toList(),
                  )
                // Móvil: wrap a dos filas si no caben
                : Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: _estados
                        .map((e) => _buildChip(e as Map<String, dynamic>))
                        .toList(),
                  ),
          ),
          // ── Lista ──
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: _accent, strokeWidth: 2))
                : _orders.isEmpty
                    ? Center(child: Text("Sin pedidos", style: TextStyle(color: _textSec)))
                    : RefreshIndicator(
                        color: _accent,
                        backgroundColor: _card,
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _orders.length,
                          itemBuilder: (_, i) {
                            final o     = _orders[i];
                            final color = _estadoColor(o['estado'] ?? '');
                            return GestureDetector(
                              onTap: () async {
                                await Navigator.push(context, MaterialPageRoute(
                                  builder: (_) => AdminOrderDetailScreen(
                                      token: widget.token, pedidoId: o['id']),
                                ));
                                _load();
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: _card,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: _divider),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44, height: 44,
                                      decoration: BoxDecoration(
                                        color: color.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: color.withOpacity(0.35)),
                                      ),
                                      child: Center(
                                        child: Text("#${o['id']}",
                                            style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12)),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text("${o['nombre'] ?? ''} ${o['apellido'] ?? ''}",
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(color: _textPri, fontWeight: FontWeight.w600, fontSize: 13)),
                                          const SizedBox(height: 2),
                                          Text(o['ciudad'] ?? '',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(color: _textSec, fontSize: 11)),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text("\$${_fmt(o['total'])}",
                                            style: const TextStyle(color: _textPri, fontWeight: FontWeight.w700, fontSize: 13)),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: color.withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(color: color.withOpacity(0.35)),
                                          ),
                                          child: Text(_estadoLabel(o['estado'] ?? ''),
                                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 6),
                                    Icon(Icons.chevron_right_rounded, color: _textSec, size: 18),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  String _fmt(dynamic value) {
    final amount = (value as num).toDouble();
    if (amount >= 1000000) return "${(amount / 1000000).toStringAsFixed(1)}M";
    if (amount >= 1000)    return "${(amount / 1000).toStringAsFixed(0)}K";
    return amount.toStringAsFixed(0);
  }
}