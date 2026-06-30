import 'package:smarttech_store/config/api_config.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// DEPENDENCIA REQUERIDA en pubspec.yaml:
//   shared_preferences: ^2.2.3
//
// Llama esto desde cualquier pantalla para abrir el chat flotante:
//   showNathaliaChat(context, token);
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

void showNathaliaChat(BuildContext context, String token, {String? initialMessage}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(0.5),
    builder: (_) => _NathaliaChatSheet(token: token, initialMessage: initialMessage),
  );
}

class _NathaliaChatSheet extends StatefulWidget {
  final String token;
  final String? initialMessage;
  const _NathaliaChatSheet({required this.token, this.initialMessage});

  @override
  State<_NathaliaChatSheet> createState() => _NathaliaChatSheetState();
}

class _NathaliaChatSheetState extends State<_NathaliaChatSheet> {
  final _controller = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _loading = false;

  static const _bg      = Color(0xFF060D17);
  static const _surface = Color(0xFF0D1F33);
  static const _card    = Color(0xFF111E2E);
  static const _accent  = Color(0xFF00D4FF);
  static const _purple  = Color(0xFF7C3AED);
  static const _purpleL = Color(0xFFA78BFA);
  static const _purpleD = Color(0xFF4C1D95);
  static const _textPri = Color(0xFFEFF6FF);
  static const _textSec = Color(0xFF7A9BB5);
  static const _divider = Color(0xFF1A2E44);

  // Clave de SharedPreferences para el historial
  // Si quieres historial separado por usuario, usa: 'chat_history_${widget.token}'
  static const _historyKey = 'chat_history';
  static const _maxSavedMessages = 50;

  final String _baseUrl = ApiConfig.baseUrl;

  static const _welcomeMessage = {
    "role": "assistant",
    "content": "Â¡Hola! Soy Nathalia, tu asistente de SmartTech ðŸ›ï¸\n\n"
        "Puedo ayudarte a:\n"
        "ðŸ”¹ Recomendar segÃºn tu presupuesto\n"
        "ðŸ”¹ Comparar componentes\n"
        "ðŸ”¹ Armar un PC completo\n\n"
        "Â¿QuÃ© necesitas?",
  };

