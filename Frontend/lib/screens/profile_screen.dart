import 'package:flutter/material.dart';
import '../services/user_service.dart';
import 'login_screen.dart';
import 'orders_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  final String token;

  const ProfileScreen({
    super.key,
    required this.token,
  });

  @override
  State<ProfileScreen> createState() =>
      _ProfileScreenState();
}

class _ProfileScreenState
    extends State<ProfileScreen> {

  final UserService service = UserService();

  Map<String, dynamic>? user;
  bool loading = true;

  String? profileImage;

  // 🎨 COLORES UI
  static const _bg = Color(0xFF060D17);
  static const _card = Color(0xFF111E2E);
  static const _accent = Color(0xFF00D4FF);
  static const _textPri = Color(0xFFEFF6FF);
  static const _textSec = Color(0xFF7A9BB5);

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  void loadUser() async {
    try {
      final data =
          await service.getMe(widget.token);

      if (!mounted) return;

      setState(() {
        user = data;
        profileImage =
            data?['imagen']?.toString();
        loading = false;
      });
    } catch (e) {
      print("ERROR: $e");

      if (!mounted) return;

      setState(() {
        user = null;
        loading = false;
      });
    }
  }

  void logout() async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.remove('token');

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
      (route) => false,
    );
  }

  Future<void> deleteAccount() async {

    final confirm = await showDialog(
      context: context,

      builder: (context) => AlertDialog(
        backgroundColor: _card,

        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(20),
        ),

        title: const Text(
          "Eliminar cuenta",
          style: TextStyle(
            color: _textPri,
            fontWeight: FontWeight.bold,
          ),
        ),

        content: const Text(
          "¿Estás seguro? Esta acción no se puede deshacer.",
          style: TextStyle(
            color: _textSec,
          ),
        ),

        actions: [

          TextButton(
            onPressed: () =>
                Navigator.pop(context, false),

            child: const Text(
              "Cancelar",
              style: TextStyle(
                color: _textSec,
              ),
            ),
          ),

          TextButton(
            onPressed: () =>
                Navigator.pop(context, true),

            child: const Text(
              "Eliminar",
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final success =
          await service.deleteAccount(
        widget.token,
      );

      if (success) {
        final prefs =
            await SharedPreferences
                .getInstance();

        await prefs.remove('token');

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const LoginScreen(),
          ),
          (route) => false,
        );
      }
    } catch (e) {

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content:
              Text("Error al eliminar cuenta"),
        ),
      );
    }
  }

  // 🔥 CARD MODERNA
  Widget infoCard({
    required Widget child,
  }) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(22),

      decoration: BoxDecoration(
        color: _card,

        borderRadius:
            BorderRadius.circular(24),

        border: Border.all(
          color:
              Colors.white.withOpacity(0.04),
        ),

        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),

      child: child,
    );
  }

  // 🔥 BOTONES PREMIUM
  Widget actionButton({
    required String text,
    required VoidCallback onTap,
    required Color color,
    required IconData icon,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 58,

      child: ElevatedButton.icon(
        onPressed: onTap,

        style: ElevatedButton.styleFrom(
          backgroundColor: color,

          elevation: 8,

          shadowColor:
              color.withOpacity(0.35),

          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(18),
          ),
        ),

        icon: Icon(icon, color: Colors.black),

        label: Text(
          text,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget buildAvatar() {

    final validImage =
        profileImage != null &&
            profileImage!.startsWith("http");

    return Stack(
      children: [

        Container(
          padding: const EdgeInsets.all(4),

          decoration: BoxDecoration(
            shape: BoxShape.circle,

            border: Border.all(
              color: _accent,
              width: 2.5,
            ),

            boxShadow: [
              BoxShadow(
                color:
                    _accent.withOpacity(0.35),
                blurRadius: 18,
              ),
            ],
          ),

          child: CircleAvatar(
            radius: 55,

            backgroundColor:
                const Color(0xFF162638),

            backgroundImage: validImage
                ? NetworkImage(profileImage!)
                : null,

            child: !validImage
                ? const Icon(
                    Icons.person,
                    size: 55,
                    color: Colors.white,
                  )
                : null,
          ),
        ),

        Positioned(
          bottom: 0,
          right: 0,

          child: GestureDetector(
            onTap: () async {

              final picker = ImagePicker();

              final picked =
                  await picker.pickImage(
                source: ImageSource.gallery,
              );

              if (picked != null) {

                final url =
                    await service
                        .uploadProfileImage(
                  widget.token,
                  picked,
                );

                if (url != null) {
                  setState(() {
                    profileImage = url;
                  });
                }
              }
            },

            child: Container(
              padding:
                  const EdgeInsets.all(8),

              decoration: BoxDecoration(
                color: _accent,
                shape: BoxShape.circle,

                boxShadow: [
                  BoxShadow(
                    color: _accent
                        .withOpacity(0.45),
                    blurRadius: 10,
                  ),
                ],
              ),

              child: const Icon(
                Icons.edit,
                size: 18,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: _bg,

      extendBodyBehindAppBar: true,

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,

        title: const Text(
          "Mi Perfil",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: 0.5,
          ),
        ),
      ),

      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,

            colors: [
              Color(0xFF060D17),
              Color(0xFF091524),
              Color(0xFF0E1E30),
            ],
          ),
        ),

        child: SafeArea(

          child: loading
              ? const Center(
                  child:
                      CircularProgressIndicator(
                    color: _accent,
                  ),
                )

              : user == null
                  ? const Center(
                      child: Text(
                        "Error cargando usuario",

                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    )

                  : SingleChildScrollView(
                      padding:
                          const EdgeInsets.all(20),

                      child: Column(
                        children: [

                          const SizedBox(height: 10),

                          // 🔥 AVATAR
                          buildAvatar(),

                          const SizedBox(height: 22),

                          // 🔥 NOMBRE
                          Text(
                            user!['nombre'] ?? '',

                            style: const TextStyle(
                              color: _textPri,
                              fontSize: 28,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 8),

                          // 🔥 EMAIL
                          Text(
                            user!['correo'] ?? '',

                            style: const TextStyle(
                              color: _textSec,
                              fontSize: 15,
                            ),
                          ),

                          const SizedBox(height: 28),

                          // 🔥 INFO CARD
                          infoCard(
                            child: Column(
                              children: [

                                Row(
                                  children: [

                                    Container(
                                      padding:
                                          const EdgeInsets
                                              .all(10),

                                      decoration:
                                          BoxDecoration(
                                        color: _accent
                                            .withOpacity(
                                                0.12),

                                        borderRadius:
                                            BorderRadius
                                                .circular(
                                                    14),
                                      ),

                                      child: const Icon(
                                        Icons.verified_user,
                                        color: _accent,
                                      ),
                                    ),

                                    const SizedBox(
                                        width: 14),

                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment
                                              .start,

                                      children: [

                                        const Text(
                                          "Rol de usuario",

                                          style: TextStyle(
                                            color:
                                                _textSec,
                                            fontSize:
                                                13,
                                          ),
                                        ),

                                        const SizedBox(
                                            height: 4),

                                        Text(
                                          "${user!['rol']}",

                                          style:
                                              const TextStyle(
                                            color:
                                                _textPri,
                                            fontSize:
                                                17,
                                            fontWeight:
                                                FontWeight
                                                    .bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 28),

                          // 🔥 MIS COMPRAS
                          actionButton(
                            text: "Mis compras",

                            onTap: () {
                              Navigator.push(
                                context,

                                MaterialPageRoute(
                                  builder: (_) =>
                                      const OrdersScreen(),
                                ),
                              );
                            },

                            color: Colors.orange,

                            icon:
                                Icons.shopping_bag,
                          ),

                          const SizedBox(height: 16),

                          // 🔥 CERRAR SESIÓN
                          actionButton(
                            text: "Cerrar sesión",

                            onTap: logout,

                            color: _accent,

                            icon: Icons.logout,
                          ),

                          const SizedBox(height: 16),

                          // 🔥 ELIMINAR CUENTA
                          actionButton(
                            text: "Eliminar cuenta",

                            onTap: deleteAccount,

                            color: Colors.redAccent,

                            icon: Icons.delete_forever,
                          ),

                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
        ),
      ),
    );
  }
}