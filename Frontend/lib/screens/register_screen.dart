import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nombreController = TextEditingController();
  final correoController = TextEditingController();
  final passwordController = TextEditingController();

  final authService = AuthService();

  bool isLoading = false;
  bool obscurePassword = true;

  String passwordStrength = "";
  Color strengthColor = Colors.grey;

  void checkPasswordStrength(String password) {
    if (password.isEmpty) {
      setState(() {
        passwordStrength = "";
      });
      return;
    }

    int score = 0;

    if (password.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) score++;

    if (score <= 1) {
      passwordStrength = "Débil";
      strengthColor = Colors.red;
    } else if (score == 2 || score == 3) {
      passwordStrength = "Media";
      strengthColor = Colors.orange;
    } else {
      passwordStrength = "Fuerte";
      strengthColor = Colors.green;
    }

    setState(() {});
  }

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  bool isValidEmail(String email) {
    final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    return regex.hasMatch(email);
  }

  void register() async {
    final nombre = nombreController.text.trim();
    final correo = correoController.text.trim();
    final password = passwordController.text.trim();

    if (nombre.isEmpty || correo.isEmpty || password.isEmpty) {
      showError("Todos los campos son obligatorios");
      return;
    }

    if (nombre.length < 3) {
      showError("El nombre debe tener al menos 3 caracteres");
      return;
    }

    if (!isValidEmail(correo)) {
      showError("Correo inválido");
      return;
    }

    if (password.length < 6) {
      showError("Contraseña muy corta");
      return;
    }

    setState(() => isLoading = true);

    try {
      final result = await authService.register(nombre, correo, password);

      setState(() => isLoading = false);

      if (result["success"]) {
        showSuccess("Cuenta creada 🚀");
        Navigator.pop(context);
      } else {
        showError(result["message"]);
      }
    } catch (e) {
      setState(() => isLoading = false);
      showError("Error de conexión");
    }
  }

  // 🔥 NUEVO ESTILO INPUT
  InputDecoration _inputStyle(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white38),
      prefixIcon: Icon(icon, color: Colors.white70),
      filled: true,
      fillColor: const Color(0xFF2C3E50),
      contentPadding: const EdgeInsets.symmetric(vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  void dispose() {
    nombreController.dispose();
    correoController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1A2F),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              width: 350,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF0F2A44),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  // HEADER
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Crear Cuenta",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // NOMBRE
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Nombre Completo",
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nombreController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputStyle("Tu nombre", Icons.person),
                  ),

                  const SizedBox(height: 15),

                  // EMAIL
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Correo Electrónico",
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: correoController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputStyle("tu@email.com", Icons.email),
                  ),

                  const SizedBox(height: 15),

                  // PASSWORD
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Contraseña",
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                  const SizedBox(height: 8),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: passwordController,
                        obscureText: obscurePassword,
                        onChanged: checkPasswordStrength,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputStyle("Mínimo 8 caracteres", Icons.lock)
                            .copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Colors.white70,
                            ),
                            onPressed: () {
                              setState(() {
                                obscurePassword = !obscurePassword;
                              });
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 6),

                      if (passwordStrength.isNotEmpty)
                        Text(
                          "Seguridad: $passwordStrength",
                          style: TextStyle(
                            color: strengthColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  // BOTÓN
                  isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: register,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1ABCFE),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              "Crear Cuenta",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),

                  const SizedBox(height: 15),

                  const Divider(color: Colors.white24),

                  const SizedBox(height: 10),

                  // LOGIN
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      "¿Ya tienes cuenta? Inicia sesión",
                      style: TextStyle(
                        color: Color(0xFF1ABCFE),
                        fontWeight: FontWeight.bold,
                      ),
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