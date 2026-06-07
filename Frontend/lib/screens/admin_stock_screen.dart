import 'package:flutter/material.dart';
import '../services/admin_service.dart';

class AdminStockScreen extends StatefulWidget {
  final String token;
  const AdminStockScreen({super.key, required this.token});

  @override
  State<AdminStockScreen> createState() => _AdminStockScreenState();
}

class _AdminStockScreenState extends State<AdminStockScreen> {
  late AdminService _service;
  List<dynamic> _stock = [];
  bool _loading = true;
  String _filter = "all";

  static const _bg      = Color(0xFF060D17);
  static const _surface = Color(0xFF0D1F33);
  static const _card    = Color(0xFF111E2E);
  static const _accent  = Color(0xFF00D4FF);
  static const _textPri = Color(0xFFEFF6FF);
  static const _textSec = Color(0xFF7A9BB5);
  static const _divider = Color(0xFF1A2E44);

  final _filters = [
    {"key": "all",     "label": "Todos"},
    {"key": "agotado", "label": "Agotado"},
    {"key": "danger",  "label": "Crítico"},
    {"key": "warn",    "label": "Bajo"},
    {"key": "ok",      "label": "OK"},
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
      final data = await _service.getStock(filter: _filter);
      if (mounted) setState(() { _stock = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case "agotado": return const Color(0xFFFF1744);
      case "danger":  return const Color(0xFFFF5252);
      case "warn":    return const Color(0xFFFFCA28);
      default:        return const Color(0xFF4CAF50);
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case "agotado": return "Agotado";
      case "danger":  return "Crítico";
      case "warn":    return "Bajo";
      default:        return "OK";
    }
  }

  void _showRestockDialog(dynamic product) {
    final controller = TextEditingController();
    bool restocking  = false;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.60),
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => Dialog(
          backgroundColor: _surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.add_box_outlined, color: _accent, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Reponer stock",
                          style: TextStyle(color: _textPri, fontWeight: FontWeight.w800, fontSize: 16)),
                      Text(product['name'] ?? '',
                          style: const TextStyle(color: _textSec, fontSize: 12)),
                    ],
                  )),
                ]),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: product['stock'] == 0
                        ? const Color(0xFFFF1744).withOpacity(0.07)
                        : _accent.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: product['stock'] == 0
                          ? const Color(0xFFFF1744).withOpacity(0.30)
                          : _accent.withOpacity(0.20),
                    ),
                  ),
                  child: Row(children: [
                    Icon(
                      product['stock'] == 0
                          ? Icons.warning_amber_rounded
                          : Icons.inventory_2_outlined,
                      color: product['stock'] == 0
                          ? const Color(0xFFFF1744)
                          : _textSec,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      product['stock'] == 0
                          ? "AGOTADO — añade unidades para activar"
                          : "Stock actual: ${product['stock']} unidades",
                      style: TextStyle(
                        color: product['stock'] == 0
                            ? const Color(0xFFFF1744)
                            : _textSec,
                        fontSize: 13,
                        fontWeight: product['stock'] == 0
                            ? FontWeight.w700
                            : FontWeight.normal,
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  enabled: !restocking,
                  style: const TextStyle(color: _textPri),
                  decoration: InputDecoration(
                    labelText: "Unidades a añadir",
                    labelStyle: const TextStyle(color: _textSec),
                    filled: true,
                    fillColor: _card,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _divider),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _accent),
                    ),
                    prefixIcon: const Icon(Icons.add, color: _accent),
                  ),
                ),
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: restocking ? null : () => Navigator.pop(dialogCtx),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 13),
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
                      onTap: restocking ? null : () async {
                        final units = int.tryParse(controller.text);
                        if (units == null || units <= 0) return;
                        setDialogState(() => restocking = true);
                        final ok = await _service.restockProduct(product['id'], units);
                        if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                        if (ok && mounted) {
                          await _load();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Row(children: [
                                const Icon(Icons.check_circle_outline,
                                    color: Color(0xFF4CAF50), size: 16),
                                const SizedBox(width: 8),
                                Text("Stock actualizado: +$units unidades",
                                    style: const TextStyle(color: _textPri, fontSize: 13)),
                              ]),
                              backgroundColor: _surface,
                              behavior: SnackBarBehavior.floating,
                              margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: const Color(0xFF4CAF50).withOpacity(0.35)),
                              ),
                            ));
                          }
                        } else if (!ok && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: const Row(children: [
                              Icon(Icons.error_outline, color: Colors.redAccent, size: 16),
                              SizedBox(width: 8),
                              Text("Error al actualizar stock",
                                  style: TextStyle(color: _textPri, fontSize: 13)),
                            ]),
                            backgroundColor: _surface,
                            behavior: SnackBarBehavior.floating,
                            margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.redAccent.withOpacity(0.35)),
                            ),
                          ));
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          color: restocking ? _accent.withOpacity(0.07) : _accent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: restocking ? _accent.withOpacity(0.20) : _accent.withOpacity(0.50)),
                        ),
                        child: restocking
                            ? const Center(child: SizedBox(width: 18, height: 18,
                                child: CircularProgressIndicator(color: _accent, strokeWidth: 2)))
                            : const Text("Añadir",
                                textAlign: TextAlign.center,
                                style: TextStyle(color: _accent, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ),
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
        title: const Text("Inventario",
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
            height: 52,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: _filters.length,
              itemBuilder: (_, i) {
                final f      = _filters[i];
                final active = _filter == f['key'];
                final color  = f['key'] == 'agotado' ? const Color(0xFFFF1744)
                             : f['key'] == 'danger'  ? const Color(0xFFFF5252)
                             : f['key'] == 'warn'    ? const Color(0xFFFFCA28)
                             : f['key'] == 'ok'      ? const Color(0xFF4CAF50)
                             : _accent;
                return GestureDetector(
                  onTap: () { setState(() => _filter = f['key']!); _load(); },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: active ? color.withOpacity(0.18) : _card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: active ? color.withOpacity(0.60) : _divider),
                    ),
                    child: Text(f['label']!,
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700,
                            color: active ? color : _textSec)),
                  ),
                );
              },
            ),
          ),

          // ── Lista ──
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: _accent, strokeWidth: 2))
                : _stock.isEmpty
                    ? Center(child: Text("Sin productos", style: TextStyle(color: _textSec)))
                    : RefreshIndicator(
                        color: _accent,
                        backgroundColor: _card,
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _stock.length,
                          itemBuilder: (_, i) {
                            final p      = _stock[i];
                            final status = p['status'] as String;
                            final color  = _statusColor(status);
                            final isOut  = status == "agotado";
                            return GestureDetector(
                              onTap: () => _showRestockDialog(p),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: _card,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isOut
                                        ? const Color(0xFFFF1744).withOpacity(0.50)
                                        : status == "danger"
                                            ? const Color(0xFFFF5252).withOpacity(0.40)
                                            : _divider,
                                  ),
                                  boxShadow: isOut
                                      ? [BoxShadow(color: const Color(0xFFFF1744).withOpacity(0.10), blurRadius: 12)]
                                      : status == "danger"
                                          ? [BoxShadow(color: const Color(0xFFFF5252).withOpacity(0.08), blurRadius: 10)]
                                          : [],
                                ),
                                child: Row(
                                  children: [
                                    Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(10),
                                          child: p['image'] != null && p['image'] != ''
                                              ? Image.network(p['image'],
                                                  width: 52, height: 52, fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) => _imgPlaceholder())
                                              : _imgPlaceholder(),
                                        ),
                                        if (isOut)
                                          Positioned.fill(
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(10),
                                              child: Container(
                                                color: Colors.black.withOpacity(0.55),
                                                child: const Icon(Icons.block_rounded,
                                                    color: Color(0xFFFF1744), size: 22),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(p['name'] ?? '',
                                              style: TextStyle(
                                                  color: isOut
                                                      ? _textSec
                                                      : _textPri,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13)),
                                          const SizedBox(height: 2),
                                          Text(p['category'] ?? '',
                                              style: const TextStyle(color: _textSec, fontSize: 11)),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          isOut ? "0 uds" : "${p['stock']} uds",
                                          style: TextStyle(
                                              color: isOut ? const Color(0xFFFF1744) : _textPri,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 15),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: color.withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(color: color.withOpacity(0.35)),
                                          ),
                                          child: Text(_statusLabel(status),
                                              style: TextStyle(
                                                  fontSize: 10, fontWeight: FontWeight.w700, color: color)),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: _accent.withOpacity(0.08),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: _accent.withOpacity(0.25)),
                                          ),
                                          child: const Text("+ Reponer",
                                              style: TextStyle(
                                                  fontSize: 10, fontWeight: FontWeight.w700, color: _accent)),
                                        ),
                                      ],
                                    ),
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

  Widget _imgPlaceholder() => Container(
        width: 52, height: 52,
        decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(10)),
        child: const Icon(Icons.image_outlined, color: _textSec, size: 22),
      );
}