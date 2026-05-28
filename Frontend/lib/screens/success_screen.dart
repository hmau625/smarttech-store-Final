import 'package:flutter/material.dart';

import 'product_list_screen.dart';
import 'cart_screen.dart';

class SuccessScreen extends StatelessWidget {

  // 🔥 TOKEN
  final String token;

  const SuccessScreen({
    super.key,
    required this.token,
  });
  // 🎨 PALETA SMARTTECH
  static const _bg = Color(0xFF060D17);
  static const _card = Color(0xFF111E2E);
  static const _accent = Color(0xFF00D4FF);
  static const _accentDim = Color(0xFF0099BB);
  static const _textPri = Color(0xFFEFF6FF);
  static const _textSec = Color(0xFF7A9BB5);
  static const _divider = Color(0xFF1A2E44);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,

      body: Container(
        width: double.infinity,

        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF060D17),
              Color(0xFF0B1624),
              Color(0xFF101D2D),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),

        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),

              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  // 🔥 ICONO PREMIUM
                  Container(
                    width: 150,
                    height: 150,

                    decoration: BoxDecoration(
                      shape: BoxShape.circle,

                      gradient: RadialGradient(
                        colors: [
                          _accent.withOpacity(0.20),
                          Colors.transparent,
                        ],
                      ),

                      boxShadow: [
                        BoxShadow(
                          color: _accent.withOpacity(0.18),
                          blurRadius: 45,
                          spreadRadius: 10,
                        ),
                      ],
                    ),

                    child: Center(
                      child: Container(
                        width: 100,
                        height: 100,

                        decoration: BoxDecoration(
                          color: _card,
                          shape: BoxShape.circle,

                          border: Border.all(
                            color: _accent.withOpacity(0.25),
                            width: 1.5,
                          ),
                        ),

                        child: const Icon(
                          Icons.check_rounded,
                          color: _accent,
                          size: 60,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 35),

                  // 🔥 CARD
                  Container(
                    width: double.infinity,

                    padding: const EdgeInsets.all(26),

                    decoration: BoxDecoration(
                      color: _card,

                      borderRadius: BorderRadius.circular(28),

                      border: Border.all(
                        color: _divider,
                        width: 1,
                      ),

                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.35),
                          blurRadius: 25,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),

                    child: Column(
                      children: [

                        // 🎉 TITULO
                        const Text(
                          "¡Compra exitosa!",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: _textPri,
                            letterSpacing: 0.4,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 12),

                        // 📝 MENSAJE
                        const Text(
                          "Tu pedido fue registrado correctamente y pronto será procesado.",
                          style: TextStyle(
                            fontSize: 15,
                            color: _textSec,
                            height: 1.5,
                            letterSpacing: 0.2,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 28),

                        // 🔹 INFO BOX
                        Container(
                          width: double.infinity,

                          padding: const EdgeInsets.all(18),

                          decoration: BoxDecoration(
                            color: _accent.withOpacity(0.06),

                            borderRadius: BorderRadius.circular(18),

                            border: Border.all(
                              color: _accent.withOpacity(0.12),
                              width: 1,
                            ),
                          ),

                          child: Row(
                            children: [

                              Container(
                                padding: const EdgeInsets.all(10),

                                decoration: BoxDecoration(
                                  color:
                                      _accent.withOpacity(0.10),
                                  shape: BoxShape.circle,
                                ),

                                child: const Icon(
                                  Icons.local_shipping_outlined,
                                  color: _accent,
                                  size: 22,
                                ),
                              ),

                              const SizedBox(width: 14),

                              const Expanded(
                                child: Text(
                                  "Recibirás actualizaciones del estado de tu pedido próximamente.",
                                  style: TextStyle(
                                    color: _textSec,
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // 🏠 BOTÓN PRODUCTOS
                        SizedBox(
                          width: double.infinity,
                          height: 56,

                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _accent,

                              elevation: 10,

                              shadowColor:
                                  _accent.withOpacity(0.35),

                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(18),
                              ),
                            ),

                            onPressed: () {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ProductListScreen(
  token: token,
),
                                ),
                                (route) => false,
                              );
                            },

                            child: const Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [

                                Icon(
                                  Icons.home_rounded,
                                  color: Colors.black,
                                  size: 22,
                                ),

                                SizedBox(width: 10),

                                Text(
                                  "Volver a productos",
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // 🛒 BOTÓN CARRITO
                        SizedBox(
                          width: double.infinity,
                          height: 54,

                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color:
                                    Colors.white.withOpacity(0.08),
                              ),

                              backgroundColor:
                                  Colors.white.withOpacity(0.03),

                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(18),
                              ),
                            ),

                            onPressed: () {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const CartScreen(),
                                ),
                                (route) => false,
                              );
                            },

                            child: const Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [

                                Icon(
                                  Icons.shopping_cart_outlined,
                                  color: _textPri,
                                  size: 20,
                                ),

                                SizedBox(width: 10),

                                Text(
                                  "Ver carrito",
                                  style: TextStyle(
                                    color: _textPri,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // 🔹 FOOTER
                  Text(
                    "Gracias por comprar en SmartTech Store",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.45),
                      fontSize: 12,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}