import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _dotAnimation;

  @override
  void initState() {
    super.initState();

    // Navigate after 10 seconds
    Future.delayed(const Duration(seconds: 10), () {
      if (!mounted) return; // ✅ check if widget is still in tree
      context.go('/welScreen');
    });

    // Animation controller for dots
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat();

    _dotAnimation = IntTween(
      begin: 1,
      end: 8,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFBCEAA9), // Updated background color
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Image.asset(
              'assets/appIcon/logo.jpg',
              width: screenSize.width * 0.5,
              height: screenSize.width * 1.0,
              fit: BoxFit.contain,
            ),

            const SizedBox(height: 20),

            // Text: Please wait...
            const Text(
              "Please wait",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF622906), // Updated text color
              ),
            ),

            const SizedBox(height: 6),

            // Dot animation
            AnimatedBuilder(
              animation: _dotAnimation,
              builder: (context, child) {
                int dots = _dotAnimation.value;
                return Text(
                  '.' * dots,
                  style: const TextStyle(
                    fontSize: 50,
                    letterSpacing: 3,
                    color: Color(0xFF622906),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
