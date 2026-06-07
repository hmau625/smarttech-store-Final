import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';
import 'register_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final correoController = TextEditingController();
  final passwordController = TextEditingController();
  final authService = AuthService();

  bool isLoading = false;
  bool obscurePassword = true;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  static const _accent  = Color(0xFF00D4FF);
  static const _surface = Color(0xFF0D1F33);
  static const _card    = Color(0xFF0F2A44);
  static const _textPri = Color(0xFFEFF6FF);
  static const _textSec = Color(0xFF7A9BB5);
  static const _divider = Color(0xFF1A2E44);
  static const _input   = Color(0xFF162638);

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    correoController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.error_outline, color: Colors.redAccent, size: 16),
        const SizedBox(width: 8),
        Expanded(child: Text(message, style: const TextStyle(color: _textPri, fontSize: 13))),
      ]),
      backgroundColor: _surface,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.redAccent.withOpacity(0.35)),
      ),
      duration: const Duration(seconds: 2),
    ));
  }

  bool isValidEmail(String email) {
    final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    return regex.hasMatch(email);
  }

  void login() async {
    final correo = correoController.text.trim();
    final password = passwordController.text.trim();

    if (correo.isEmpty || password.isEmpty) {
      showError("Todos los campos son obligatorios");
      return;
    }

    if (!isValidEmail(correo)) {
      showError("El correo no tiene un formato válido");
      return;
    }

    if (password.length < 6) {
      showError("La contraseña debe tener al menos 6 caracteres");
      return;
    }

    setState(() => isLoading = true);

    try {
      final result = await authService.login(correo, password);

      if (result["success"]) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', result["token"]);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else {
        setState(() => isLoading = false);
        showError(result["message"]);
      }
    } catch (e) {
      setState(() => isLoading = false);
      showError("Error de conexión. Intenta nuevamente");
    }
  }

  InputDecoration _inputStyle(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: _textSec.withOpacity(0.5), fontSize: 13),
      prefixIcon: Icon(icon, color: _accent.withOpacity(0.7), size: 20),
      filled: true,
      fillColor: _input,
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _accent, width: 1.4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    // Responsive: 90% del ancho en móvil, max 420 en desktop
    final cardWidth = screenW < 500 ? screenW * 0.90 : 420.0;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/fondo_SmarTech.jpeg'),
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
        ),
        child: Container(
          color: Colors.black.withOpacity(0.55),
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                  child: Container(
                    width: cardWidth,
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: _card.withOpacity(0.92),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: _accent.withOpacity(0.10), width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.50),
                          blurRadius: 40,
                          spreadRadius: 4,
                          offset: const Offset(0, 10),
                        ),
                        BoxShadow(
                          color: _accent.withOpacity(0.05),
                          blurRadius: 60,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ── Logo ──
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _accent.withOpacity(0.10),
                            shape: BoxShape.circle,
                            border: Border.all(color: _accent.withOpacity(0.25)),
                            boxShadow: [BoxShadow(color: _accent.withOpacity(0.15), blurRadius: 20)],
                          ),
                          child: const Icon(Icons.memory, color: _accent, size: 32),
                        ),
                        const SizedBox(height: 14),
                        const Text("SmartTech",
                            style: TextStyle(color: _textPri, fontWeight: FontWeight.w800,
                                fontSize: 22, letterSpacing: 1.5)),
                        const Text("STORE",
                            style: TextStyle(color: _accent, fontWeight: FontWeight.w600,
                                fontSize: 10, letterSpacing: 5)),
                        const SizedBox(height: 6),
                        Text("Inicia sesión en tu cuenta",
                            style: TextStyle(color: _textSec.withOpacity(0.7), fontSize: 12)),

                        const SizedBox(height: 24),
                        Divider(color: _divider.withOpacity(0.5)),
                        const SizedBox(height: 20),

                        // ── Email ──
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text("Correo Electrónico",
                              style: TextStyle(color: _textSec, fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: correoController,
                          style: const TextStyle(color: _textPri, fontSize: 14),
                          keyboardType: TextInputType.emailAddress,
                          decoration: _inputStyle("tu@email.com", Icons.email_outlined),
                        ),

                        const SizedBox(height: 16),

                        // ── Password ──
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text("Contraseña",
                              style: TextStyle(color: _textSec, fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: passwordController,
                          obscureText: obscurePassword,
                          style: const TextStyle(color: _textPri, fontSize: 14),
                          decoration: _inputStyle("••••••••", Icons.lock_outline).copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                color: _textSec, size: 20,
                              ),
                              onPressed: () => setState(() => obscurePassword = !obscurePassword),
                            ),
                          ),
                        ),

                        const SizedBox(height: 28),

                        // ── Botón ──
                        isLoading
                            ? const SizedBox(
                                height: 54,
                                child: Center(child: CircularProgressIndicator(color: _accent, strokeWidth: 2.5)),
                              )
                            : GestureDetector(
                                onTap: login,
                                child: Container(
                                  width: double.infinity,
                                  height: 54,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF00D4FF), Color(0xFF0090B8)],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(color: _accent.withOpacity(0.35), blurRadius: 18, offset: const Offset(0, 4)),
                                    ],
                                  ),
                                  child: const Center(
                                    child: Text("Iniciar Sesión",
                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800,
                                            fontSize: 15, letterSpacing: 0.5)),
                                  ),
                                ),
                              ),

                        const SizedBox(height: 20),
                        Divider(color: _divider.withOpacity(0.5)),
                        const SizedBox(height: 8),

                        // ── Link registro ──
                        TextButton(
                          onPressed: () => Navigator.push(
                            context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                          child: RichText(
                            text: TextSpan(
                              text: "¿No tienes cuenta? ",
                              style: TextStyle(color: _textSec.withOpacity(0.7), fontSize: 13),
                              children: const [
                                TextSpan(
                                  text: "Regístrate",
                                  style: TextStyle(color: _accent, fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}