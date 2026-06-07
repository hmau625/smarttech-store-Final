import 'package:flutter/material.dart';
import '../services/favorite_service.dart';

class FavoritesScreen extends StatefulWidget {
  final String token;

  const FavoritesScreen({super.key, required this.token});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen>
    with TickerProviderStateMixin {
  final FavoriteService favService = FavoriteService();

  List<dynamic> favorites = [];
  bool isLoading = true;

  final Set<int> _removing = {};
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

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
    loadFavorites();
  }

  Future<void> loadFavorites() async {
    setState(() => isLoading = true);
    final data = await favService.getFavorites(widget.token);
    setState(() {
      favorites = data;
      isLoading = false;
    });
  }

  String _formatPrice(dynamic raw) {
    if (raw == null) return '\$0';
    final value = (raw is num) ? raw.toDouble() : double.tryParse(raw.toString()) ?? 0.0;
    final intPart = value.toInt();
    final decimals = value - intPart;
    final digits = intPart.toString();
    final buf = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buf.write('.');
      buf.write(digits[i]);
    }
    return decimals > 0.001
        ? '\$${buf.toString()},${(decimals * 100).round().toString().padLeft(2, '0')}'
        : '\$${buf.toString()}';
  }

  // ✅ Extrae el productId de forma segura probando los campos posibles
  int? _getProductId(dynamic fav) {
    // Intenta product_id primero, luego id del producto anidado, luego id raíz
    return (fav['product_id'] ?? fav['product']?['id'] ?? fav['id']) as int?;
  }

  Future<void> _removeFavorite(int index) async {
    if (_removing.contains(index)) return;

    final removedItem = favorites[index];
    final productId   = _getProductId(removedItem);

    if (productId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Error: no se pudo identificar el producto",
              style: TextStyle(color: Color(0xFFEFF6FF), fontSize: 13)),
          backgroundColor: const Color(0xFF0D1F33),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() => _removing.add(index));

    final success = await favService.removeFavorite(widget.token, productId);

    if (!mounted) return;

    if (!success) {
      setState(() => _removing.remove(index));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.error_outline_rounded,
                  color: Colors.orangeAccent, size: 16),
              SizedBox(width: 8),
              Text("No se pudo eliminar, intenta de nuevo",
                  style: TextStyle(color: Color(0xFFEFF6FF), fontSize: 13)),
            ],
          ),
          backgroundColor: const Color(0xFF0D1F33),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
                color: Colors.orangeAccent.withOpacity(0.25), width: 1),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    _listKey.currentState?.removeItem(
      index,
      (context, animation) => SizeTransition(
        sizeFactor: animation,
        axisAlignment: -1,
        child: FadeTransition(
          opacity: animation,
          child: _favCard(removedItem, index, isRemoving: false),
        ),
      ),
      duration: const Duration(milliseconds: 280),
    );

    setState(() {
      favorites.removeAt(index);
      _removing.remove(index);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.favorite_border_rounded,
                color: Colors.redAccent, size: 16),
            SizedBox(width: 8),
            Text("Eliminado de favoritos",
                style: TextStyle(color: Color(0xFFEFF6FF), fontSize: 13)),
          ],
        ),
        backgroundColor: const Color(0xFF0D1F33),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.redAccent.withOpacity(0.25), width: 1),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _removeAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.60),
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF0D1F33),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 28, 28, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.10),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Colors.redAccent.withOpacity(0.30), width: 1.5),
                ),
                child: const Icon(Icons.delete_sweep_rounded,
                    color: Colors.redAccent, size: 28),
              ),
              const SizedBox(height: 18),
              const Text("¿Eliminar todos?",
                  style: TextStyle(
                      color: Color(0xFFEFF6FF),
                      fontSize: 18,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              const Text(
                "Se eliminarán todos tus productos favoritos. Esta acción no se puede deshacer.",
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Color(0xFF7A9BB5), fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx, false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A2E44),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text("Cancelar",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Color(0xFF7A9BB5),
                                fontWeight: FontWeight.w600,
                                fontSize: 13)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx, true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.redAccent.withOpacity(0.40),
                              width: 1),
                        ),
                        child: const Text("Eliminar todo",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.w700,
                                fontSize: 13)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed != true) return;
    for (final fav in favorites) {
      // ✅ usa _getProductId también aquí
      final pid = _getProductId(fav);
      if (pid != null) await favService.removeFavorite(widget.token, pid);
    }
    setState(() {
      favorites.clear();
      _removing.clear();
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.delete_sweep_rounded,
                  color: Colors.redAccent, size: 16),
              SizedBox(width: 8),
              Text("Todos los favoritos eliminados",
                  style: TextStyle(color: Color(0xFFEFF6FF), fontSize: 13)),
            ],
          ),
          backgroundColor: const Color(0xFF0D1F33),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
                color: Colors.redAccent.withOpacity(0.25), width: 1),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _favCard(dynamic fav, int index, {bool isRemoving = false}) {
    final product = fav['product'];
    final removing = isRemoving || _removing.contains(index);

    return _FavHoverCard(
      onRemove: removing ? null : () => _removeFavorite(index),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFF0A1929),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _divider, width: 1),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: product['image'] != null
                      ? Image.network(product['image'],
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                              Icons.broken_image_outlined,
                              color: _textSec,
                              size: 26))
                      : const Icon(Icons.image_outlined,
                          color: _textSec, size: 26),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Opacity(
                opacity: removing ? 0.5 : 1.0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product['name'] ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: _textPri,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            height: 1.3)),
                    const SizedBox(height: 4),
                    if ((product['brand'] ?? '').toString().isNotEmpty)
                      Text(product['brand'],
                          style: const TextStyle(
                              color: _textSec,
                              fontSize: 12,
                              fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    if ((product['category'] ?? '').toString().isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: _accent.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: _accent.withOpacity(0.20), width: 0.8),
                        ),
                        child: Text(product['category'],
                            style: const TextStyle(
                                color: _accent,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3)),
                      ),
                    const SizedBox(height: 10),
                    Text(_formatPrice(product['price']),
                        style: const TextStyle(
                            color: _accent,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            letterSpacing: 0.2)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: removing ? null : () => _removeFavorite(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: removing
                      ? Colors.redAccent.withOpacity(0.06)
                      : Colors.redAccent.withOpacity(0.13),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Colors.redAccent
                          .withOpacity(removing ? 0.20 : 0.40),
                      width: 1.2),
                  boxShadow: removing
                      ? []
                      : [
                          BoxShadow(
                              color: Colors.redAccent.withOpacity(0.18),
                              blurRadius: 10,
                              spreadRadius: 1),
                        ],
                ),
                child: removing
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.redAccent,
                        ),
                      )
                    : const Icon(Icons.favorite_rounded,
                        color: Colors.redAccent, size: 22),
              ),
            ),
          ],
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
        toolbarHeight: 70,
        leadingWidth: 56,
        leading: Center(
          child: _BackButton(onTap: () => Navigator.pop(context)),
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _PulsingHeart(),
                const SizedBox(width: 10),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFFFF6B8A), Color(0xFFFF3D6B)],
                  ).createShader(bounds),
                  child: const Text(
                    "Mis Favoritos",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ),
            if (favorites.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  "${favorites.length} producto${favorites.length == 1 ? '' : 's'} guardado${favorites.length == 1 ? '' : 's'}",
                  style: TextStyle(
                    color: Colors.redAccent.withOpacity(0.65),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
        centerTitle: true,
        actions: [
          if (favorites.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: GestureDetector(
                onTap: _removeAll,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Colors.redAccent.withOpacity(0.35), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.delete_sweep_rounded,
                          color: Colors.redAccent, size: 18),
                      SizedBox(width: 5),
                      Text("Limpiar",
                          style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _divider),
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Color(0xFF00D4FF)))
          : favorites.isEmpty
              ? _emptyState()
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: const [
                          Icon(Icons.touch_app_rounded,
                              color: Color(0xFF7A9BB5), size: 12),
                          SizedBox(width: 4),
                          Text("Toca ❤️ para eliminar",
                              style: TextStyle(
                                  color: Color(0xFF7A9BB5), fontSize: 11)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: AnimatedList(
                        key: _listKey,
                        padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
                        initialItemCount: favorites.length,
                        itemBuilder: (context, index, animation) {
                          return SizeTransition(
                            sizeFactor: animation,
                            axisAlignment: -1,
                            child: FadeTransition(
                              opacity: animation,
                              child: _favCard(favorites[index], index),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1F33),
              shape: BoxShape.circle,
              border: Border.all(
                  color: Colors.redAccent.withOpacity(0.20), width: 1.5),
              boxShadow: [
                BoxShadow(
                    color: Colors.redAccent.withOpacity(0.08),
                    blurRadius: 24,
                    spreadRadius: 4)
              ],
            ),
            child: const Icon(Icons.favorite_border_rounded,
                size: 48, color: Colors.redAccent),
          ),
          const SizedBox(height: 20),
          const Text("Sin favoritos aún",
              style: TextStyle(
                  color: Color(0xFFEFF6FF),
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text(
            "Guarda los productos que más te gusten\ntocando el corazón en cada tarjeta.",
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Color(0xFF7A9BB5), fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }
}

// ── Botón Volver ──────────────────────────────────────────────────────────────
class _BackButton extends StatefulWidget {
  final VoidCallback onTap;
  const _BackButton({required this.onTap});

  @override
  State<_BackButton> createState() => _BackButtonState();
}

class _BackButtonState extends State<_BackButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 130));
    _scale = Tween<double>(begin: 1.0, end: 0.82)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTapDown(_) => _ctrl.forward();
  void _onTapUp(_) {
    _ctrl.reverse();
    widget.onTap();
  }
  void _onTapCancel() => _ctrl.reverse();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => Transform.scale(
          scale: _scale.value,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF112233), Color(0xFF0D1F33)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: const Color(0xFF00D4FF).withOpacity(0.35),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00D4FF).withOpacity(0.18),
                  blurRadius: 10,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.35),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  top: 4,
                  left: 4,
                  child: Container(
                    width: 16,
                    height: 8,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withOpacity(0.08),
                          Colors.transparent,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFF7AE8FF), Color(0xFF00D4FF)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ).createShader(bounds),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 17,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Corazón con pulso ─────────────────────────────────────────────────────────
class _PulsingHeart extends StatefulWidget {
  @override
  State<_PulsingHeart> createState() => _PulsingHeartState();
}

class _PulsingHeartState extends State<_PulsingHeart>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.88, end: 1.12)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scale,
      builder: (_, __) => Transform.scale(
        scale: _scale.value,
        child: const Icon(Icons.favorite_rounded,
            color: Colors.redAccent, size: 20),
      ),
    );
  }
}

// ── Hover Card ────────────────────────────────────────────────────────────────
class _FavHoverCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onRemove;
  const _FavHoverCard({required this.child, required this.onRemove});

  @override
  State<_FavHoverCard> createState() => _FavHoverCardState();
}

class _FavHoverCardState extends State<_FavHoverCard> {
  bool _hovered = false;
  static const _card    = Color(0xFF111E2E);
  static const _accent  = Color(0xFF00D4FF);
  static const _divider = Color(0xFF1A2E44);

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: widget.onRemove != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: _hovered ? const Color(0xFF152234) : _card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _hovered ? _accent.withOpacity(0.50) : _divider,
            width: _hovered ? 1.5 : 1,
          ),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                      color: _accent.withOpacity(0.10),
                      blurRadius: 18,
                      spreadRadius: 2)
                ]
              : [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.28),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ],
        ),
        child: widget.child,
      ),
    );
  }
}