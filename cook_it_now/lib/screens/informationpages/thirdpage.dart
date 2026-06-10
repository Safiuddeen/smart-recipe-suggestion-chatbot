import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/session_service.dart';

class ThirdPage extends StatefulWidget {
  const ThirdPage({super.key});

  @override
  State<ThirdPage> createState() => _ThirdPageState();
}

class _ThirdPageState extends State<ThirdPage> {
  static const int totalPages = 4;
  static const int currentPage = 2;

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
    context.go('/secondpage', extra: {'email': _email});
  }

  Future<void> _goNext() async {
    if (_email.isNotEmpty) {
      await SessionService.saveEmail(_email);
    }
    if (!mounted) return;
    context.go('/fourthpage', extra: {'email': _email});
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
          body: Column(
            children: [
              const Text(
                "SEARCH LIKE THIS",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF7A2D00),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ListView(
                    children: [
                      buildImageCard(
                        'assets/images/image01.png',
                        Icons.edit,
                        "Enter ingredients you already have",
                      ),
                      const SizedBox(height: 20),
                      buildImageCard(
                        'assets/images/image02.png',
                        Icons.search,
                        "Search recipes by name instantly",
                      ),
                      const SizedBox(height: 30),
                      const Text(
                        "No ingredients wasted. No time wasted.\nDiscover smart recipes powered by AI.",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF7A2D00),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
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
                  height: 25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildImageCard(String path, IconData icon, String text) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white, width: 3),
      ),
      child: Column(
        children: [
          Container(
            height: 150,
            width: double.infinity,
            alignment: Alignment.center,
            child: Image.asset(path, fit: BoxFit.contain),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFF7A2D00), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    text,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
