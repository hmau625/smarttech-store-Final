import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smarttech_store/screens/nathalia_chat_screen.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../services/user_service.dart';
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
  final UserService userService = UserService();

  List<Product> products = [];
  List<Product> filteredProducts = [];
  List<int> favorites = [];

  late bool isAdmin;
  bool loadingFav = false;
  bool isLoading = true;

  String? _profileImageUrl;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _logoPulseCtrl;
  late Animation<double> _logoPulse;

  final TextEditingController searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String? selectedCategory;
  String? selectedSort;

  List<String> get categories {
    final cats = products
        .map((p) => p.category ?? '')
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return cats;
  }

  static const _bg        = Color(0xFF060D17);
  static const _surface   = Color(0xFF0D1F33);
  static const _card      = Color(0xFF111E2E);
  static const _accent    = Color(0xFF00D4FF);
  static const _accentDim = Color(0xFF0099BB);
  static const _textPri   = Color(0xFFEFF6FF);
  static const _textSec   = Color(0xFF7A9BB5);
  static const _divider   = Color(0xFF1A2E44);

  @override
  void initState() {
    super.initState();
    isAdmin = AuthUtils.isAdmin(widget.token);

    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);

    _logoPulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat(reverse: true);
    _logoPulse = Tween<double>(begin: 0.90, end: 1.0).animate(
        CurvedAnimation(parent: _logoPulseCtrl, curve: Curves.easeInOut));

    loadProducts();
    loadFavoritesLocal();
    loadFavorites();
    _loadProfileImage();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _logoPulseCtrl.dispose();
    searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileImage() async {
    // 1. Mostrar foto cacheada de inmediato
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('profile_image_url');
    if (cached != null && cached.isNotEmpty && mounted) {
      setState(() => _profileImageUrl = cached);
    }
    // 2. Actualizar desde el servidor
    try {
      final data = await userService.getMe(widget.token);
      if (mounted && data != null) {
        final rawUrl = data['imagen'] as String?;
        final url = (rawUrl != null && rawUrl.isNotEmpty) ? rawUrl : null;
        print('🖼 FOTO PERFIL URL: $url');
        print('🖼 DATA COMPLETA: $data');
        setState(() => _profileImageUrl = url);
        if (url != null && url.isNotEmpty) {
          await prefs.setString('profile_image_url', url);
        } else {
          await prefs.remove('profile_image_url');
        }
      }
    } catch (e) {
      print('❌ ERROR cargando perfil: $e');
    }
  }

  void _scrollToTop() => _scrollController.animateTo(0,
      duration: const Duration(milliseconds: 600), curve: Curves.easeInOut);

  void _scrollToFooter() => _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 700), curve: Curves.easeInOut);

  Future<void> loadProducts() async {
    final data = await api.getProducts();
    setState(() {
      products = data;
      _applyFilters();
      isLoading = false;
    });
    _fadeController.forward();
  }

  void _applyFilters() {
    final query = searchController.text.toLowerCase();
    List<Product> result = products.where((p) {
      final matchesSearch = query.isEmpty ||
          p.name.toLowerCase().contains(query) ||
          (p.category ?? '').toLowerCase().contains(query);
      final matchesCategory =
          selectedCategory == null || (p.category ?? '') == selectedCategory;
      final hasStock = (p.stock ?? 0) > 0;
      return matchesSearch && matchesCategory && hasStock;
    }).toList();

    switch (selectedSort) {
      case 'price_asc':
        result.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_desc':
        result.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'newest':
        result = result.reversed.toList();
        break;
      case 'popular':
        result.sort((a, b) => (b.stock ?? 0).compareTo(a.stock ?? 0));
        break;
    }

    setState(() => filteredProducts = result);
  }

  void filterProducts(String query) => _applyFilters();

  void selectCategory(String? category) {
    setState(() => selectedCategory = category);
    _applyFilters();
  }

  Future<void> saveFavoritesLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        'favorites', favorites.map((e) => e.toString()).toList());
  }

  Future<void> loadFavoritesLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList('favorites');
    if (data != null) {
      setState(() => favorites = data.map((e) => int.parse(e)).toList());
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
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.60),
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF0D1F33),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 28, 28, 20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.10),
                shape: BoxShape.circle,
                border: Border.all(
                    color: Colors.redAccent.withOpacity(0.30), width: 1.5),
              ),
              child: const Icon(Icons.logout_rounded,
                  color: Colors.redAccent, size: 28),
            ),
            const SizedBox(height: 18),
            const Text("¿Cerrar sesión?",
                style: TextStyle(
                    color: Color(0xFFEFF6FF),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2)),
            const SizedBox(height: 8),
            const Text(
                "¿Estás seguro de que deseas cerrar tu sesión en SmartTech Store?",
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Color(0xFF7A9BB5), fontSize: 13, height: 1.4)),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pop(ctx, false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                        color: const Color(0xFF1A2E44),
                        borderRadius: BorderRadius.circular(12)),
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
                          color: Colors.redAccent.withOpacity(0.40), width: 1),
                    ),
                    child: const Text("Cerrar sesión",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                  ),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
    if (confirmed != true) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    Navigator.pushAndRemoveUntil(context,
        MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
  }

  String _formatPrice(dynamic raw) {
    if (raw == null) return '\$0';
    final value =
        (raw is num) ? raw.toDouble() : double.tryParse(raw.toString()) ?? 0.0;
    final intPart = value.toInt();
    final decimals = value - intPart;
    final buf = StringBuffer();
    final digits = intPart.toString();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buf.write('.');
      buf.write(digits[i]);
    }
    return decimals > 0.001
        ? '\$${buf.toString()},${(decimals * 100).round().toString().padLeft(2, '0')}'
        : '\$${buf.toString()}';
  }

  String _productCountLabel() {
    final total = products.length;
    if (total > 100) return '+100';
    if (total > 50) return '+50';
    if (total > 20) return '+20';
    if (total == 0) return '0';
    return '+$total';
  }

  int _getColumns(double width) {
    if (width >= 1200) return 5;
    if (width >= 900) return 4;
    if (width >= 600) return 3;
    return 2;
  }

  double _getRatio(double width) {
    if (width >= 600) return 0.68;
    return 0.72;
  }

  // ── Foto de perfil ────────────────────────────────────────────────────────
  Widget _profileAvatar() {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(context,
            MaterialPageRoute(builder: (_) => ProfileScreen(token: widget.token)));
        // Refrescar foto al volver
        _loadProfileImage();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _accent.withOpacity(0.07),
          border: Border.all(color: _accent.withOpacity(0.35), width: 1.5),
        ),
        child: ClipOval(
          child: _profileImageUrl != null && _profileImageUrl!.isNotEmpty
              ? Image.network(
                  // Si ya es URL completa la usa directo, si es relativa la resuelve
                  _profileImageUrl!.startsWith('http')
                      ? _profileImageUrl!
                      : ApiService.resolveImage(_profileImageUrl!),
                  fit: BoxFit.cover,
                  headers: {"Authorization": "Bearer ${widget.token}"},
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.person_outline, color: _textPri, size: 20),
                )
              : const Icon(Icons.person_outline, color: _textPri, size: 20),
        ),
      ),
    );
  }

  Widget _navAction(
      {required IconData icon,
      required VoidCallback onTap,
      String? tooltip}) {
    return Tooltip(
      message: tooltip ?? '',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _accent.withOpacity(0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _accent.withOpacity(0.18), width: 1),
            boxShadow: [
              BoxShadow(
                  color: _accent.withOpacity(0.05),
                  blurRadius: 8,
                  spreadRadius: 1)
            ],
          ),
          child: Icon(icon, color: _textPri, size: 22),
        ),
      ),
    );
  }

  // ── Sort bottom sheet ─────────────────────────────────────────────────────
  void _showSortSheet() async {
    final sorts = [
      {'key': null, 'label': 'Relevancia', 'icon': Icons.sort_rounded},
      {'key': 'price_asc', 'label': 'Precio: menor a mayor', 'icon': Icons.arrow_upward_rounded},
      {'key': 'price_desc', 'label': 'Precio: mayor a menor', 'icon': Icons.arrow_downward_rounded},
      {'key': 'newest', 'label': 'Más reciente', 'icon': Icons.fiber_new_outlined},
      {'key': 'popular', 'label': 'Más popular', 'icon': Icons.local_fire_department_outlined},
    ];

    final selected = await showModalBottomSheet<String?>(
      context: context,
      backgroundColor: _card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 8),
          Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: _divider, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 14),
          const Text("Ordenar por",
              style: TextStyle(
                  color: _textPri, fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          ...sorts.map((s) {
            final isActive = selectedSort == s['key'];
            return Column(children: [
              ListTile(
                leading: Icon(s['icon'] as IconData,
                    color: isActive ? _accent : _textSec, size: 20),
                title: Text(s['label'] as String,
                    style: TextStyle(
                        color: isActive ? _accent : _textPri,
                        fontWeight:
                            isActive ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 14)),
                trailing: isActive
                    ? const Icon(Icons.check_rounded, color: _accent, size: 18)
                    : null,
                onTap: () => Navigator.pop(
                    context, s['key']?.toString() ?? '__none__'),
              ),
              if (s != sorts.last) const Divider(color: _divider, height: 1),
            ]);
          }),
          const SizedBox(height: 10),
        ]),
      ),
    );
    if (selected == null) return;
    setState(() => selectedSort = selected == '__none__' ? null : selected);
    _applyFilters();
  }

  // ── Categorías ────────────────────────────────────────────────────────────
  Widget _categoryChips() {
    final cats = categories;
    if (cats.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(builder: (context, constraints) {
      final isMobile = constraints.maxWidth < 600;

      if (isMobile) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: GestureDetector(
            onTap: () async {
              final selected = await showModalBottomSheet<String?>(
                context: context,
                backgroundColor: _card,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20))),
                builder: (_) => DraggableScrollableSheet(
                  initialChildSize: 0.5,
                  minChildSize: 0.3,
                  maxChildSize: 0.85,
                  expand: false,
                  builder: (_, scrollCtrl) => SingleChildScrollView(
                    controller: scrollCtrl,
                    child: SafeArea(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const SizedBox(height: 8),
                    Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                            color: _divider,
                            borderRadius: BorderRadius.circular(2))),
                    const SizedBox(height: 14),
                    const Text("Categorías",
                        style: TextStyle(
                            color: _textPri,
                            fontSize: 15,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    ListTile(
                      leading: Icon(Icons.apps_rounded,
                          color: selectedCategory == null ? _accent : _textSec,
                          size: 20),
                      title: Text("Todas",
                          style: TextStyle(
                              color: selectedCategory == null
                                  ? _accent
                                  : _textPri,
                              fontWeight: selectedCategory == null
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              fontSize: 14)),
                      trailing: selectedCategory == null
                          ? const Icon(Icons.check_rounded,
                              color: _accent, size: 18)
                          : null,
                      onTap: () => Navigator.pop(context, '__all__'),
                    ),
                    const Divider(color: _divider, height: 1),
                    ...cats.map((cat) => Column(children: [
                          ListTile(
                            leading: Icon(Icons.label_outline_rounded,
                                color: selectedCategory == cat
                                    ? _accent
                                    : _textSec,
                                size: 18),
                            title: Text(cat,
                                style: TextStyle(
                                    color: selectedCategory == cat
                                        ? _accent
                                        : _textPri,
                                    fontWeight: selectedCategory == cat
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    fontSize: 14)),
                            trailing: selectedCategory == cat
                                ? const Icon(Icons.check_rounded,
                                    color: _accent, size: 18)
                                : null,
                            onTap: () => Navigator.pop(context, cat),
                          ),
                          if (cat != cats.last)
                            const Divider(color: _divider, height: 1),
                        ])),
                    const SizedBox(height: 10),
                  ]),
                    ),
                  ),
                ),
              );
              if (selected == null) return;
              selectCategory(selected == '__all__' ? null : selected);
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: selectedCategory != null
                        ? _accent.withOpacity(0.55)
                        : _divider,
                    width: selectedCategory != null ? 1.5 : 1),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.category_outlined,
                    color: selectedCategory != null ? _accent : _textSec,
                    size: 16),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    selectedCategory ?? "Todas las categorías",
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: selectedCategory != null ? _accent : _textSec,
                        fontSize: 13,
                        fontWeight: selectedCategory != null
                            ? FontWeight.w700
                            : FontWeight.w500),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.keyboard_arrow_down_rounded,
                    color: selectedCategory != null ? _accent : _textSec,
                    size: 18),
              ]),
            ),
          ),
        );
      }

      // Desktop: chips alineados a la izquierda
      return SizedBox(
        height: 42,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              _CategoryChip(
                label: 'Todas',
                isSelected: selectedCategory == null,
                onTap: () => selectCategory(null),
              ),
              const SizedBox(width: 8),
              ...cats.map((cat) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _CategoryChip(
                      label: cat,
                      isSelected: selectedCategory == cat,
                      onTap: () => selectCategory(cat),
                    ),
                  )),
            ],
          ),
        ),
      );
    });
  }

  Widget _productCard(Product p, int index) {
    final isFav = favorites.contains(p.id);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + index * 60),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child:
            Transform.translate(offset: Offset(0, 16 * (1 - value)), child: child),
      ),
      child: _HoverCard(
        onTap: () async {
          final result = await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                      ProductDetailScreen(product: p, token: widget.token)));
          if (result == true) loadProducts();
        },
        child: Column(children: [
          Expanded(
            flex: 7,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                  color: Color(0xFF0A1929),
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(15))),
              child: Stack(children: [
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        ApiService.resolveImage(p.image),
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return const Center(
                              child: CircularProgressIndicator(
                                  strokeWidth: 1.8, color: _accent));
                        },
                        errorBuilder: (context, error, stackTrace) => Container(
                          decoration: BoxDecoration(
                              color: const Color(0xFF0A1929),
                              borderRadius: BorderRadius.circular(10)),
                          child: const Center(
                              child: Icon(Icons.broken_image_outlined,
                                  color: _textSec, size: 28)),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => toggleFavorite(p.id!),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: isFav
                            ? Colors.red.withOpacity(0.22)
                            : Colors.black.withOpacity(0.52),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: isFav
                                ? Colors.redAccent.withOpacity(0.70)
                                : Colors.white.withOpacity(0.22),
                            width: 1.2),
                        boxShadow: isFav
                            ? [BoxShadow(color: Colors.redAccent.withOpacity(0.30), blurRadius: 8, spreadRadius: 1)]
                            : [BoxShadow(color: Colors.black.withOpacity(0.40), blurRadius: 6)],
                      ),
                      child: Icon(
                          isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: isFav ? Colors.redAccent : Colors.white.withOpacity(0.75),
                          size: 16),
                    ),
                  ),
                ),
              ]),
            ),
          ),
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              decoration: const BoxDecoration(
                  borderRadius:
                      BorderRadius.vertical(bottom: Radius.circular(15))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(p.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: _textPri,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                          height: 1.2)),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatPrice(p.price),
                          style: const TextStyle(
                              color: _accent,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              letterSpacing: 0.3)),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 3),
                        decoration: BoxDecoration(
                            color: _accent.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(
                                color: _accent.withOpacity(0.2), width: 0.5)),
                        child: const Icon(Icons.arrow_forward_ios,
                            size: 9, color: _accentDim),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _skeleton() {
    return LayoutBuilder(builder: (context, constraints) {
      final columns = _getColumns(constraints.maxWidth);
      return GridView.builder(
        padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
        itemCount: 10,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.68),
        itemBuilder: (_, i) => _SkeletonCard(delay: i * 80),
      );
    });
  }

  // ── Footer ────────────────────────────────────────────────────────────────
  Widget _buildFooter() {
    final productLabel = _productCountLabel();
    return Container(
      color: const Color(0xFF060D17),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(height: 1, color: _divider),
        Container(
          color: _surface,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(children: [
            GestureDetector(
              onTap: _scrollToTop,
              child: AnimatedBuilder(
                animation: _logoPulse,
                builder: (_, child) =>
                    Transform.scale(scale: _logoPulse.value, child: child),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: _accent.withOpacity(0.30), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                            color: _accent.withOpacity(0.10),
                            blurRadius: 12,
                            spreadRadius: 1)
                      ],
                    ),
                    child:
                        const Icon(Icons.memory, color: _accent, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text("SmartTech",
                            style: TextStyle(
                                color: _textPri,
                                fontWeight: FontWeight.w800,
                                fontSize: 17,
                                letterSpacing: 0.8)),
                        Text("STORE",
                            style: TextStyle(
                                color: _accent,
                                fontWeight: FontWeight.w600,
                                fontSize: 9,
                                letterSpacing: 4.0)),
                      ]),
                ]),
              ),
            ),
            const Spacer(),
            Row(children: [
              ...List.generate(
                  5,
                  (_) => const Icon(Icons.star_rounded,
                      color: Color(0xFFF59E0B), size: 13)),
              const SizedBox(width: 6),
              const Text("4.9", style: TextStyle(color: _textSec, fontSize: 11)),
            ]),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _scrollToTop,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                    color: _accent.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: _accent.withOpacity(0.22), width: 1)),
                child: Row(children: const [
                  Icon(Icons.arrow_upward_rounded, color: _accent, size: 13),
                  SizedBox(width: 4),
                  Text("Inicio",
                      style: TextStyle(
                          color: _accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
          ]),
        ),
        Container(height: 1, color: _divider),
        Container(
          color: _bg,
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(children: [
            _footerStat(productLabel, "Productos"),
            _footerStatDivider(),
            _footerStat("24/7", "Soporte IA"),
            _footerStatDivider(),
            _footerStat("48h", "Envío express"),
            _footerStatDivider(),
            _footerStat("100%", "Garantía"),
          ]),
        ),
        Container(height: 1, color: _divider),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: LayoutBuilder(builder: (context, constraints) {
            final isWide = constraints.maxWidth > 480;
            if (isWide) {
              return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 5, child: _colInfo()),
                    const SizedBox(width: 16),
                    Expanded(flex: 3, child: _colNav()),
                    const SizedBox(width: 16),
                    Expanded(flex: 3, child: _colInfo2()),
                    const SizedBox(width: 16),
                    Expanded(flex: 4, child: _colNathalia()),
                  ]);
            }
            return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _colInfo(),
                  const SizedBox(height: 20),
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child: _colNav()),
                    const SizedBox(width: 16),
                    Expanded(child: _colInfo2()),
                  ]),
                  const SizedBox(height: 20),
                  _colNathalia(),
                ]);
          }),
        ),
        Container(height: 1, color: _divider),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text("TECNOLOGÍAS QUE USAMOS",
                style: TextStyle(
                    color: _textSec,
                    fontSize: 10,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: [
              _techPill(Icons.auto_awesome, "IA Nathalia"),
              _techPill(Icons.lock_outline, "SSL / TLS"),
              _techPill(Icons.speed_outlined, "CDN Rápida"),
              _techPill(Icons.storage_outlined, "Base de datos"),
              _techPill(Icons.smartphone_outlined, "App Móvil"),
              _techPill(Icons.analytics_outlined, "Analytics"),
            ]),
          ]),
        ),
        Container(height: 1, color: _divider),
        Container(
          color: _accent.withOpacity(0.03),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              _secItem(Icons.shield_outlined, "Compra 100% segura"),
              const SizedBox(width: 20),
              _secItem(Icons.lock_outline, "SSL cifrado"),
              const SizedBox(width: 20),
              _secItem(Icons.local_shipping_outlined, "Envío garantizado"),
              const SizedBox(width: 20),
              _secItem(Icons.replay_outlined, "Devolución fácil"),
              const SizedBox(width: 20),
              _secItem(Icons.verified_outlined, "Productos certificados"),
            ]),
          ),
        ),
        Container(height: 1, color: _divider),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: LayoutBuilder(builder: (context, constraints) {
            final isWide = constraints.maxWidth > 520;
            if (isWide) {
              return Row(children: [
                const Text(
                    "© 2025 SmartTech Store · Todos los derechos reservados",
                    style: TextStyle(color: _textSec, fontSize: 10)),
                const Spacer(),
                _footerLink("Privacidad"),
                const SizedBox(width: 14),
                _footerLink("Términos"),
                const SizedBox(width: 14),
                _footerLink("Cookies"),
                const SizedBox(width: 16),
                _socialBtn(Icons.camera_alt_outlined),
                const SizedBox(width: 8),
                _socialBtn(Icons.facebook_outlined),
                const SizedBox(width: 8),
                _socialBtn(Icons.music_note_outlined),
                const SizedBox(width: 8),
                _socialBtn(Icons.chat_bubble_outline),
              ]);
            }
            return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    _socialBtn(Icons.camera_alt_outlined),
                    const SizedBox(width: 8),
                    _socialBtn(Icons.facebook_outlined),
                    const SizedBox(width: 8),
                    _socialBtn(Icons.music_note_outlined),
                    const SizedBox(width: 8),
                    _socialBtn(Icons.chat_bubble_outline),
                  ]),
                  const SizedBox(height: 10),
                  Wrap(spacing: 14, runSpacing: 6, children: [
                    _footerLink("Privacidad"),
                    _footerLink("Términos"),
                    _footerLink("Cookies"),
                  ]),
                  const SizedBox(height: 8),
                  const Text(
                      "© 2025 SmartTech Store · Todos los derechos reservados",
                      style: TextStyle(color: _textSec, fontSize: 10)),
                ]);
          }),
        ),
      ]),
    );
  }

  Widget _footerStat(String value, String label) => Expanded(
        child: Column(children: [
          Text(value,
              style: const TextStyle(
                  color: _accent,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: _textSec, fontSize: 10)),
        ]),
      );

  Widget _footerStatDivider() =>
      Container(width: 1, height: 30, color: _divider);

  Widget _colInfo() =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text("SMARTTECH STORE",
            style: TextStyle(
                color: _textSec,
                fontSize: 10,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        const Text(
            "Tu tienda de tecnología de confianza. Encontrarás los mejores productos al mejor precio con la asesoría de Nathalia, tu asistente IA.",
            style: TextStyle(color: _textSec, fontSize: 11, height: 1.6)),
        const SizedBox(height: 12),
        _infoRow(Icons.location_on_outlined, "Colombia · Envíos a todo el país"),
        const SizedBox(height: 6),
        _infoRow(Icons.mail_outline, "smart.tech6913@gmail.com"),
        const SizedBox(height: 6),
        _infoRow(Icons.phone_outlined, "+57 311 506 4196"),
      ]);

  Widget _infoRow(IconData icon, String text) => Row(children: [
        Icon(icon, color: _accent, size: 13),
        const SizedBox(width: 6),
        Flexible(
            child: Text(text,
                style: const TextStyle(color: _textSec, fontSize: 11))),
      ]);

  Widget _colNav() =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text("NAVEGACIÓN",
            style: TextStyle(
                color: _textSec,
                fontSize: 10,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        _navLink(Icons.devices_outlined, "Productos"),
        _navLink(Icons.favorite_border, "Favoritos"),
        _navLink(Icons.shopping_bag_outlined, "Carrito"),
        _navLink(Icons.person_outline, "Perfil"),
        _navLink(Icons.local_offer_outlined, "Ofertas", badge: "HOT"),
        _navLink(Icons.local_shipping_outlined, "Rastrear pedido"),
      ]);

  Widget _colInfo2() =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text("INFORMACIÓN",
            style: TextStyle(
                color: _textSec,
                fontSize: 10,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        _navLink(Icons.info_outline, "Sobre nosotros"),
        _navLink(Icons.shield_outlined, "Garantías"),
        _navLink(Icons.replay_outlined, "Devoluciones"),
        _navLink(Icons.lock_outline, "Privacidad"),
        _navLink(Icons.description_outlined, "Términos"),
        _navLink(Icons.help_outline, "Preguntas frecuentes"),
      ]);

  Widget _navLink(IconData icon, String label, {String? badge}) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          Icon(icon, color: _textSec, size: 13),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  color: Color(0xFFA8C4D8), fontSize: 12)),
          if (badge != null) ...[
            const SizedBox(width: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                      color: Colors.orange.withOpacity(0.35), width: 0.5)),
              child: Text(badge,
                  style: const TextStyle(
                      color: Colors.orange,
                      fontSize: 9,
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ]),
      );

  Widget _colNathalia() =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text("NATHALIA IA",
            style: TextStyle(
                color: _textSec,
                fontSize: 10,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF7C3AED).withOpacity(0.10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: const Color(0xFF7C3AED).withOpacity(0.28), width: 1),
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withOpacity(0.25),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: const Color(0xFFA78BFA).withOpacity(0.40),
                      width: 1),
                ),
                child: const Icon(Icons.auto_awesome,
                    color: Color(0xFFA78BFA), size: 16),
              ),
              const SizedBox(width: 8),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text("Nathalia",
                    style: TextStyle(
                        color: Color(0xFFA78BFA),
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
                Row(children: [
                  Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                          color: Color(0xFF34D399),
                          shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  const Text("En línea ahora",
                      style: TextStyle(
                          color: Color(0xFF34D399),
                          fontSize: 10,
                          fontWeight: FontWeight.w600)),
                ]),
              ]),
            ]),
            const SizedBox(height: 10),
            const Text(
                "Asistente de compras 24/7. Te ayudo a encontrar el producto perfecto y resuelvo todas tus dudas al instante.",
                style: TextStyle(
                    color: Color(0xFFC4B5FD), fontSize: 11, height: 1.5)),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => showNathaliaChat(context, widget.token),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withOpacity(0.20),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: const Color(0xFFA78BFA).withOpacity(0.35),
                      width: 1),
                ),
                child: const Text("Chatear con Nathalia ✦",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Color(0xFFA78BFA),
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ),
      ]);

  Widget _techPill(IconData icon, String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: _divider, width: 1)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: _accent.withOpacity(0.7), size: 13),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(
                  color: Color(0xFFA8C4D8),
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ]),
      );

  Widget _secItem(IconData icon, String label) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: const Color(0xFF34D399), size: 13),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(color: _textSec, fontSize: 10)),
      ]);

  Widget _footerLink(String label) =>
      Text(label, style: const TextStyle(color: _textSec, fontSize: 11));

  Widget _socialBtn(IconData icon) => Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
            color: _accent.withOpacity(0.07),
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: _accent.withOpacity(0.18), width: 1)),
        child: Icon(icon, color: _textSec, size: 15),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        elevation: 0,
        toolbarHeight: 72,
        titleSpacing: 20,
        title: Row(children: [
          GestureDetector(
            onTap: _scrollToFooter,
            child: AnimatedBuilder(
              animation: _logoPulse,
              builder: (_, child) =>
                  Transform.scale(scale: _logoPulse.value, child: child),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: _accent.withOpacity(0.30), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                        color: _accent.withOpacity(0.10),
                        blurRadius: 12,
                        spreadRadius: 1)
                  ],
                ),
                child: const Icon(Icons.memory, color: _accent, size: 24),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
            Text("SmartTech",
                style: TextStyle(
                    color: _textPri,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    letterSpacing: 1.0)),
            Text("STORE",
                style: TextStyle(
                    color: _accent,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                    letterSpacing: 4.0)),
          ]),
        ]),
        actions: [
          _navAction(
              icon: Icons.favorite_outline,
              tooltip: "Favoritos",
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          FavoritesScreen(token: widget.token)))),
          _navAction(
              icon: Icons.shopping_bag_outlined,
              tooltip: "Carrito",
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const CartScreen()))),
          // ── Foto de perfil ──
          _profileAvatar(),
          _navAction(
              icon: Icons.logout,
              tooltip: "Cerrar sesión",
              onTap: logout),
          const SizedBox(width: 12),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _divider),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: Stack(children: [
        Align(
          alignment: Alignment.bottomLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 20, bottom: 20),
            child: _CartBubbleFab(
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const CartScreen()))),
          ),
        ),
        Align(
          alignment: Alignment.bottomRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 20, bottom: 20),
            child: _NathaliaFab(
                onTap: () => showNathaliaChat(context, widget.token)),
          ),
        ),
        if (isAdmin)
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 20, bottom: 100),
              child: FloatingActionButton(
                heroTag: 'admin_fab',
                backgroundColor: _accent,
                elevation: 6,
                onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => AddProductScreen()))
                    .then((_) => loadProducts()),
                child: const Icon(Icons.add, color: _bg, size: 24),
              ),
            ),
          ),
      ]),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(children: [
          // ── Buscador ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
            child: Container(
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _divider, width: 1),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x22000000),
                      blurRadius: 8,
                      offset: Offset(0, 2))
                ],
              ),
              child: TextField(
                controller: searchController,
                onChanged: filterProducts,
                style: const TextStyle(
                    color: _textPri, fontSize: 13, letterSpacing: 0.2),
                decoration: InputDecoration(
                  hintText: "Buscar productos o categoría…",
                  hintStyle:
                      const TextStyle(color: _textSec, fontSize: 13),
                  prefixIcon:
                      const Icon(Icons.search, color: _textSec, size: 18),
                  suffixIcon: searchController.text.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            searchController.clear();
                            filterProducts('');
                          },
                          child: const Icon(Icons.close,
                              color: _textSec, size: 16))
                      : null,
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 13, horizontal: 4),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
            ),
          ),

          // ── Categorías + Ordenar ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: _categoryChips()),
                GestureDetector(
                  onTap: _showSortSheet,
                  child: Container(
                    margin: const EdgeInsets.only(right: 14),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: selectedSort != null
                          ? _accent.withOpacity(0.12)
                          : _surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: selectedSort != null
                              ? _accent.withOpacity(0.55)
                              : _divider,
                          width: selectedSort != null ? 1.5 : 1),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.sort_rounded,
                          color: selectedSort != null ? _accent : _textSec,
                          size: 16),
                      const SizedBox(width: 5),
                      Text("Ordenar",
                          style: TextStyle(
                              color: selectedSort != null
                                  ? _accent
                                  : _textSec,
                              fontSize: 12,
                              fontWeight: selectedSort != null
                                  ? FontWeight.w700
                                  : FontWeight.w500)),
                    ]),
                  ),
                ),
              ],
            ),
          ),

          // ── Contador + filtros activos ──────────────────────────────────
          if (!isLoading)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 0),
              child: Row(children: [
                Text(
                  "${filteredProducts.length} producto${filteredProducts.length == 1 ? '' : 's'}",
                  style: const TextStyle(
                      color: _textSec, fontSize: 11, letterSpacing: 0.3),
                ),
                if (selectedCategory != null) ...[
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => selectCategory(null),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: _accent.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: _accent.withOpacity(0.25), width: 0.5),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text(selectedCategory!,
                            style: const TextStyle(
                                color: _accent,
                                fontSize: 10,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(width: 4),
                        const Icon(Icons.close, color: _accent, size: 10),
                      ]),
                    ),
                  ),
                ],
                if (selectedSort != null) ...[
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () {
                      setState(() => selectedSort = null);
                      _applyFilters();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: _accent.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: _accent.withOpacity(0.25), width: 0.5),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.sort_rounded,
                            color: _accent, size: 10),
                        const SizedBox(width: 4),
                        const Icon(Icons.close, color: _accent, size: 10),
                      ]),
                    ),
                  ),
                ],
              ]),
            ),

          const SizedBox(height: 6),

          // ── Grid ────────────────────────────────────────────────────────
          isLoading
              ? SizedBox(height: 500, child: _skeleton())
              : filteredProducts.isEmpty
                  ? const SizedBox(
                      height: 200,
                      child: Center(
                        child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.search_off,
                                  color: _textSec, size: 44),
                              SizedBox(height: 10),
                              Text("Sin resultados",
                                  style: TextStyle(
                                      color: _textSec,
                                      fontSize: 14,
                                      letterSpacing: 0.4)),
                            ]),
                      ),
                    )
                  : FadeTransition(
                      opacity: _fadeAnimation,
                      child: LayoutBuilder(builder: (context, constraints) {
                        final columns = _getColumns(constraints.maxWidth);
                        final ratio = _getRatio(constraints.maxWidth);
                        final rows =
                            (filteredProducts.length / columns).ceil();
                        final itemH =
                            constraints.maxWidth / columns / ratio;
                        final gridH =
                            rows * itemH + (rows - 1) * 12 + 18.0;
                        return SizedBox(
                          height: gridH,
                          child: GridView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
                            itemCount: filteredProducts.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: columns,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                    childAspectRatio: ratio),
                            itemBuilder: (context, index) =>
                                _productCard(filteredProducts[index], index),
                          ),
                        );
                      }),
                    ),

          _buildFooter(),
        ]),
      ),
    );
  }
}

