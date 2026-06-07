import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import 'admin_stock_screen.dart';
import 'admin_orders_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  final String token;
  const AdminDashboardScreen({super.key, required this.token});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late AdminService _service;
  Map<String, dynamic>? _stats;
  List<dynamic> _topProducts = [];
  List<dynamic> _topClients  = [];
  bool _loading = true;

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
    _service = AdminService(token: widget.token);
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    try {
      final stats    = await _service.getStats();
      final products = await _service.getTopProducts();
      final clients  = await _service.getTopClients();
      setState(() {
        _stats       = stats;
        _topProducts = products;
        _topClients  = clients;
        _loading     = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  void _goToStock() => Navigator.push(context,
      MaterialPageRoute(builder: (_) => AdminStockScreen(token: widget.token)));

  void _goToOrders() => Navigator.push(context,
      MaterialPageRoute(builder: (_) => AdminOrdersScreen(token: widget.token)));

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
          child: const Text("Panel Admin",
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 20)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: _accent),
            onPressed: _loadAll,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _divider),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: _accent, strokeWidth: 2))
          : RefreshIndicator(
              color: _accent,
              backgroundColor: _card,
              onRefresh: _loadAll,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle("Resumen general"),
                    const SizedBox(height: 10),
                    // ── Metric cards: 2 columnas, altura fija y compacta ──
                    Row(children: [
                      Expanded(child: _metricCard("Ingresos totales",
                          "\$${_fmt(_stats!['total_revenue'])}",
                          Icons.attach_money, const Color(0xFF00D4FF))),
                      const SizedBox(width: 10),
                      Expanded(child: _metricCard("Unidades vendidas",
                          "${_stats!['total_units_sold']}",
                          Icons.inventory_2_outlined, const Color(0xFF4CAF50))),
                    ]),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(child: _metricCard("Stock crítico",
                          "${_stats!['critical_stock_count']} productos",
                          Icons.warning_amber_rounded, const Color(0xFFFF5252))),
                      const SizedBox(width: 10),
                      Expanded(child: _metricCard("Clientes",
                          "${_stats!['total_clients']}",
                          Icons.people_outline, const Color(0xFFAB47BC))),
                    ]),
                    const SizedBox(height: 24),
                    _sectionTitle("Gestión rápida"),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(child: _actionCard("Inventario",
                          Icons.inventory_outlined,
                          const Color(0xFF00D4FF), _goToStock)),
                      const SizedBox(width: 10),
                      Expanded(child: _actionCard("Pedidos",
                          Icons.receipt_long_outlined,
                          const Color(0xFF4CAF50), _goToOrders)),
                    ]),
                    const SizedBox(height: 24),
                    _sectionTitle("Más vendidos"),
                    const SizedBox(height: 10),
                    _topProductsList(),
                    const SizedBox(height: 24),
                    _sectionTitle("Top clientes"),
                    const SizedBox(height: 10),
                    _topClientsList(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _sectionTitle(String t) => Text(t,
      style: const TextStyle(
          color: _textPri, fontSize: 15, fontWeight: FontWeight.w700));

  // ── Card compacta: ícono pequeño + texto al lado, altura fija 64px ────────
  Widget _metricCard(String label, String value, IconData icon, Color color) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25)),
        boxShadow: [BoxShadow(color: color.withOpacity(0.06), blurRadius: 8)],
      ),
      child: Row(children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 15),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(value,
                  style: const TextStyle(
                      color: _textPri,
                      fontSize: 14,
                      fontWeight: FontWeight.w800),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              Text(label,
                  style: const TextStyle(color: _textSec, fontSize: 10),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _actionCard(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.35)),
        ),
        child: Row(children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w700, fontSize: 13)),
          const Spacer(),
          Icon(Icons.chevron_right_rounded,
              color: color.withOpacity(0.6), size: 16),
        ]),
      ),
    );
  }

  Widget _topProductsList() {
    if (_topProducts.isEmpty) {
      return Text("Sin datos", style: TextStyle(color: _textSec));
    }
    final maxV = (_topProducts.first['total_vendido'] as num).toDouble();
    final colors = [
      _accent, const Color(0xFF4CAF50), const Color(0xFFAB47BC),
      const Color(0xFFFF7043), const Color(0xFFFFCA28), const Color(0xFF26C6DA)
    ];
    return Column(
      children: List.generate(_topProducts.length, (i) {
        final p   = _topProducts[i];
        final pct = maxV > 0 ? (p['total_vendido'] as num) / maxV : 0.0;
        final c   = colors[i % colors.length];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _divider),
          ),
          child: Row(children: [
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                  color: c.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8)),
              child: Center(
                  child: Text("${i + 1}",
                      style: TextStyle(
                          color: c,
                          fontWeight: FontWeight.w800,
                          fontSize: 12))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p['name'] ?? '',
                      style: const TextStyle(
                          color: _textPri,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                        value: pct.toDouble(),
                        minHeight: 4,
                        backgroundColor: _divider,
                        color: c),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text("${p['total_vendido']} uds",
                  style: const TextStyle(
                      color: _textPri,
                      fontWeight: FontWeight.w700,
                      fontSize: 12)),
              Text("\$${_fmt(p['ingresos_generados'])}",
                  style: TextStyle(
                      color: c, fontSize: 11, fontWeight: FontWeight.w600)),
            ]),
          ]),
        );
      }),
    );
  }

  Widget _topClientsList() {
    if (_topClients.isEmpty) {
      return Text("Sin datos", style: TextStyle(color: _textSec));
    }
    final colors = [
      _accent, const Color(0xFF4CAF50), const Color(0xFFFF7043),
      const Color(0xFFAB47BC), const Color(0xFFFFCA28)
    ];
    return Column(
      children: List.generate(_topClients.length, (i) {
        final c      = _topClients[i];
        final color  = colors[i % colors.length];
        final nombre = c['nombre'] as String? ?? '';
        final initials = nombre
            .split(' ')
            .take(2)
            .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
            .join();
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _divider),
          ),
          child: Row(children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: color.withOpacity(0.15),
              child: Text(initials,
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w800,
                      fontSize: 12)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(nombre,
                      style: const TextStyle(
                          color: _textPri,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                  Text(c['correo'] ?? '',
                      style: const TextStyle(color: _textSec, fontSize: 11)),
                ],
              ),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text("\$${_fmt(c['total_gastado'])}",
                  style: const TextStyle(
                      color: _textPri,
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
              Text("${c['total_pedidos']} pedidos",
                  style: const TextStyle(color: _textSec, fontSize: 11)),
            ]),
          ]),
        );
      }),
    );
  }

  String _fmt(dynamic value) {
    final amount = (value as num).toDouble();
    if (amount >= 1000000)
      return "${(amount / 1000000).toStringAsFixed(1)}M";
    if (amount >= 1000) return "${(amount / 1000).toStringAsFixed(0)}K";
    return amount.toStringAsFixed(0);
  }
}