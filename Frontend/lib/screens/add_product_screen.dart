import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/api_service.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final ApiService api = ApiService();

  // Controllers base
  final nameController = TextEditingController();
  final brandController = TextEditingController();
  final priceController = TextEditingController();
  final stockController = TextEditingController();
  final imageController = TextEditingController();

  // 🔥 Categorías PRO
  final List<String> categories = [
    "CPU",
    "GPU",
    "RAM",
    "SSD",
    "Motherboard",
    "Power Supply",
    "Case",
    "Cooling",
    "Prebuilt PC"
  ];

  String? selectedCategory;

  // 🔥 Specs dinámicos por categoría
  final Map<String, List<String>> categorySpecs = {
    "CPU": ["Cores", "Threads", "Frequency (GHz)"],
    "GPU": ["VRAM (GB)", "Chipset"],
    "RAM": ["Size (GB)", "Speed (MHz)"],
    "SSD": ["Capacity (GB)", "Type (NVMe/SATA)"],
    "Motherboard": ["Socket", "Chipset", "Form Factor"],
    "Power Supply": ["Wattage", "Certification"],
    "Case": ["Form Factor Support"],
    "Cooling": ["Type (Air/Liquid)", "Fan Size"],
    "Prebuilt PC": ["CPU", "GPU", "RAM", "Storage"]
  };

  final Map<String, TextEditingController> dynamicSpecsControllers = {};

  // 🔥 Error UI
  void showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  // 🔥 Cuando cambia categoría
  void onCategoryChanged(String? value) {
    setState(() {
      selectedCategory = value;

      dynamicSpecsControllers.clear();

      if (value != null && categorySpecs[value] != null) {
        for (var spec in categorySpecs[value]!) {
          dynamicSpecsControllers[spec] = TextEditingController();
        }
      }
    });
  }

  // 🔥 Guardar producto
  void saveProduct() async {
    if (nameController.text.isEmpty ||
        brandController.text.isEmpty ||
        selectedCategory == null ||
        priceController.text.isEmpty ||
        stockController.text.isEmpty) {
      showError("Completa todos los campos obligatorios");
      return;
    }

    double? price = double.tryParse(priceController.text);
    int? stock = int.tryParse(stockController.text);

    if (price == null || price <= 0) {
      showError("Precio inválido");
      return;
    }

    if (stock == null || stock < 0) {
      showError("Stock inválido");
      return;
    }

    // 🔥 Specs automáticos
    Map<String, dynamic> specsJson = {};

    dynamicSpecsControllers.forEach((key, controller) {
      if (controller.text.isNotEmpty) {
        specsJson[key] = controller.text;
      }
    });

    final product = Product(
      name: nameController.text,
      brand: brandController.text,
      category: selectedCategory!,
      price: price,
      stock: stock,
      image: imageController.text,
      specs: specsJson.isNotEmpty ? specsJson : null,
    );

    await api.createProduct(product);
    Navigator.pop(context);
  }

  InputDecoration inputStyle(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.blueAccent),
      filled: true,
      fillColor: Colors.white.withOpacity(0.9),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Agregar Producto"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),

      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0F2027),
              Color(0xFF203A43),
              Color(0xFF2C5364),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),

        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: inputStyle("Nombre", Icons.devices),
                      ),

                      const SizedBox(height: 12),

                      TextField(
                        controller: brandController,
                        decoration: inputStyle("Marca", Icons.business),
                      ),

                      const SizedBox(height: 12),

                      // 🔥 DROPDOWN CATEGORÍA
                      DropdownButtonFormField<String>(
                        value: selectedCategory,
                        decoration: inputStyle("Categoría", Icons.category),
                        items: categories.map((cat) {
                          return DropdownMenuItem(
                            value: cat,
                            child: Text(cat),
                          );
                        }).toList(),
                        onChanged: onCategoryChanged,
                      ),

                      const SizedBox(height: 12),

                      TextField(
                        controller: priceController,
                        keyboardType: TextInputType.number,
                        decoration: inputStyle("Precio", Icons.attach_money),
                      ),

                      const SizedBox(height: 12),

                      TextField(
                        controller: stockController,
                        keyboardType: TextInputType.number,
                        decoration: inputStyle("Stock", Icons.inventory),
                      ),

                      const SizedBox(height: 12),

                      TextField(
                        controller: imageController,
                        decoration: inputStyle("Imagen URL", Icons.image),
                      ),

                      const SizedBox(height: 12),

                      // 🔥 SPECS DINÁMICOS
                      if (selectedCategory != null &&
                          categorySpecs[selectedCategory!] != null)
                        Column(
                          children: categorySpecs[selectedCategory!]!.map((spec) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: TextField(
                                controller: dynamicSpecsControllers[spec],
                                decoration: inputStyle(spec, Icons.memory),
                              ),
                            );
                          }).toList(),
                        ),

                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          onPressed: saveProduct,
                          child: const Text(
                            "Guardar Producto",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
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