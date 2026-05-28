import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'product_list_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  @override
  void initState() {
    super.initState();
    _redirect();
  }

  // 🔥 REDIRECCIÓN AUTOMÁTICA
  Future<void> _redirect() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    if (token != null && token.isNotEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ProductListScreen(token: token),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0A1A2F),
      body: Center(
        child: CircularProgressIndicator(
          color: Color(0xFF1ABCFE),
        ),
      ),
    );
  }
}