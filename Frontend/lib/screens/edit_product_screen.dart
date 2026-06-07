import 'dart:typed_data';
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

class EditProductScreen extends StatefulWidget {
  final Product product;

  const EditProductScreen({
    super.key,
    required this.product,
  });

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen>
    with TickerProviderStateMixin {
  final ApiService api = ApiService();

  Uint8List? selectedImageBytes;
  String? selectedImageName;
  bool isUploadingImage = false;

  static const _bg = Color(0xFF060D17);
  static const _surface = Color(0xFF111E2E);
  static const _card = Color(0xFF162538);
  static const _accent = Color(0xFF00D4FF);
  static const _accent2 = Color(0xFF0099BB);
  static const _textPri = Color(0xFFEFF6FF);
  static const _textSec = Color(0xFF7A9BB5);
  static const _divider = Color(0xFF1A2E44);

  late TextEditingController nameController;
  late TextEditingController priceController;
  late TextEditingController brandController;
  late TextEditingController stockController;
  late TextEditingController imageController;

  bool isSaving = false;

  final List<String> categories = [
    "CPU", "GPU", "RAM", "SSD", "Motherboard",
    "Power Supply", "Case", "Cooling", "Prebuilt PC",
  ];

  String? selectedCategory;

  final Map<String, List<String>> categorySpecs = {
    "CPU": ["Cores","Threads","Socket","Base Clock","Boost Clock","Cache","TDP","Architecture","Integrated Graphics","Unlocked"],
    "GPU": ["VRAM","Chipset","Boost Clock","Memory Type","Bus Width","Ray Tracing","DLSS / FSR","Power Consumption","Length","HDMI / DisplayPort"],
    "RAM": ["Capacity","Speed","Type","Latency","Voltage","RGB","Channels"],
    "SSD": ["Capacity","Type","Read Speed","Write Speed","Form Factor","Interface","TBW"],
    "Motherboard": ["Socket","Chipset","Form Factor","RAM Support","PCIe Version","M.2 Slots","WiFi","Bluetooth"],
    "Power Supply": ["Wattage","Certification","Modular","Fan Size","Voltage","Protection"],
    "Case": ["Form Factor Support","GPU Clearance","Radiator Support","Fans Included","Side Panel","Color"],
    "Cooling": ["Type","Fan Size","RPM","RGB","Noise Level","Socket Support"],
    "Prebuilt PC": ["CPU","GPU","RAM","Storage","Power Supply","Cooling","Motherboard","Operating System"],
  };

  final Map<String, TextEditingController> dynamicSpecsControllers = {};

  late AnimationController _controller;
  late Animation<double> _fade;

  // AÑADIDO: convierte 1250000.0 → "1.250.000" para el initState
  String _toCOP(double value) {
    return value.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _controller.forward();

    nameController = TextEditingController(text: widget.product.name);
    priceController = TextEditingController(text: _toCOP(widget.product.price)); // AÑADIDO
    brandController = TextEditingController(text: widget.product.brand ?? "");
    stockController = TextEditingController(text: (widget.product.stock ?? 0).toString());
    imageController = TextEditingController(text: widget.product.image ?? "");

    selectedCategory = widget.product.category;
    loadSpecsControllers();
  }

  void loadSpecsControllers() {
    dynamicSpecsControllers.clear();
    if (selectedCategory != null && categorySpecs[selectedCategory!] != null) {
      for (var spec in categorySpecs[selectedCategory!]!) {
        dynamicSpecsControllers[spec] = TextEditingController(
          text: widget.product.specs?[spec]?.toString() ?? "",
        );
      }
    }
  }

  void showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.redAccent,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ));
  }

  void showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.green,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ));
  }

  Future<void> pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      if (file.bytes == null) {
        showError("No se pudieron leer los bytes de la imagen");
        return;
      }
      setState(() {
        selectedImageBytes = file.bytes;
        selectedImageName = file.name;
      });
    } catch (e) {
      showError("Error seleccionando imagen: $e");
    }
  }

  Future<String?> uploadImage() async {
    if (selectedImageBytes == null) {
      return imageController.text.trim();
    }
    try {
      setState(() => isUploadingImage = true);
      final imageUrl = await api.uploadProductImage(
        selectedImageBytes!,
        selectedImageName ?? "image.jpg",
      );
      return imageUrl;
    } catch (e) {
      showError("Error subiendo imagen: $e");
      return null;
    } finally {
      setState(() => isUploadingImage = false);
    }
  }

  void onCategoryChanged(String? value) {
    setState(() {
      selectedCategory = value;
      dynamicSpecsControllers.clear();
      if (value != null && categorySpecs[value] != null) {
        for (var spec in categorySpecs[value]!) {
          dynamicSpecsControllers[spec] = TextEditingController(
            text: widget.product.specs?[spec]?.toString() ?? "",
          );
        }
      }
    });
  }

  void updateProduct() async {
    FocusScope.of(context).unfocus();

    if (nameController.text.trim().isEmpty ||
        brandController.text.trim().isEmpty ||
        selectedCategory == null ||
        priceController.text.trim().isEmpty ||
        stockController.text.trim().isEmpty) {
      showError("Completa todos los campos");
      return;
    }

    if (selectedImageBytes == null && imageController.text.trim().isEmpty) {
      showError("Selecciona o ingresa una imagen");
      return;
    }

    // AÑADIDO: quita los puntos para parsear
    final price = double.tryParse(priceController.text.replaceAll('.', ''));
    final stock = int.tryParse(stockController.text);

    if (price == null || price <= 0) { showError("Precio inválido"); return; }
    if (stock == null || stock <= 0) { showError("Stock inválido");  return; }

    final uploadedImage = await uploadImage();
    if (uploadedImage == null || uploadedImage.isEmpty) {
      showError("Error al subir la imagen");
      return;
    }

    final Map<String, dynamic> specsJson = {};
    dynamicSpecsControllers.forEach((key, controller) {
      if (controller.text.trim().isNotEmpty) {
        specsJson[key] = controller.text.trim();
      }
    });

    final updated = Product(
      id: widget.product.id,
      name: nameController.text.trim(),
      price: price,
      category: selectedCategory!,
      brand: brandController.text.trim(),
      stock: stock,
      image: uploadedImage,
      specs: specsJson.isNotEmpty ? specsJson : null,
    );

    try {
      setState(() => isSaving = true);
      await api.updateProduct(updated);
      showSuccess("Producto actualizado");
      Future.delayed(
        const Duration(milliseconds: 700),
        () => Navigator.pop(context, true),
      );
    } catch (e) {
      showError("Error al actualizar: $e");
    } finally {
      setState(() => isSaving = false);
    }
  }

  InputDecoration inputStyle(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: _textSec),
      prefixIcon: Icon(icon, color: _accent),
      filled: true,
      fillColor: _surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _accent, width: 1.5),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    nameController.dispose();
    priceController.dispose();
    brandController.dispose();
    stockController.dispose();
    imageController.dispose();
    for (var c in dynamicSpecsControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: _textPri),
        title: const Text(
          "Editar Producto",
          style: TextStyle(color: _textPri, fontWeight: FontWeight.bold),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _divider),
        ),
      ),
      body: FadeTransition(
        opacity: _fade,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _divider),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.35),
                  blurRadius: 25,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 82, height: 82,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(colors: [_accent, _accent2]),
                    boxShadow: [BoxShadow(
                        color: _accent.withOpacity(0.35),
                        blurRadius: 28, spreadRadius: 2)],
                  ),
                  child: const Icon(Icons.edit, color: Colors.black, size: 38),
                ),
                const SizedBox(height: 20),
                const Text("Editar Producto",
                    style: TextStyle(color: _textPri, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 30),

                TextField(
                  controller: nameController,
                  style: const TextStyle(color: _textPri),
                  decoration: inputStyle("Nombre", Icons.devices),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: brandController,
                  style: const TextStyle(color: _textPri),
                  decoration: inputStyle("Marca", Icons.business),
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  dropdownColor: _surface,
                  style: const TextStyle(color: _textPri),
                  decoration: inputStyle("Categoría", Icons.category),
                  items: categories
                      .map((cat) => DropdownMenuItem(
                            value: cat,
                            child: Text(cat, style: const TextStyle(color: _textPri)),
                          ))
                      .toList(),
                  onChanged: onCategoryChanged,
                ),
                const SizedBox(height: 16),

                // AÑADIDO: _CopInputFormatter en el campo precio
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [_CopInputFormatter()],
                  style: const TextStyle(color: _textPri),
                  decoration: inputStyle("Precio", Icons.attach_money),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: stockController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(color: _textPri),
                  decoration: inputStyle("Stock", Icons.inventory_2),
                ),
                const SizedBox(height: 16),

                if (selectedImageBytes != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    width: double.infinity,
                    height: 220,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      image: DecorationImage(
                        image: MemoryImage(selectedImageBytes!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                else if (imageController.text.trim().isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    width: double.infinity,
                    height: 220,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      image: DecorationImage(
                        image: NetworkImage(ApiService.resolveImage(imageController.text)),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _surface,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: isUploadingImage ? null : pickImage,
                    icon: const Icon(Icons.upload, color: _accent),
                    label: Text(
                      isUploadingImage ? "Subiendo..." : "Cambiar Imagen",
                      style: const TextStyle(color: _textPri),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: imageController,
                  style: const TextStyle(color: _textPri),
                  decoration: inputStyle("Imagen URL", Icons.image),
                ),

                if (selectedCategory != null &&
                    categorySpecs[selectedCategory!] != null)
                  Column(
                    children: categorySpecs[selectedCategory!]!
                        .map((spec) => Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: TextField(
                                controller: dynamicSpecsControllers[spec],
                                style: const TextStyle(color: _textPri),
                                decoration: inputStyle(spec, Icons.memory),
                              ),
                            ))
                        .toList(),
                  ),

                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accent,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18)),
                    ),
                    onPressed: isSaving ? null : updateProduct,
                    child: isSaving
                        ? const SizedBox(
                            width: 24, height: 24,
                            child: CircularProgressIndicator(
                                color: Colors.black, strokeWidth: 2))
                        : const Text("Actualizar Producto",
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
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