import 'package:flutter/material.dart';
import '../services/admin_service.dart';

class AdminOrderDetailScreen extends StatefulWidget {
  final String token;
  final int pedidoId;
  const AdminOrderDetailScreen({super.key, required this.token, required this.pedidoId});

  @override
  State<AdminOrderDetailScreen> createState() => _AdminOrderDetailScreenState();
}

class _AdminOrderDetailScreenState extends State<AdminOrderDetailScreen> {
  late AdminService _service;
  Map<String, dynamic>? _order;
  bool _loading  = true;
  bool _updating = false;

  static const _bg      = Color(0xFF060D17);
  static const _surface = Color(0xFF0D1F33);
  static const _card    = Color(0xFF111E2E);
  static const _accent  = Color(0xFF00D4FF);
  static const _textPri = Color(0xFFEFF6FF);
  static const _textSec = Color(0xFF7A9BB5);
  static const _divider = Color(0xFF1A2E44);

  final _estados = ["pagado","en_preparacion","enviado","entregado","cancelado"];
  final _labels  = {"pagado":"Pagado","en_preparacion":"En preparación","enviado":"Enviado","entregado":"Entregado","cancelado":"Cancelado"};
  final _icons   = {"pagado":Icons.payment_outlined,"en_preparacion":Icons.inventory_2_outlined,"enviado":Icons.local_shipping_outlined,"entregado":Icons.check_circle_outline,"cancelado":Icons.cancel_outlined};
  final _colors  = {"pagado":const Color(0xFF00D4FF),"en_preparacion":const Color(0xFFFFCA28),"enviado":const Color(0xFFAB47BC),"entregado":const Color(0xFF4CAF50),"cancelado":const Color(0xFFFF5252)};

