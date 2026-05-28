import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../services/favorite_service.dart';
import 'product_detail_screen.dart';
import 'cart_screen.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import '../utils/auth_utils.dart';
import 'favorite_screen.dart';
import 'add_product_screen.dart';

class ProductListScreen extends StatefulWidget {
  final String token;

  const ProductListScreen({super.key, required this.token});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen>
    with TickerProviderStateMixin {
  final ApiService api = ApiService();
  final FavoriteService favService = FavoriteService();

  List<Product> products = [];
  List<Product> filteredProducts = [];
  List<int> favorites = [];

  late bool isAdmin;
  bool loadingFav = false;
  bool isLoading = true;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final TextEditingController searchController = TextEditingController();

  // ── Color palette ──────────────────────────────────────────────────────────
  static const _bg         = Color(0xFF060D17);
  static const _surface    = Color(0xFF0D1F33);
  static const _card       = Color(0xFF111E2E);
  static const _cardHover  = Color(0xFF162538);
  static const _accent     = Color(0xFF00D4FF);
  static const _accentDim  = Color(0xFF0099BB);
  static const _textPri    = Color(0xFFEFF6FF);
  static const _textSec    = Color(0xFF7A9BB5);
  static const _divider    = Color(0xFF1A2E44);
  static const _shimmer    = Color(0xFF162030);

  @override
  void initState() {
    super.initState();
    isAdmin = AuthUtils.isAdmin(widget.token);

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    loadProducts();
    loadFavoritesLocal();
    loadFavorites();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadProducts() async {
    final data = await api.getProducts();
    setState(() {
      products = data;
      filteredProducts = data;
      isLoading = false;
    });
    _fadeController.forward();
  }

  void filterProducts(String query) {
    final results = products.where((p) {
      return p.name.toLowerCase().contains(query.toLowerCase()) ||
          (p.category ?? "").toLowerCase().contains(query.toLowerCase());
    }).toList();
    setState(() => filteredProducts = results);
  }

  Future<void> saveFavoritesLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'favorites',
      favorites.map((e) => e.toString()).toList(),
    );
  }

