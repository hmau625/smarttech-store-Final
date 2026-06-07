import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import '../models/product.dart';
import '../services/api_service.dart';

// ── AÑADIDO: formatea mientras escribes "10000" → "10.000" ───────────────────
class _CopInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return newValue.copyWith(text: '');
    final formatted = digits.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
// ─────────────────────────────────────────────────────────────────────────────

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen>
    with SingleTickerProviderStateMixin {
  final ApiService api = ApiService();

  static const _bg      = Color(0xFF060D17);
  static const _surface = Color(0xFF0D1F33);
  static const _card    = Color(0xFF111E2E);
  static const _accent  = Color(0xFF00D4FF);
  static const _textPri = Color(0xFFEFF6FF);
  static const _textSec = Color(0xFF7A9BB5);
  static const _divider = Color(0xFF1A2E44);
  static const _error   = Color(0xFFFF4D6A);

  final nameController  = TextEditingController();
  final brandController = TextEditingController();
  final priceController = TextEditingController();
  final stockController = TextEditingController();
  final Map<String, TextEditingController> dynamicSpecsControllers = {};

  String? selectedCategory;
  bool _isSaving     = false;
  bool _isUploading  = false;

  String?       _imageUrl;
  String?       _imageFileName;

  late AnimationController _fadeCtrl;
  late Animation<double>   _fadeAnim;

  final List<Map<String, dynamic>> categories = [
    {"label": "CPU",          "icon": Icons.memory_rounded},
    {"label": "GPU",          "icon": Icons.videogame_asset_rounded},
    {"label": "RAM",          "icon": Icons.sd_card_rounded},
    {"label": "SSD",          "icon": Icons.storage_rounded},
    {"label": "Motherboard",  "icon": Icons.developer_board_rounded},
    {"label": "Power Supply", "icon": Icons.bolt_rounded},
    {"label": "Case",         "icon": Icons.computer_rounded},
    {"label": "Cooling",      "icon": Icons.wind_power_rounded},
    {"label": "Prebuilt PC",  "icon": Icons.desktop_windows_rounded},
  ];

  final Map<String, List<Map<String, dynamic>>> categorySpecs = {
    "CPU":          [{"label": "Cores",             "icon": Icons.grain_rounded},
                     {"label": "Threads",            "icon": Icons.linear_scale_rounded},
                     {"label": "Frequency (GHz)",    "icon": Icons.speed_rounded}],
    "GPU":          [{"label": "VRAM (GB)",          "icon": Icons.grain_rounded},
                     {"label": "Chipset",            "icon": Icons.memory_rounded}],
    "RAM":          [{"label": "Size (GB)",          "icon": Icons.sd_card_rounded},
                     {"label": "Speed (MHz)",        "icon": Icons.speed_rounded}],
    "SSD":          [{"label": "Capacity (GB)",      "icon": Icons.storage_rounded},
                     {"label": "Type (NVMe/SATA)",   "icon": Icons.compare_arrows_rounded}],
    "Motherboard":  [{"label": "Socket",             "icon": Icons.hub_rounded},
                     {"label": "Chipset",            "icon": Icons.memory_rounded},
                     {"label": "Form Factor",        "icon": Icons.grid_view_rounded}],
    "Power Supply": [{"label": "Wattage",            "icon": Icons.bolt_rounded},
                     {"label": "Certification",      "icon": Icons.verified_rounded}],
    "Case":         [{"label": "Form Factor Support","icon": Icons.grid_view_rounded}],
    "Cooling":      [{"label": "Type (Air/Liquid)",  "icon": Icons.ac_unit_rounded},
                     {"label": "Fan Size",           "icon": Icons.rotate_right_rounded}],
    "Prebuilt PC":  [{"label": "CPU",                "icon": Icons.memory_rounded},
                     {"label": "GPU",                "icon": Icons.videogame_asset_rounded},
                     {"label": "RAM",                "icon": Icons.sd_card_rounded},
                     {"label": "Storage",            "icon": Icons.storage_rounded}],
  };

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    nameController.dispose();
    brandController.dispose();
    priceController.dispose();
    stockController.dispose();
    for (final c in dynamicSpecsControllers.values) c.dispose();
    super.dispose();
  }

  void _onCategoryChanged(String cat) {
    setState(() {
      selectedCategory = cat;
      dynamicSpecsControllers.clear();
      for (final spec in categorySpecs[cat] ?? []) {
        dynamicSpecsControllers[spec['label']!] = TextEditingController();
      }
    });
  }

  Future<void> _pickAndUploadImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.bytes == null) {
      _showError("No se pudo leer el archivo");
      return;
    }

    setState(() => _isUploading = true);

    final url = await api.uploadProductImage(file.bytes!, file.name);

    setState(() {
      _isUploading  = false;
      _imageUrl     = url;
      _imageFileName = file.name;
    });

    if (url == null) {
      _showError("Error al subir la imagen, intenta de nuevo");
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.error_outline_rounded, color: _error, size: 16),
        const SizedBox(width: 8),
        Expanded(child: Text(msg,
            style: const TextStyle(color: _textPri, fontSize: 13))),
      ]),
      backgroundColor: _surface,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: _error.withOpacity(0.35), width: 1),
      ),
      duration: const Duration(seconds: 3),
    ));
  }

  void _showSuccess() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: const [
        Icon(Icons.check_circle_outline_rounded, color: _accent, size: 16),
        SizedBox(width: 8),
        Text("Producto guardado exitosamente",
            style: TextStyle(color: _textPri, fontSize: 13)),
      ]),
      backgroundColor: _surface,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: _accent.withOpacity(0.35), width: 1),
      ),
      duration: const Duration(seconds: 2),
    ));
  }

  Future<void> _saveProduct() async {
    if (nameController.text.isEmpty ||
        brandController.text.isEmpty ||
        selectedCategory == null ||
        priceController.text.isEmpty ||
        stockController.text.isEmpty) {
      _showError("Completa todos los campos obligatorios");
      return;
    }
    if (_imageUrl == null) {
      _showError("Selecciona una imagen para el producto");
      return;
    }

    // AÑADIDO: quita los puntos para parsear
    final price = double.tryParse(priceController.text.replaceAll('.', ''));
    final stock = int.tryParse(stockController.text);
    if (price == null || price <= 0) { _showError("Precio inválido"); return; }
    if (stock == null || stock <= 0)  { _showError("Stock inválido");  return; }

    final specs = <String, dynamic>{};
    dynamicSpecsControllers.forEach((k, c) {
      if (c.text.isNotEmpty) specs[k] = c.text;
    });

    setState(() => _isSaving = true);

    final product = Product(
      name:     nameController.text,
      brand:    brandController.text,
      category: selectedCategory!,
      price:    price,
      stock:    stock,
      image:    _imageUrl!,
      specs:    specs.isNotEmpty ? specs : null,
    );

    await api.createProduct(product);
    if (!mounted) return;
    setState(() => _isSaving = false);
    _showSuccess();
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) Navigator.pop(context);
  }

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(children: [
      Container(width: 3, height: 14,
          decoration: BoxDecoration(
              color: _accent, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 8),
      Text(text, style: const TextStyle(
          color: _textSec, fontSize: 11,
          fontWeight: FontWeight.w700, letterSpacing: 1.2)),
    ]),
  );

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? hint,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _divider, width: 1),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        style: const TextStyle(color: _textPri, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          hintStyle: TextStyle(color: _textSec.withOpacity(0.5), fontSize: 13),
          labelStyle: const TextStyle(color: _textSec, fontSize: 13),
          prefixIcon: Icon(icon, color: _accent.withOpacity(0.7), size: 18),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          floatingLabelBehavior: FloatingLabelBehavior.never,
        ),
      ),
    );
  }

  Widget _categoryChip(Map<String, dynamic> cat) {
    final selected = selectedCategory == cat['label'];
    return GestureDetector(
      onTap: () => _onCategoryChanged(cat['label']),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? _accent.withOpacity(0.15) : _bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? _accent.withOpacity(0.6) : _divider,
            width: selected ? 1.5 : 1,
          ),
          boxShadow: selected
              ? [BoxShadow(color: _accent.withOpacity(0.12),
                  blurRadius: 10, spreadRadius: 1)]
              : [],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(cat['icon'] as IconData,
              size: 14, color: selected ? _accent : _textSec),
          const SizedBox(width: 6),
          Text(cat['label'] as String,
              style: TextStyle(
                  color: selected ? _accent : _textSec,
                  fontSize: 12,
                  fontWeight:
                      selected ? FontWeight.w700 : FontWeight.w500)),
        ]),
      ),
    );
  }

  Widget _imagePicker() {
    return GestureDetector(
      onTap: _isUploading ? null : _pickAndUploadImage,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: _imageUrl != null ? 180 : 110,
        decoration: BoxDecoration(
          color: _bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _imageUrl != null
                ? _accent.withOpacity(0.45)
                : _divider,
            width: _imageUrl != null ? 1.5 : 1,
          ),
        ),
        child: _isUploading
            ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const SizedBox(
                  width: 28, height: 28,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: _accent),
                ),
                const SizedBox(height: 10),
                Text("Subiendo imagen...",
                    style: TextStyle(
                        color: _textSec.withOpacity(0.8), fontSize: 12)),
              ])
            : _imageUrl != null
                ? Stack(children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(13),
                      child: Image.network(
                        ApiService.resolveImage(_imageUrl),
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(Icons.broken_image_outlined,
                              color: _textSec, size: 32),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0, left: 0, right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.75),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: const BorderRadius.only(
                            bottomLeft:  Radius.circular(13),
                            bottomRight: Radius.circular(13),
                          ),
                        ),
                        child: Row(children: [
                          Icon(Icons.check_circle_rounded,
                              color: _accent, size: 14),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _imageFileName ?? "Imagen subida",
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: _textPri,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _accent.withOpacity(0.20),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: _accent.withOpacity(0.45), width: 1),
                            ),
                            child: const Text("Cambiar",
                                style: TextStyle(
                                    color: _accent,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ]),
                      ),
                    ),
                  ])
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _accent.withOpacity(0.08),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: _accent.withOpacity(0.25), width: 1),
                        ),
                        child: const Icon(Icons.add_photo_alternate_rounded,
                            color: _accent, size: 24),
                      ),
                      const SizedBox(height: 10),
                      const Text("Seleccionar imagen",
                          style: TextStyle(
                              color: _textPri,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text("PNG, JPG, WEBP",
                          style: TextStyle(
                              color: _textSec.withOpacity(0.7),
                              fontSize: 11)),
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
          child: _AppBackButton(onTap: () => Navigator.pop(context)),
        ),
        title: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _accent.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _accent.withOpacity(0.25), width: 1),
            ),
            child: const Icon(Icons.add_box_rounded, color: _accent, size: 18),
          ),
          const SizedBox(width: 10),
          ShaderMask(
            shaderCallback: (b) => const LinearGradient(
              colors: [_accent, Color(0xFF7AE8FF)],
            ).createShader(b),
            child: const Text("Nuevo Producto",
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    letterSpacing: 0.3)),
          ),
        ]),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _divider),
        ),
      ),

      body: FadeTransition(
        opacity: _fadeAnim,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              _sectionLabel("INFORMACIÓN BÁSICA"),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _divider, width: 1),
                  boxShadow: [BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: Column(children: [
                  _field(controller: nameController,
                      label: "Nombre del producto",
                      icon: Icons.devices_rounded),
                  const SizedBox(height: 10),
                  _field(controller: brandController,
                      label: "Marca",
                      icon: Icons.business_rounded),
                ]),
              ),

              const SizedBox(height: 20),

              _sectionLabel("IMAGEN DEL PRODUCTO"),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: _imageUrl != null
                        ? _accent.withOpacity(0.25)
                        : _divider,
                    width: 1,
                  ),
                  boxShadow: [BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: _imagePicker(),
              ),

              const SizedBox(height: 20),

              _sectionLabel("PRECIO Y STOCK"),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _divider, width: 1),
                  boxShadow: [BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: Row(children: [
                  Expanded(child: _field(
                      controller: priceController,
                      label: "Precio",
                      icon: Icons.attach_money_rounded,
                      keyboardType: TextInputType.number,
                      inputFormatters: [_CopInputFormatter()])), // ← AÑADIDO
                  const SizedBox(width: 10),
                  Expanded(child: _field(
                      controller: stockController,
                      label: "Stock",
                      icon: Icons.inventory_2_rounded,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly])),
                ]),
              ),

              const SizedBox(height: 20),

              _sectionLabel("CATEGORÍA"),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _divider, width: 1),
                  boxShadow: [BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: Wrap(
                  spacing: 8, runSpacing: 8,
                  children: categories.map(_categoryChip).toList(),
                ),
              ),

              if (selectedCategory != null &&
                  (categorySpecs[selectedCategory!] ?? []).isNotEmpty) ...[
                const SizedBox(height: 20),
                _sectionLabel(
                    "ESPECIFICACIONES · ${selectedCategory!.toUpperCase()}"),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _card,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                        color: _accent.withOpacity(0.20), width: 1),
                    boxShadow: [
                      BoxShadow(color: _accent.withOpacity(0.05),
                          blurRadius: 16, spreadRadius: 1),
                      BoxShadow(color: Colors.black.withOpacity(0.25),
                          blurRadius: 12, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    children: (categorySpecs[selectedCategory!] ?? [])
                        .asMap().entries.map((entry) {
                      final spec = entry.value;
                      return Padding(
                        padding: EdgeInsets.only(top: entry.key == 0 ? 0 : 10),
                        child: _field(
                          controller: dynamicSpecsControllers[spec['label']]!,
                          label:  spec['label'] as String,
                          icon:   spec['icon']  as IconData,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],

              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: GestureDetector(
                  onTap: _isSaving ? null : _saveProduct,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _isSaving
                            ? [_accent.withOpacity(0.3),
                               _accent.withOpacity(0.2)]
                            : [const Color(0xFF00D4FF),
                               const Color(0xFF0090B8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: _isSaving ? [] : [
                        BoxShadow(
                            color: _accent.withOpacity(0.35),
                            blurRadius: 20, spreadRadius: 1,
                            offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Center(
                      child: _isSaving
                          ? const SizedBox(width: 22, height: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.5, color: Colors.white))
                          : Row(mainAxisSize: MainAxisSize.min, children: const [
                              Icon(Icons.save_rounded,
                                  color: Colors.white, size: 18),
                              SizedBox(width: 8),
                              Text("Guardar Producto",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                      letterSpacing: 0.3)),
                            ]),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppBackButton extends StatefulWidget {
  final VoidCallback onTap;
  const _AppBackButton({required this.onTap});

  @override
  State<_AppBackButton> createState() => _AppBackButtonState();
}

class _AppBackButtonState extends State<_AppBackButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 130));
    _scale = Tween<double>(begin: 1.0, end: 0.82)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _onTapDown(_)  => _ctrl.forward();
  void _onTapUp(_)    { _ctrl.reverse(); widget.onTap(); }
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
            width: 40, height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF112233), Color(0xFF0D1F33)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                  color: const Color(0xFF00D4FF).withOpacity(0.35), width: 1.2),
              boxShadow: [
                BoxShadow(color: const Color(0xFF00D4FF).withOpacity(0.18),
                    blurRadius: 10, offset: const Offset(0, 2)),
                BoxShadow(color: Colors.black.withOpacity(0.35),
                    blurRadius: 6, offset: const Offset(0, 3)),
              ],
            ),
            child: Stack(alignment: Alignment.center, children: [
              Positioned(top: 4, left: 4,
                child: Container(width: 16, height: 8,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(colors: [
                      Colors.white.withOpacity(0.08),
                      Colors.transparent,
                    ]),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              ShaderMask(
                shaderCallback: (b) => const LinearGradient(
                  colors: [Color(0xFF7AE8FF), Color(0xFF00D4FF)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ).createShader(b),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 17),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}