// ── Cart Bubble FAB ───────────────────────────────────────────────────────────
class _CartBubbleFab extends StatefulWidget {
  final VoidCallback onTap;
  const _CartBubbleFab({required this.onTap});
  @override
  State<_CartBubbleFab> createState() => _CartBubbleFabState();
}

class _CartBubbleFabState extends State<_CartBubbleFab>
    with SingleTickerProviderStateMixin {
  static const _bubbleColor = Color(0xFFB0C8D8);
  static const _bg = Color(0xFF0D1F33);
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.88, end: 1.0)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, child) =>
          Transform.scale(scale: _pulse.value, child: child),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 66,
          height: 66,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _bg,
            border:
                Border.all(color: _bubbleColor.withOpacity(0.45), width: 1.5),
            boxShadow: [
              BoxShadow(
                  color: _bubbleColor.withOpacity(0.12),
                  blurRadius: 12,
                  spreadRadius: 1),
              BoxShadow(
                  color: Colors.black.withOpacity(0.30),
                  blurRadius: 8,
                  offset: const Offset(0, 4)),
            ],
          ),
          child: const Icon(Icons.shopping_cart_outlined,
              color: _bubbleColor, size: 28),
        ),
      ),
    );
  }
}

// ── Nathalia FAB ─────────────────────────────────────────────────────────────
class _NathaliaFab extends StatefulWidget {
  final VoidCallback onTap;
  const _NathaliaFab({required this.onTap});
  @override
  State<_NathaliaFab> createState() => _NathaliaFabState();
}

