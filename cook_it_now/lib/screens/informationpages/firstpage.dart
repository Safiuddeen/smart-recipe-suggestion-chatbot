import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/session_service.dart';

class FirstPage extends StatefulWidget {
  const FirstPage({super.key});

  @override
  State<FirstPage> createState() => _FirstPageState();
}

class _FirstPageState extends State<FirstPage> {
  static const int totalPages = 4;
  static const int currentPage = 0;

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

  Future<void> _next() async {
    if (_email.isNotEmpty) {
      await SessionService.saveEmail(_email);
    }
    if (!mounted) return;
    context.go('/secondpage', extra: {'email': _email});
  }

  @override
  Widget build(BuildContext context) {
    final Size screen = MediaQuery.of(context).size;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor: const Color(0xFFBCEAA9),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(height: screen.height * 0.08),
                        Image.asset(
                          'assets/appIcon/logo.jpg',
                          height: screen.height * 0.3,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          "Welcome to CookIt Now",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF7A2D00),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "Discover delicious recipes using ingredients you already have. Reduce food waste and cook smarter with our AI-powered suggestions.",
                          style: TextStyle(
                            fontSize: 16,
                            color: Color.fromARGB(221, 0, 0, 0),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: _next,
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
                      const SizedBox(height: 10),
                      LinearProgressIndicator(
                        value: (currentPage + 1) / totalPages,
                        backgroundColor: Colors.white,
                        color: const Color(0xFF7A2D00),
                        minHeight: 6,
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
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
}
