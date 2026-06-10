import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/session_service.dart';

class FourthPage extends StatefulWidget {
  const FourthPage({super.key});

  @override
  State<FourthPage> createState() => _FourthPageState();
}

class _FourthPageState extends State<FourthPage> {
  static const int totalPages = 4;
  static const int currentPage = 3;

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
    context.go('/thirdpage', extra: {'email': _email});
  }

  Future<void> _goToHome() async {
    if (_email.isNotEmpty) {
      await SessionService.saveEmail(_email);
    }
    if (!mounted) return;
    context.go('/home');
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
                  "What You’ll Get",
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
                          Icons.restaurant_menu,
                          "Recipe Name",
                          "View the name of the suggested dish.",
                        ),
                        const SizedBox(height: 20),
                        buildStep(
                          Icons.menu_book,
                          "Detailed Recipe",
                          "Step-by-step cooking instructions.",
                        ),
                        const SizedBox(height: 20),
                        buildStep(
                          Icons.star,
                          "Best Matches",
                          "Top recommended recipe plus two alternatives.",
                        ),
                        const SizedBox(height: 20),
                        buildStep(
                          Icons.image,
                          "AI-Generated Food Image",
                          "Preview of the dish created using AI.",
                        ),
                        const SizedBox(height: 20),
                        buildStep(
                          Icons.local_fire_department,
                          "Nutritional Information",
                          "Calories and basic nutrition details.",
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
                      onPressed: _goToHome,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7A2D00),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        "Lets Find\nRecipes",
                        style: TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
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
