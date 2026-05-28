import 'package:flutter/material.dart';
import 'payment_detail_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final double total;
  final String token;

  const CheckoutScreen({
    super.key,
    required this.total,
    required this.token,
  });

  @override
  State<CheckoutScreen> createState() =>
      _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {

  String method = "tarjeta";

  // 🎨 PALETA PRO
  static const _bg = Color(0xFF060D17);
  static const _card = Color(0xFF111E2E);
  static const _accent = Color(0xFF00D4FF);
  static const _textPri = Color(0xFFEFF6FF);
  static const _textSec = Color(0xFF7A9BB5);
  static const _divider = Color(0xFF1A2E44);

  void goNext() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentDetailScreen(
          method: method,
          total: widget.total,
          token: widget.token, // ✅ CORREGIDO
        ),
      ),
    );
  }

  // 🔥 CARD SECCIÓN
  Widget _section(Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _divider),
      ),
      child: child,
    );
  }

  // 🔥 OPCIÓN DE PAGO PRO
  Widget _paymentOption({
    required String title,
    required String value,
    required IconData icon,
  }) {
    final bool selected = method == value;

    return GestureDetector(
      onTap: () => setState(() => method = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? _accent.withOpacity(0.12)
              : Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? _accent : _divider,
          ),
        ),
        child: Row(
          children: [

            Icon(
              icon,
              color: selected ? _accent : _textSec,
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: selected ? _textPri : _textSec,
                  fontWeight:
                      selected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),

            if (selected)
              const Icon(
                Icons.check_circle,
                color: _accent,
                size: 18,
              )
          ],
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
        backgroundColor: const Color(0xFF0F2A44),
        elevation: 0,
        title: const Text(
          "Checkout",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            // 💰 TOTAL PRO
            _section(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  const Text(
                    "Total a pagar",
                    style: TextStyle(color: _textSec),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    "\$${widget.total.toStringAsFixed(2)}",
                    style: const TextStyle(
                      color: _accent,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 💳 MÉTODOS DE PAGO
            _section(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  const Text(
                    "Método de pago",
                    style: TextStyle(
                      color: _textPri,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  _paymentOption(
                    title: "Tarjeta",
                    value: "tarjeta",
                    icon: Icons.credit_card,
                  ),

                  _paymentOption(
                    title: "Nequi",
                    value: "nequi",
                    icon: Icons.phone_android,
                  ),

                  _paymentOption(
                    title: "Contra entrega",
                    value: "contra_entrega",
                    icon: Icons.local_shipping,
                  ),
                ],
              ),
            ),

            const Spacer(),

            // 🚀 BOTÓN PRO
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: goNext,
                child: const Text(
                  "Continuar",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}