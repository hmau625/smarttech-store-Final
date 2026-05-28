import 'package:flutter/material.dart';
import '../services/favorite_service.dart';

class FavoritesScreen extends StatefulWidget {
  final String token;

  const FavoritesScreen({super.key, required this.token});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final FavoriteService favService = FavoriteService();

  List<dynamic> favorites = [];

  // 🎨 PALETA PRO
  static const _bg = Color(0xFF060D17);
  static const _card = Color(0xFF111E2E);
  static const _accent = Color(0xFF00D4FF);
  static const _textPri = Color(0xFFEFF6FF);
  static const _textSec = Color(0xFF7A9BB5);
  static const _divider = Color(0xFF1A2E44);

  @override
  void initState() {
    super.initState();
    loadFavorites();
  }

  Future<void> loadFavorites() async {
    final data = await favService.getFavorites(widget.token);

    setState(() {
      favorites = data;
    });
  }

  void showInfo(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFF0D2B1A),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,

      appBar: AppBar(
        title: const Text(
          "Mis Favoritos",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      body: favorites.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border,
                      size: 60, color: Colors.white38),
                  SizedBox(height: 10),
                  Text(
                    "No tienes favoritos",
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                final fav = favorites[index];
                final product = fav['product'];

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _divider),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Row(
                    children: [

                      // 🖼️ IMAGEN PRO
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F2A44),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: product['image'] != null
                              ? Image.network(
                                  product['image'],
                                  fit: BoxFit.contain,
                                )
                              : const Icon(Icons.image,
                                  color: Colors.white38),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // 📦 INFO
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            Text(
                              product['name'] ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _textPri,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),

                            const SizedBox(height: 4),

                            Text(
                              product['brand'] ?? '',
                              style: const TextStyle(
                                color: _textSec,
                                fontSize: 11,
                              ),
                            ),

                            Text(
                              product['category'] ?? '',
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 10,
                              ),
                            ),

                            const SizedBox(height: 6),

                            Text(
                              "\$${product['price']}",
                              style: const TextStyle(
                                color: _accent,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ❤️ BOTÓN FAVORITO PRO
                      GestureDetector(
                        onTap: () async {
                          final productId = fav['product_id'];

                          await favService.removeFavorite(
                              widget.token, productId);

                          showInfo("Eliminado de favoritos");

                          loadFavorites();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.favorite,
                            color: Colors.redAccent,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}