class _NathaliaFabState extends State<_NathaliaFab>
    with SingleTickerProviderStateMixin {
  static const _purple = Color(0xFF7C3AED);
  static const _purpleLight = Color(0xFFA78BFA);
  static const _purpleDark = Color(0xFF4C1D95);
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2200))
      ..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.92, end: 1.0)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      AnimatedOpacity(
        opacity: _hovered ? 1.0 : 0.75,
        duration: const Duration(milliseconds: 200),
        child: Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _purpleDark.withOpacity(0.85),
            borderRadius: BorderRadius.circular(10),
            border:
                Border.all(color: _purpleLight.withOpacity(0.35), width: 1),
            boxShadow: [
              BoxShadow(color: _purple.withOpacity(0.25), blurRadius: 8)
            ],
          ),
          child: const Text("Nathalia",
              style: TextStyle(
                  color: Color(0xFFEDE9FE),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5)),
        ),
      ),
      MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedBuilder(
            animation: _pulse,
            builder: (_, child) =>
                Transform.scale(scale: _pulse.value, child: child),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 66,
              height: 66,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                    colors: [
                      _hovered ? const Color(0xFF8B5CF6) : _purple,
                      _purpleDark
                    ],
                    center: Alignment.topCenter,
                    radius: 1.2),
                border: Border.all(
                    color:
                        _purpleLight.withOpacity(_hovered ? 0.70 : 0.45),
                    width: 2),
                boxShadow: [
                  BoxShadow(
                      color: _purple.withOpacity(_hovered ? 0.55 : 0.35),
                      blurRadius: _hovered ? 24 : 16,
                      spreadRadius: _hovered ? 3 : 1),
                  BoxShadow(
                      color: _purple.withOpacity(0.15),
                      blurRadius: 40,
                      spreadRadius: 6),
                ],
              ),
              child: const Icon(Icons.auto_awesome,
                  color: Color(0xFFEDE9FE), size: 28),
            ),
          ),
        ),
      ),
    ]);
  }
}

