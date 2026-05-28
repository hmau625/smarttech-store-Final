import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List orders = [];
  bool loading = true;

  final String baseUrl = "http://localhost:8000";

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  Future<void> fetchOrders() async {
    final token = await getToken();

    final response = await http.get(
      Uri.parse("$baseUrl/orders/?token=$token"),
    );

    if (response.statusCode == 200) {
      setState(() {
        orders = jsonDecode(response.body);
        loading = false;
      });
    } else {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),

      appBar: AppBar(
        title: const Text("Mis compras"),
        backgroundColor: Colors.black,
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : orders.isEmpty
              ? const Center(
                  child: Text("No tienes compras aún 🛒"),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 15),
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                      ),

                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          // 🔥 HEADER PEDIDO
                          Text(
                            "Pedido #${order['order_id']}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),

                          const SizedBox(height: 5),

                          Text("Estado: ${order['status']}"),
                          Text("Total: \$${order['total_price']}"),
                          Text("Pago: ${order['payment_method']}"),
                          Text("Fecha: ${order['created_at']}"),

                          const Divider(),

                          // 🔥 PRODUCTOS
                          ...List.generate(order['items'].length, (i) {
                            final item = order['items'][i];

                            return Row(
                              children: [

                                const Icon(Icons.shopping_bag, size: 18),

                                const SizedBox(width: 5),

                                Expanded(
                                  child: Text(
                                    item['product_name'],
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),

                                Text("x${item['quantity']}"),
                                const SizedBox(width: 10),
                                Text("\$${item['price']}"),
                              ],
                            );
                          }),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}