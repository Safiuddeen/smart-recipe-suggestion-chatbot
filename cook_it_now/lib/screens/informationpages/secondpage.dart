import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/session_service.dart';

class SecondPage extends StatefulWidget {
  const SecondPage({super.key});

  @override
  State<SecondPage> createState() => _SecondPageState();
}

class _SecondPageState extends State<SecondPage> {
  static const int totalPages = 4;
  static const int currentPage = 1;

  String _email = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final extra = GoRouterState.of(context).extra;
    if (extra is Map && extra['email'] != null) {
      _email = extra['email'].toString();
      SessionService.saveEmail(_email);
    }
  }

  Future<void> _goBack() async {
    if (_email.isNotEmpty) {
      await SessionService.saveEmail(_email);
    }
    if (!mounted) return;
    context.go('/firstpage', extra: {'email': _email});
  }

  Future<void> _goNext() async {
    if (_email.isNotEmpty) {
      await SessionService.saveEmail(_email);
    }
    if (!mounted) return;
    context.go('/thirdpage', extra: {'email': _email});
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) {
            _goBack();
          }
        },
        child: Scaffold(
          backgroundColor: const Color(0xFFBCEAA9),
          appBar: AppBar(
            backgroundColor: const Color(0xFFBCEAA9),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black87),
              onPressed: _goBack,
            ),
          ),
          body: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),
                const Text(
                  "HOW IT WORKS",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF7A2D00),
                  ),
                ),
                const SizedBox(height: 40),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        buildStep(
                          Icons.shopping_basket,
                          "Add Ingredients",
                          "Enter the ingredients you have at home.",
                        ),
                        const SizedBox(height: 20),
                        buildStep(
                          Icons.search,
                          "Search Recipes",
                          "Find recipes based on your ingredients.",
                        ),
                        const SizedBox(height: 20),
                        buildStep(
                          Icons.restaurant_menu,
                          "Get Suggestions",
                          "AI suggests the best meals you can cook.",
                        ),
                        const SizedBox(height: 20),
                        buildStep(
                          Icons.eco,
                          "Reduce Waste",
                          "Use leftover food and minimize waste.",
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: _goNext,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7A2D00),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        "Next",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: LinearProgressIndicator(
                    value: (currentPage + 1) / totalPages,
                    backgroundColor: Colors.white,
                    color: const Color(0xFF7A2D00),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  height: 40,
                  width: double.infinity,
                  color: Colors.white,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  child: Image.asset(
                    'assets/appIcon/footerlogo2.jpg',
                    height: 30,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget buildStep(IconData icon, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF7A2D00),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF7A2D00),
                ),
              ),
              const SizedBox(height: 5),
              Text(desc, style: const TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }
}