  // â”€â”€ Historial persistente â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_historyKey);
      if (saved != null && saved.isNotEmpty) {
        final List decoded = jsonDecode(saved);
        if (decoded.isNotEmpty) {
          setState(() {
            _messages.clear();
            _messages.addAll(
              decoded.map((e) => Map<String, String>.from(e)).toList(),
            );
          });
          _scrollToBottom();
          return;
        }
      }
    } catch (_) {
      // Si falla la carga, se queda con el mensaje de bienvenida
    }
  }

  Future<void> _saveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final toSave = _messages.length > _maxSavedMessages
          ? _messages.sublist(_messages.length - _maxSavedMessages)
          : List<Map<String, String>>.from(_messages);
      await prefs.setString(_historyKey, jsonEncode(toSave));
    } catch (_) {
      // Fallo silencioso, no crÃ­tico
    }
  }

  Future<void> _clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_historyKey);
    } catch (_) {}
    setState(() {
      _messages.clear();
      _messages.add(Map<String, String>.from(_welcomeMessage));
    });
  }

  // â”€â”€ Lifecycle â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  @override
  void initState() {
    super.initState();
    // Mensaje de bienvenida por defecto
    _messages.add(Map<String, String>.from(_welcomeMessage));
    // Intenta cargar historial guardado (lo reemplaza si existe)
    _loadHistory();
    // Mensaje inicial automÃ¡tico (ej: desde product detail)
    if (widget.initialMessage != null && widget.initialMessage!.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) _send(widget.initialMessage);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // â”€â”€ Enviar mensaje â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<void> _send([String? override]) async {
    final text = override ?? _controller.text.trim();
    if (text.isEmpty || _loading) return;

    setState(() {
      _messages.add({"role": "user", "content": text});
      _loading = true;
    });
    if (override == null) _controller.clear();
    _scrollToBottom();

    try {
      final history = _messages
          .where((m) => m["role"] == "user" || m["role"] == "assistant")
          .toList();
      final recent = history.length > 10 ? history.sublist(history.length - 10) : history;

      final res = await http.post(
        Uri.parse("$_baseUrl/ai/chat"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${widget.token}",
        },
        body: jsonEncode({
          "message": text,
          "history": recent.sublist(0, recent.length - 1),
        }),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _processResponse(data["response"]);
      } else {
        setState(() => _messages.add({
          "role": "assistant",
          "content": "Ups, tuve un problema. Intenta de nuevo ðŸ˜…",
        }));
      }
    } catch (e) {
      setState(() => _messages.add({
        "role": "assistant",
        "content": "Error de conexiÃ³n ðŸ”Œ",
      }));
    }

    setState(() => _loading = false);
    _scrollToBottom();
    await _saveHistory(); // Guarda despuÃ©s de cada intercambio
  }

  // â”€â”€ Agregar al carrito â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<void> _addToCart(int productId) async {
    try {
      final res = await http.post(
        Uri.parse("$_baseUrl/cart/add?product_id=$productId&token=${widget.token}"),
      );
      if (res.statusCode == 200) {
        setState(() => _messages.add({
          "role": "assistant",
          "content": "Listo, producto #$productId agregado al carrito ðŸ›’",
        }));
      } else {
        setState(() => _messages.add({
          "role": "assistant",
          "content": "No pude agregar el producto #$productId al carrito ðŸ˜•",
        }));
      }
    } catch (_) {
      setState(() => _messages.add({
        "role": "assistant",
        "content": "Error de conexiÃ³n al agregar ðŸ”Œ",
      }));
    }
    _scrollToBottom();
    await _saveHistory();
  }

  // â”€â”€ Procesar respuesta â€” FIX: allMatches para mÃºltiples CART_ADD â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  void _processResponse(String response) {
    // allMatches captura TODOS los CART_ADD:X, no solo el primero
    final cartMatches = RegExp(r'CART_ADD:(\d+)').allMatches(response);

    // Limpia TODOS los CART_ADD del texto visible
    final cleanText = response.replaceAll(RegExp(r'CART_ADD:\d+\s*'), '').trim();

    setState(() {
      _messages.add({
        "role": "assistant",
        "content": cleanText.isNotEmpty ? cleanText : "Agregando al carrito...",
      });
    });

    // Itera y agrega cada producto encontrado
    for (final match in cartMatches) {
      final productId = int.parse(match.group(1)!);
      _addToCart(productId);
    }
  }

  // â”€â”€ Extraer productos con [ID:X] para mostrar botones â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  List<MapEntry<String, int>> _extractProducts(String text) {
    final matches = RegExp(r'([^.\n\[]+?)\s*\[ID:(\d+)\]').allMatches(text);
    return matches.map((m) => MapEntry(m.group(1)!.trim(), int.parse(m.group(2)!))).toList();
  }

  // â”€â”€ Chip de sugerencia â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _chip(String label, String msg) {
    return GestureDetector(
      onTap: () => _send(msg),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: _purple.withOpacity(0.12),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _purple.withOpacity(0.35)),
        ),
        child: Text(label,
            style: const TextStyle(color: _purpleL, fontSize: 11, fontWeight: FontWeight.w600)),
      ),
    );
  }

  // â”€â”€ Burbuja de mensaje â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _bubble(Map<String, String> msg) {
    final isUser = msg["role"] == "user";
    final content = msg["content"] ?? "";
    final products = !isUser ? _extractProducts(content) : <MapEntry<String, int>>[];
    final cleanText = content.replaceAll(RegExp(r'\s*\[ID:\d+\]'), '');

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser)
            Container(
              width: 30, height: 30,
              margin: const EdgeInsets.only(right: 8, top: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(colors: [_purple, _purpleD]),
                border: Border.all(color: _purpleL.withOpacity(0.5), width: 1.5),
              ),
              child: const Icon(Icons.auto_awesome, color: Color(0xFFEDE9FE), size: 14),
            ),
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isUser ? _accent.withOpacity(0.15) : _card,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(14),
                      topRight: const Radius.circular(14),
                      bottomLeft: Radius.circular(isUser ? 14 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 14),
                    ),
                    border: Border.all(
                      color: isUser ? _accent.withOpacity(0.30) : _divider,
                    ),
                  ),
                  child: Text(
                    cleanText,
                    style: const TextStyle(color: _textPri, fontSize: 13, height: 1.45),
                  ),
                ),
                if (products.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6, runSpacing: 6,
                    children: products.map((p) => GestureDetector(
                      onTap: () => _addToCart(p.value),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _accent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _accent.withOpacity(0.35)),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.add_shopping_cart_rounded, color: _accent, size: 14),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              p.key.length > 25 ? "${p.key.substring(0, 25)}..." : p.key,
                              style: const TextStyle(
                                  color: _accent, fontSize: 11, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ]),
                      ),
                    )).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // â”€â”€ Typing indicator â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _typing() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30, height: 30,
            margin: const EdgeInsets.only(right: 8, top: 2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: [_purple, _purpleD]),
              border: Border.all(color: _purpleL.withOpacity(0.5), width: 1.5),
            ),
            child: const Icon(Icons.auto_awesome, color: Color(0xFFEDE9FE), size: 14),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14), topRight: Radius.circular(14),
                bottomRight: Radius.circular(14), bottomLeft: Radius.circular(4),
              ),
              border: Border.all(color: _divider),
            ),
            child: SizedBox(
              width: 40,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(3, (i) => _animDot(i * 200)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _animDot(int delayMs) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      builder: (_, v, __) => Container(
        width: 7, height: 7,
        decoration: BoxDecoration(
          color: _purpleL.withOpacity(v),
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  // â”€â”€ Build â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  @override
  Widget build(BuildContext context) {
    final showSuggestions = _messages.length <= 1 && !_loading;

    return DraggableScrollableSheet(
      initialChildSize: 0.70,
      minChildSize: 0.40,
      maxChildSize: 0.92,
      builder: (_, scrollCtrl) {
        return Container(
          decoration: const BoxDecoration(
            color: _bg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // â”€â”€ Handle + Header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  border: Border(bottom: BorderSide(color: _divider)),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 40, height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                          color: _divider, borderRadius: BorderRadius.circular(2)),
                    ),
                    Row(children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(colors: [_purple, _purpleD]),
                          border: Border.all(color: _purpleL.withOpacity(0.5), width: 2),
                          boxShadow: [BoxShadow(color: _purple.withOpacity(0.35), blurRadius: 10)],
                        ),
                        child: const Icon(Icons.auto_awesome, color: Color(0xFFEDE9FE), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Nathalia",
                                style: TextStyle(
                                    color: _textPri, fontWeight: FontWeight.w800, fontSize: 17)),
                            Text(
                              _loading ? "Escribiendo..." : "Asistente SmartTech",
                              style: TextStyle(
                                  color: _loading ? _purpleL : _textSec,
                                  fontSize: 11, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                      // BotÃ³n limpiar historial
                      GestureDetector(
                        onTap: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              backgroundColor: _surface,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              title: const Text("Limpiar historial",
                                  style: TextStyle(color: _textPri, fontSize: 16)),
                              content: const Text(
                                "Â¿Borrar toda la conversaciÃ³n?",
                                style: TextStyle(color: _textSec, fontSize: 14),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text("Cancelar",
                                      style: TextStyle(color: _textSec)),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text("Limpiar",
                                      style: TextStyle(color: Colors.redAccent)),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) _clearHistory();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: _divider.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.delete_outline_rounded,
                              color: _textSec, size: 18),
                        ),
                      ),
                      // BotÃ³n cerrar
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _divider.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.close_rounded, color: _textSec, size: 18),
                        ),
                      ),
                    ]),
                  ],
                ),
              ),

              // â”€â”€ Messages â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              Expanded(
                child: ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                  itemCount: _messages.length + (_loading ? 1 : 0),
                  itemBuilder: (_, i) {
                    if (i == _messages.length && _loading) return _typing();
                    return _bubble(_messages[i]);
                  },
                ),
              ),

              // â”€â”€ Suggestions â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              if (showSuggestions)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  child: Row(children: [
                    _chip("ðŸ’° PC Gamer \$3M", "Quiero armar un PC gamer con presupuesto de 3 millones"),
                    const SizedBox(width: 6),
                    _chip("ðŸ”„ Comparar GPUs", "Compara las tarjetas grÃ¡ficas disponibles"),
                    const SizedBox(width: 6),
                    _chip("ðŸ’» PC programar", "PC para programaciÃ³n, quÃ© me recomiendas?"),
                    const SizedBox(width: 6),
                    _chip("ðŸŽ® Mejor GPU", "CuÃ¡l es la mejor GPU que tienen?"),
                  ]),
                ),

              // â”€â”€ Input â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              Container(
                padding: EdgeInsets.fromLTRB(
                    12, 8, 12, MediaQuery.of(context).padding.bottom + 12),
                decoration: BoxDecoration(
                  color: _surface,
                  border: Border(top: BorderSide(color: _divider)),
                ),
                child: Row(children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF162638),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: _divider),
                      ),
                      child: TextField(
                        controller: _controller,
                        style: const TextStyle(color: _textPri, fontSize: 13),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                        decoration: InputDecoration(
                          hintText: "PregÃºntale a Nathalia...",
                          hintStyle: TextStyle(
                              color: _textSec.withOpacity(0.5), fontSize: 12),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _loading ? null : () => _send(),
                    child: Container(
                      width: 42, height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: _loading
                              ? [_purple.withOpacity(0.3), _purpleD.withOpacity(0.2)]
                              : [_purple, _purpleD],
                        ),
                        boxShadow: _loading
                            ? []
                            : [BoxShadow(color: _purple.withOpacity(0.4), blurRadius: 10)],
                      ),
                      child: Icon(
                        _loading
                            ? Icons.hourglass_top_rounded
                            : Icons.send_rounded,
                        color: const Color(0xFFEDE9FE), size: 18,
                      ),
                    ),
                  ),
                ]),
              ),
            ],
          ),
        );
      },
    );
  }
}