  Future<void> loadFavoritesLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList('favorites');
    if (data != null) {
      setState(() {
        favorites = data.map((e) => int.parse(e)).toList();
      });
    }
  }

  Future<void> loadFavorites() async {
    final data = await favService.getFavorites(widget.token);
    final favIds = data.map<int>((e) => e['product_id'] as int).toList();
    setState(() => favorites = favIds);
    await saveFavoritesLocal();
  }

  Future<void> toggleFavorite(int productId) async {
    if (loadingFav) return;
    setState(() => loadingFav = true);
    final isFav = favorites.contains(productId);
    if (isFav) {
      await favService.removeFavorite(widget.token, productId);
      favorites.remove(productId);
    } else {
      await favService.addFavorite(widget.token, productId);
      favorites.add(productId);
    }
    await saveFavoritesLocal();
    setState(() => loadingFav = false);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  // ── Product Card ────────────────────────────────────────────────────────────
Widget _productCard(Product p, int index) {

  final isFav = favorites.contains(p.id);

  return TweenAnimationBuilder<double>(
    tween: Tween(begin: 0.0, end: 1.0),

    duration: Duration(
      milliseconds: 300 + index * 60,
    ),

    curve: Curves.easeOutCubic,

    builder: (context, value, child) => Opacity(
      opacity: value,

      child: Transform.translate(
        offset: Offset(0, 16 * (1 - value)),
        child: child,
      ),
    ),

    child: GestureDetector(
      onTap: () async {

        final result = await Navigator.push(
          context,

          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(
              product: p,
              token: widget.token,
            ),
          ),
        );

        if (result == true) loadProducts();
      },

      child: Container(
        decoration: BoxDecoration(
          color: _card,

          borderRadius: BorderRadius.circular(18),

          border: Border.all(
            color: _divider,
            width: 1,
          ),

          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.28),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),

        child: Column(
          children: [

            // ── IMAGE AREA ────────────────────────────────────────────────
            Expanded(
              child: Container(
                width: double.infinity,

                decoration: const BoxDecoration(
                  color: Color(0xFF0A1929),

                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(18),
                  ),
                ),

                child: Stack(
                  children: [

                    // 🔥 GLOW PREMIUM
                    Center(
                      child: Container(
                        width: 120,
                        height: 120,

                        decoration: BoxDecoration(
                          shape: BoxShape.circle,

                          boxShadow: [
                            BoxShadow(
                              color: _accent.withOpacity(0.10),
                              blurRadius: 45,
                              spreadRadius: 18,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 🔥 IMAGEN
Positioned.fill(
  child: ClipRRect(
    borderRadius: BorderRadius.circular(14),

    child: Image.network(
      p.image ?? "",

      // 🔥 AHORA SÍ OCUPA TODA LA TARJETA
      fit: BoxFit.cover,

      width: double.infinity,
      height: double.infinity,

      filterQuality: FilterQuality.high,

      loadingBuilder:
          (
            context,
            child,
            progress,
          ) {

        if (progress == null) {
          return AnimatedScale(
            scale: 1,
            duration:
                const Duration(
              milliseconds: 300,
            ),
            child: child,
          );
        }

        return const Center(
          child:
              CircularProgressIndicator(
            strokeWidth: 1.8,
            color: _accent,
          ),
        );
      },

      errorBuilder:
          (
            context,
            error,
            stackTrace,
          ) {

        return Container(
          color: const Color(0xFF0A1929),

          child: const Center(
            child: Icon(
              Icons.broken_image_outlined,
              color: _textSec,
              size: 34,
            ),
          ),
        );
      },
    ),
  ),
),
                    // 🔥 FAVORITOS
                    Positioned(
                      top: 10,
                      right: 10,

                      child: GestureDetector(
                        onTap: () =>
                            toggleFavorite(p.id!),

                        child: AnimatedContainer(
                          duration: const Duration(
                            milliseconds: 220,
                          ),

                          padding:
                              const EdgeInsets.all(7),

                          decoration: BoxDecoration(
                            color: isFav
                                ? Colors.red.withOpacity(
                                    0.14,
                                  )
                                : Colors.black
                                    .withOpacity(0.25),

                            shape: BoxShape.circle,

                            border: Border.all(
                              color: isFav
                                  ? Colors.red
                                      .withOpacity(0.35)
                                  : Colors.white
                                      .withOpacity(0.08),

                              width: 1,
                            ),

                            boxShadow: [
                              BoxShadow(
                                color: Colors.black
                                    .withOpacity(0.20),

                                blurRadius: 10,
                              ),
                            ],
                          ),

                          child: Icon(
                            isFav
                                ? Icons.favorite
                                : Icons.favorite_border,

                            color: isFav
                                ? Colors.redAccent
                                : _textSec,

                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── INFO AREA ─────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(
                10,
                10,
                10,
                12,
              ),

              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(18),
                ),
              ),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [

                  Text(
                    p.name,

                    maxLines: 1,

                    overflow: TextOverflow.ellipsis,

                    style: const TextStyle(
                      color: _textPri,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,

                    children: [

                      Text(
                        "\$${p.price}",

                        style: const TextStyle(
                          color: _accent,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          letterSpacing: 0.3,
                        ),
                      ),

                      Container(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),

                        decoration: BoxDecoration(
                          color:
                              _accent.withOpacity(0.08),

                          borderRadius:
                              BorderRadius.circular(6),

                          border: Border.all(
                            color: _accent
                                .withOpacity(0.2),

                            width: 0.5,
                          ),
                        ),

                        child: const Icon(
                          Icons.arrow_forward_ios,
                          size: 10,
                          color: _accentDim,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  // ── Skeleton loader ─────────────────────────────────────────────────────────
 Widget _skeleton() {
  return GridView.builder(
    padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),

    itemCount: 9,

    gridDelegate:
        const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 3,

      // 🔥 MÁS ESPACIO ENTRE TARJETAS
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,

      // 🔥 TARJETAS MÁS COMPACTAS
      childAspectRatio: 0.62,
    ),

    itemBuilder: (_, i) => _SkeletonCard(
      delay: i * 80,
    ),
  );
}

  // ── AppBar action button ────────────────────────────────────────────────────
  Widget _navAction({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.white.withOpacity(0.07),
            width: 1,
          ),
        ),
        child: Icon(icon, color: _textPri, size: 18),
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
        toolbarHeight: 58,
        titleSpacing: 16,
        title: Row(
          children: [
            // Logo mark
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _accent.withOpacity(0.25),
                  width: 1,
                ),
              ),
              child: const Icon(Icons.memory, color: _accent, size: 16),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "SmartTech",
                  style: TextStyle(
                    color: _textPri,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    letterSpacing: 1.0,
                  ),
                ),
                Text(
                  "STORE",
                  style: TextStyle(
                    color: _accent,
                    fontWeight: FontWeight.w500,
                    fontSize: 9,
                    letterSpacing: 3.0,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          _navAction(
            icon: Icons.favorite_outline,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FavoritesScreen(token: widget.token),
              ),
            ),
          ),
          _navAction(
            icon: Icons.shopping_bag_outlined,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CartScreen()),
            ),
          ),
          _navAction(
            icon: Icons.person_outline,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProfileScreen(token: widget.token),
              ),
            ),
          ),
          _navAction(
            icon: Icons.logout,
            onTap: logout,
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: _divider,
          ),
        ),
      ),

      floatingActionButton: isAdmin
          ? FloatingActionButton(
              backgroundColor: _accent,
              elevation: 6,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AddProductScreen()),
                ).then((_) => loadProducts());
              },
              child: const Icon(Icons.add, color: _bg, size: 22),
            )
          : null,

      body: Column(
        children: [
          // ── Search bar ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
            child: Container(
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _divider, width: 1),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: searchController,
                onChanged: filterProducts,
                style: const TextStyle(
                  color: _textPri,
                  fontSize: 13,
                  letterSpacing: 0.2,
                ),
                decoration: InputDecoration(
                  hintText: "Buscar productos o categoría…",
                  hintStyle: const TextStyle(
                    color: _textSec,
                    fontSize: 13,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: _textSec,
                    size: 18,
                  ),
                  suffixIcon: searchController.text.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            searchController.clear();
                            filterProducts('');
                          },
                          child: const Icon(
                            Icons.close,
                            color: _textSec,
                            size: 16,
                          ),
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 13,
                    horizontal: 4,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
            ),
          ),

          // ── Results count tag ─────────────────────────────────────────────
          if (!isLoading)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Row(
                children: [
                  Text(
                    "${filteredProducts.length} productos",
                    style: const TextStyle(
                      color: _textSec,
                      fontSize: 11,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 6),

          // ── Grid ──────────────────────────────────────────────────────────
          Expanded(
            child: isLoading
                ? _skeleton()
                : filteredProducts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.search_off,
                                color: _textSec, size: 44),
                            SizedBox(height: 10),
                            Text(
                              "Sin resultados",
                              style: TextStyle(
                                color: _textSec,
                                fontSize: 14,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                      )
                    : FadeTransition(
                        opacity: _fadeAnimation,
                        child: GridView.builder(
                          padding: const EdgeInsets.fromLTRB(14, 4, 14, 80),
                          itemCount: filteredProducts.length,
gridDelegate:
    const SliverGridDelegateWithFixedCrossAxisCount(
  crossAxisCount: 4,
  crossAxisSpacing: 10,
  mainAxisSpacing: 10,
  childAspectRatio: 0.72,
),
                          itemBuilder: (context, index) {
                            return _productCard(
                                filteredProducts[index], index);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

// ── Animated skeleton card ───────────────────────────────────────────────────
class _SkeletonCard extends StatefulWidget {
  final int delay;
  const _SkeletonCard({required this.delay});

  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
    Future.delayed(Duration(milliseconds: widget.delay),
        () => _ctrl.repeat(reverse: true));
  }

  

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        decoration: BoxDecoration(
          color: Color.lerp(
            const Color(0xFF0D1F33),
            const Color(0xFF162030),
            _anim.value,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF1A2E44),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Color.lerp(
                    const Color(0xFF0A1929),
                    const Color(0xFF0F2235),
                    _anim.value,
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 8,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Color.lerp(
                        const Color(0xFF1A2E44),
                        const Color(0xFF213547),
                        _anim.value,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 8,
                    width: 48,
                    decoration: BoxDecoration(
                      color: Color.lerp(
                        const Color(0xFF0D3045),
                        const Color(0xFF0F4060),
                        _anim.value,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}