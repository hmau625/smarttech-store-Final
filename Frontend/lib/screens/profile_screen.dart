import 'package:flutter/material.dart';
import '../services/user_service.dart';
import 'login_screen.dart';
import 'orders_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'admin_dashboard_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String token;
  const ProfileScreen({super.key, required this.token});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService service = UserService();

  Map<String, dynamic>? user;
  bool loading        = true;
  bool uploadingImage = false;
  String? profileImage;

  static const _bg      = Color(0xFF060D17);
  static const _card    = Color(0xFF111E2E);
  static const _accent  = Color(0xFF00D4FF);
  static const _textPri = Color(0xFFEFF6FF);
  static const _textSec = Color(0xFF7A9BB5);

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  void loadUser() async {
    try {
      final data = await service.getMe(widget.token);
      if (!mounted) return;
      setState(() {
        user         = data;
        final img = data?['imagen']?.toString();
        if (img != null && img.startsWith('http')) {
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          profileImage = '$img?t=$timestamp';
        } else {
          profileImage = img;
        }
        loading      = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { user = null; loading = false; });
    }
  }

  void logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> deleteAccount() async {
    final confirm = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Eliminar cuenta",
            style: TextStyle(color: _textPri, fontWeight: FontWeight.bold)),
        content: const Text("¿Estás seguro? Esta acción no se puede deshacer.",
            style: TextStyle(color: _textSec)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancelar", style: TextStyle(color: _textSec)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Eliminar",
                style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      final success = await service.deleteAccount(widget.token);
      if (success) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('token');
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al eliminar cuenta")),
      );
    }
  }

  // ── Subir imagen ──
  Future<void> _pickAndUpload() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;

    setState(() => uploadingImage = true);

    final bytes    = await picked.readAsBytes();
    final fileName = picked.name;
    final url      = await service.uploadProfileImage(widget.token, bytes, fileName);

    if (!mounted) return;
    setState(() {
      uploadingImage = false;
      if (url != null) {
            final timestamp = DateTime.now().millisecondsSinceEpoch;
            profileImage = '$url?t=$timestamp';
          }
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(url != null ? Icons.check_circle_outline : Icons.error_outline,
            color: url != null ? const Color(0xFF4CAF50) : Colors.redAccent, size: 16),
        const SizedBox(width: 8),
        Text(url != null ? "Foto actualizada" : "Error al subir imagen",
            style: const TextStyle(color: _textPri, fontSize: 13)),
      ]),
      backgroundColor: const Color(0xFF0D1F33),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ── Quitar imagen ──
  Future<void> _removeImage() async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.60),
      builder: (_) => Dialog(
        backgroundColor: const Color(0xFF0D1F33),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.10),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.redAccent.withOpacity(0.30)),
                ),
                child: const Icon(Icons.no_photography_outlined,
                    color: Colors.redAccent, size: 28),
              ),
              const SizedBox(height: 16),
              const Text("¿Quitar foto de perfil?",
                  style: TextStyle(color: _textPri, fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 8),
              const Text("Se mostrará el ícono por defecto",
                  style: TextStyle(color: _textSec, fontSize: 13)),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context, false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A2E44),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text("Cancelar",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: _textSec, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context, true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.redAccent.withOpacity(0.40)),
                      ),
                      child: const Text("Quitar",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.redAccent, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
    if (confirm != true) return;

    // Llamar al backend para borrar la imagen de la BD
    final ok = await service.removeProfileImage(widget.token);

    if (mounted) {
      if (ok) {
        setState(() => profileImage = null);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: const [
            Icon(Icons.check_circle_outline, color: Color(0xFF4CAF50), size: 16),
            SizedBox(width: 8),
            Text("Foto eliminada", style: TextStyle(color: _textPri, fontSize: 13)),
          ]),
          backgroundColor: const Color(0xFF0D1F33),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: const [
            Icon(Icons.error_outline, color: Colors.redAccent, size: 16),
            SizedBox(width: 8),
            Text("Error al eliminar foto", style: TextStyle(color: _textPri, fontSize: 13)),
          ]),
          backgroundColor: const Color(0xFF0D1F33),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    }
  }

  // ── Avatar con opciones ──
  void _showImageOptions() {
    final hasImage = profileImage != null && profileImage!.startsWith("http");
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0D1F33),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: const Color(0xFF1A2E44),
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            const Text("Foto de perfil",
                style: TextStyle(
                    color: _textPri, fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 16),
            _optionTile(
              icon: Icons.photo_library_outlined,
              label: hasImage ? "Cambiar foto" : "Subir foto",
              color: _accent,
              onTap: () { Navigator.pop(context); _pickAndUpload(); },
            ),
            if (hasImage) ...[
              const SizedBox(height: 8),
              _optionTile(
                icon: Icons.delete_outline_rounded,
                label: "Quitar foto",
                color: Colors.redAccent,
                onTap: () { Navigator.pop(context); _removeImage(); },
              ),
            ],
            const SizedBox(height: 8),
            _optionTile(
              icon: Icons.close,
              label: "Cancelar",
              color: _textSec,
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _optionTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Text(label,
              style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 14)),
        ]),
      ),
    );
  }

  Widget buildAvatar() {
    final validImage = profileImage != null && profileImage!.startsWith("http");
    return Stack(
      children: [
        GestureDetector(
          onTap: _showImageOptions,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _accent, width: 2.5),
              boxShadow: [BoxShadow(color: _accent.withOpacity(0.35), blurRadius: 18)],
            ),
            child: uploadingImage
                ? const CircleAvatar(
                    radius: 55,
                    backgroundColor: Color(0xFF162638),
                    child: CircularProgressIndicator(color: _accent, strokeWidth: 2),
                  )
                : CircleAvatar(
                    radius: 55,
                    backgroundColor: const Color(0xFF162638),
                    backgroundImage: validImage ? NetworkImage(profileImage!) : null,
                    child: !validImage
                        ? const Icon(Icons.person, size: 55, color: Colors.white)
                        : null,
                  ),
          ),
        ),
        // ── Botón editar ──
        Positioned(
          bottom: 0, right: 0,
          child: GestureDetector(
            onTap: _showImageOptions,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _accent,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: _accent.withOpacity(0.45), blurRadius: 10)],
              ),
              child: const Icon(Icons.camera_alt, size: 18, color: Colors.black),
            ),
          ),
        ),
      ],
    );
  }

  Widget infoCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.25), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      child: child,
    );
  }

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
          shadowColor: color.withOpacity(0.35),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        icon: Icon(icon, color: Colors.black),
        label: Text(text,
            style: const TextStyle(
                color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = user?['rol'] == 'admin';

    return Scaffold(
      backgroundColor: _bg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: const Text("Mi Perfil",
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold,
                fontSize: 20, letterSpacing: 0.5)),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF060D17), Color(0xFF091524), Color(0xFF0E1E30)],
          ),
        ),
        child: SafeArea(
          child: loading
              ? const Center(child: CircularProgressIndicator(color: _accent))
              : user == null
                  ? const Center(child: Text("Error cargando usuario",
                      style: TextStyle(color: Colors.white, fontSize: 16)))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const SizedBox(height: 10),
                          buildAvatar(),
                          const SizedBox(height: 22),

                          Text(user!['nombre'] ?? '',
                              style: const TextStyle(
                                  color: _textPri, fontSize: 28,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),

                          Text(user!['correo'] ?? '',
                              style: const TextStyle(color: _textSec, fontSize: 15)),
                          const SizedBox(height: 28),

                          infoCard(
                            child: Row(children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: _accent.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(Icons.verified_user, color: _accent),
                              ),
                              const SizedBox(width: 14),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Rol de usuario",
                                      style: TextStyle(color: _textSec, fontSize: 13)),
                                  const SizedBox(height: 4),
                                  Text("${user!['rol']}",
                                      style: const TextStyle(
                                          color: _textPri, fontSize: 17,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ]),
                          ),
                          const SizedBox(height: 28),

                          if (isAdmin) ...[
                            actionButton(
                              text: "Panel de administración",
                              onTap: () => Navigator.push(context, MaterialPageRoute(
                                builder: (_) => AdminDashboardScreen(token: widget.token),
                              )),
                              color: _accent,
                              icon: Icons.admin_panel_settings,
                            ),
                            const SizedBox(height: 16),
                          ],

                          if (!isAdmin) ...[
                            actionButton(
                              text: "Mis compras",
                              onTap: () => Navigator.push(context, MaterialPageRoute(
                                builder: (_) => const OrdersScreen(),
                              )),
                              color: Colors.orange,
                              icon: Icons.shopping_bag,
                            ),
                            const SizedBox(height: 16),
                          ],

                          actionButton(
                            text: "Cerrar sesión",
                            onTap: logout,
                            color: const Color(0xFF1D9E75),
                            icon: Icons.logout,
                          ),
                          const SizedBox(height: 16),

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