// ── Category Chip ─────────────────────────────────────────────────────────────
class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  static const _accent = Color(0xFF00D4FF);
  static const _surface = Color(0xFF0D1F33);
  static const _divider = Color(0xFF1A2E44);
  static const _textSec = Color(0xFF7A9BB5);

  const _CategoryChip(
      {required this.label,
      required this.isSelected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? _accent.withOpacity(0.15) : _surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
              color: isSelected
                  ? _accent.withOpacity(0.60)
                  : _divider,
              width: isSelected ? 1.5 : 1),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: _accent.withOpacity(0.20),
                      blurRadius: 8,
                      spreadRadius: 1)
                ]
              : [],
        ),
        child: Text(label,
            style: TextStyle(
                color: isSelected ? _accent : _textSec,
                fontSize: 13,
                fontWeight: isSelected
                    ? FontWeight.w700
                    : FontWeight.w500,
                letterSpacing: 0.3)),
      ),
    );
  }
}

// ── Hover Card ────────────────────────────────────────────────────────────────
class _HoverCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _HoverCard({required this.child, required this.onTap});
  @override
  State<_HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<_HoverCard> {
  bool _hovered = false;
  static const _card = Color(0xFF111E2E);
  static const _accent = Color(0xFF00D4FF);
  static const _divider = Color(0xFF1A2E44);

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: _hovered ? const Color(0xFF152234) : _card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: _hovered ? _accent.withOpacity(0.55) : _divider,
                width: _hovered ? 1.5 : 1),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                        color: _accent.withOpacity(0.18),
                        blurRadius: 20,
                        spreadRadius: 2),
                    BoxShadow(
                        color: _accent.withOpacity(0.08),
                        blurRadius: 40,
                        spreadRadius: 6),
                  ]
                : [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.28),
                        blurRadius: 14,
                        offset: const Offset(0, 6))
                  ],
          ),
          child: AnimatedScale(
            scale: _hovered ? 1.03 : 1.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

// ── Skeleton Card ─────────────────────────────────────────────────────────────
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
        vsync: this, duration: const Duration(milliseconds: 1200));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
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
              const Color(0xFF0D1F33), const Color(0xFF162030), _anim.value),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF1A2E44), width: 1),
        ),
        child: Column(children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Color.lerp(const Color(0xFF0A1929),
                    const Color(0xFF0F2235), _anim.value),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(9),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                height: 8,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Color.lerp(const Color(0xFF1A2E44),
                      const Color(0xFF213547), _anim.value),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                height: 8,
                width: 48,
                decoration: BoxDecoration(
                  color: Color.lerp(const Color(0xFF0D3045),
                      const Color(0xFF0F4060), _anim.value),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}