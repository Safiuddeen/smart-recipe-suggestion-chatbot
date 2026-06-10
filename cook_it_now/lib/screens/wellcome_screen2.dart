import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class WelcomeStart extends StatefulWidget {
  const WelcomeStart({super.key});

  @override
  State<WelcomeStart> createState() => _WelcomeStartState();
}

class _WelcomeStartState extends State<WelcomeStart> {
  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;

    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: const Color(0xFFBCEAA9),
        appBar: AppBar(backgroundColor: const Color(0xFFBCEAA9), elevation: 0),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(height: screenSize.height * 0.02),

                        const Text(
                          'WELCOME TO THE',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6B3B1F),
                          ),
                        ),

                        const SizedBox(height: 20),

                        const Text(
                          'Cook It Now',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6B3B1F),
                            letterSpacing: 1.5,
                          ),
                        ),

                        SizedBox(height: screenSize.height * 0.01),

                        Image.asset(
                          'assets/appIcon/logo.jpg',
                          height: screenSize.height * 0.5,
                          fit: BoxFit.contain,
                        ),

                        const SizedBox(height: 8),

                        _buildStartButton(context, screenSize),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Footer
            Container(
              height: 40,
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.only(right: 16),
              alignment: Alignment.centerRight,
              child: Image.asset(
                'assets/appIcon/footerlogo2.jpg',
                height: 30,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartButton(BuildContext context, Size screenSize) {
    return SizedBox(
      width: screenSize.width * 0.7,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF622906),
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        onPressed: () {
          context.go('/signin');
        },
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Get Start',
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }
}