  @override
  void initState() {
    super.initState();
    _service = AdminService(token: widget.token);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _service.getOrderDetail(widget.pedidoId);
      setState(() { _order = data; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _changeStatus(String nuevo) async {
    setState(() => _updating = true);
    final ok = await _service.updateOrderStatus(widget.pedidoId, nuevo);
    setState(() => _updating = false);
    if (ok) {
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [
            const Icon(Icons.check_circle_outline, color: Color(0xFF4CAF50), size: 16),
            const SizedBox(width: 8),
            Text("Estado: ${_labels[nuevo]}", style: const TextStyle(color: _textPri, fontSize: 13)),
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
    }
  }

  void _showStatusPicker() {
    final current = _order!['estado'] as String;
    showModalBottomSheet(
      context: context,
      backgroundColor: _surface,
      // isScrollControlled permite que el sheet crezca con el contenido
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) {
        return Padding(
          // padding bottom = teclado + safe area para no desbordar
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom +
                MediaQuery.of(context).padding.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // handle
              Center(
                child: Container(
                  width: 36, height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                      color: _divider, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const Text("Cambiar estado",
                  style: TextStyle(
                      color: _textPri, fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 14),
              ..._estados.map((e) {
                final isActive = e == current;
                final color = _colors[e]!;
                return GestureDetector(
                  onTap: isActive
                      ? null
                      : () { Navigator.pop(context); _changeStatus(e); },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isActive ? color.withOpacity(0.12) : _card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: isActive
                              ? color.withOpacity(0.50)
                              : _divider),
                    ),
                    child: Row(children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(_icons[e], color: color, size: 16),
                      ),
                      const SizedBox(width: 12),
                      Text(_labels[e]!,
                          style: TextStyle(
                              color: isActive ? color : _textPri,
                              fontWeight: isActive
                                  ? FontWeight.w800
                                  : FontWeight.w500,
                              fontSize: 14)),
                      if (isActive) ...[
                        const Spacer(),
                        Icon(Icons.check_rounded, color: color, size: 18),
                      ],
                    ]),
                  ),
                );
              }),
            ],
          ),
        );
      },
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
          _order != null ? "Pedido #${_order!['id']}" : "Detalle",
          style: const TextStyle(
              color: _textPri, fontWeight: FontWeight.w800, fontSize: 20),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _divider),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: _accent, strokeWidth: 2))
          : _order == null
              ? Center(
                  child: Text("Pedido no encontrado",
                      style: TextStyle(color: _textSec)))
              : Stack(
                  children: [
                    SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _estadoStepper(),
                          const SizedBox(height: 14),
                          _infoCard("Cliente", Column(children: [
                            _row("Nombre","${_order!['nombre']} ${_order!['apellido']}"),
                            _row("Documento","${_order!['tipo_documento']} ${_order!['documento']}"),
                            _row("Contacto", _order!['numero_contacto'] ?? ''),
                          ])),
                          const SizedBox(height: 12),
                          _infoCard("Entrega", Column(children: [
                            _row("País", _order!['pais'] ?? ''),
                            _row("Departamento", _order!['departamento'] ?? ''),
                            _row("Ciudad", _order!['ciudad'] ?? ''),
                            _row("Dirección", _order!['direccion'] ?? ''),
                            if ((_order!['fecha_entrega'] ?? '').isNotEmpty)
                              _row("Fecha estimada", _order!['fecha_entrega']),
                          ])),
                          const SizedBox(height: 12),
                          _infoCard("Pago", Column(children: [
                            _row("Método", _order!['metodo_pago'] ?? ''),
                            if ((_order!['referencia_pago'] ?? '').isNotEmpty)
                              _row("Referencia", _order!['referencia_pago']),
                          ])),
                          const SizedBox(height: 12),
                          _infoCard(
                            "Productos",
                            Column(children: [
                              ...(_order!['items'] as List).map((item) =>
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Row(children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: (item['image'] ?? '').isNotEmpty
                                            ? Image.network(item['image'],
                                                width: 44, height: 44,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) =>
                                                    _imgPlaceholder())
                                            : _imgPlaceholder(),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(item['name'] ?? '',
                                                style: const TextStyle(
                                                    color: _textPri,
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 13)),
                                            Text(
                                                "x${item['cantidad']}  —  \$${_fmt(item['precio_unitario'])} c/u",
                                                style: const TextStyle(
                                                    color: _textSec,
                                                    fontSize: 11)),
                                          ],
                                        ),
                                      ),
                                      Text("\$${_fmt(item['subtotal'])}",
                                          style: const TextStyle(
                                              color: _textPri,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13)),
                                    ]),
                                  )),
                              Divider(color: _divider),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text("Total",
                                      style: TextStyle(
                                          color: _textPri,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14)),
                                  Text("\$${_fmt(_order!['total'])}",
                                      style: const TextStyle(
                                          color: _accent,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 18)),
                                ],
                              ),
                            ]),
                          ),
                        ],
                      ),
                    ),
                    // Botón cambiar estado
                    Positioned(
                      bottom: 16, left: 16, right: 16,
                      child: _updating
                          ? const Center(
                              child: CircularProgressIndicator(
                                  color: _accent, strokeWidth: 2))
                          : GestureDetector(
                              onTap: _showStatusPicker,
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                  color: _accent.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                      color: _accent.withOpacity(0.45)),
                                  boxShadow: [
                                    BoxShadow(
                                        color: _accent.withOpacity(0.15),
                                        blurRadius: 16)
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(Icons.edit_outlined,
                                        color: _accent, size: 18),
                                    SizedBox(width: 8),
                                    Text("Cambiar estado del pedido",
                                        style: TextStyle(
                                            color: _accent,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15)),
                                  ],
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }

  Widget _estadoStepper() {
    final current     = _order!['estado'] as String;
    final stepEstados = ["pagado", "en_preparacion", "enviado", "entregado"];
    final currentIdx  = stepEstados.indexOf(current);
    final isCancelado = current == "cancelado";

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _divider),
      ),
      child: isCancelado
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Badge cancelado
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF5252).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.cancel_outlined,
                        color: Color(0xFFFF5252), size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Text("Pedido cancelado",
                      style: TextStyle(
                          color: Color(0xFFFF5252),
                          fontWeight: FontWeight.w800,
                          fontSize: 14)),
                ]),
                const SizedBox(height: 12),
                // Pasos en gris (referencia visual)
                Row(
                  children: List.generate(stepEstados.length * 2 - 1, (i) {
                    if (i.isOdd) {
                      return Expanded(
                          child: Container(height: 2, color: _divider));
                    }
                    final idx = i ~/ 2;
                    return Column(children: [
                      Container(
                        width: 24, height: 24,
                        decoration: BoxDecoration(
                          color: _surface,
                          shape: BoxShape.circle,
                          border: Border.all(color: _divider),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(_labels[stepEstados[idx]]!,
                          style:
                              const TextStyle(fontSize: 9, color: _textSec),
                          textAlign: TextAlign.center),
                    ]);
                  }),
                ),
              ],
            )
          : Row(
              children: List.generate(stepEstados.length * 2 - 1, (i) {
                if (i.isOdd) {
                  final done = i ~/ 2 < currentIdx;
                  return Expanded(
                      child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            gradient: done
                                ? const LinearGradient(colors: [
                                    Color(0xFF00D4FF),
                                    Color(0xFF4CAF50)
                                  ])
                                : null,
                            color: done ? null : _divider,
                          )));
                }
                final idx    = i ~/ 2;
                final done   = idx <= currentIdx;
                final active = idx == currentIdx;
                return Column(children: [
                  Container(
                    width: 30, height: 30,
                    decoration: BoxDecoration(
                      color: done ? _accent.withOpacity(0.20) : _card,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: done ? _accent : _divider,
                          width: done ? 2 : 1),
                      boxShadow: active
                          ? [BoxShadow(
                              color: _accent.withOpacity(0.40),
                              blurRadius: 10)]
                          : [],
                    ),
                    child: done
                        ? const Icon(Icons.check_rounded,
                            color: _accent, size: 14)
                        : null,
                  ),
                  const SizedBox(height: 4),
                  Text(_labels[stepEstados[idx]]!,
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: active
                              ? FontWeight.w800
                              : FontWeight.w400,
                          color: active ? _accent : _textSec),
                      textAlign: TextAlign.center),
                ]);
              }),
            ),
    );
  }

  Widget _infoCard(String title, Widget child) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    color: _textSec,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    letterSpacing: 0.5)),
            const SizedBox(height: 12),
            child,
          ],
        ),
      );

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
                width: 100,
                child: Text(label,
                    style: const TextStyle(color: _textSec, fontSize: 12))),
            Expanded(
                child: Text(value,
                    style: const TextStyle(
                        color: _textPri,
                        fontSize: 12,
                        fontWeight: FontWeight.w600))),
          ],
        ),
      );

  Widget _imgPlaceholder() => Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
            color: _surface, borderRadius: BorderRadius.circular(8)),
        child: const Icon(Icons.image_outlined, color: _textSec, size: 18),
      );

  String _fmt(dynamic value) {
    final amount = (value as num).toDouble();
    if (amount >= 1000000)
      return "${(amount / 1000000).toStringAsFixed(1)}M";
    if (amount >= 1000) return "${(amount / 1000).toStringAsFixed(0)}K";
    return amount.toStringAsFixed(0);
  }
}