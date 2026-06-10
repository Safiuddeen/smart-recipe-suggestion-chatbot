import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/terms_service.dart';

class TermsPage extends StatefulWidget {
  const TermsPage({super.key});

  @override
  State<TermsPage> createState() => _TermsPageState();
}

class _TermsPageState extends State<TermsPage> {
  bool isAccepted = false;
  bool isLoggedIn = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPageState();
  }

  Future<void> _loadPageState() async {
    final prefs = await SharedPreferences.getInstance();
    final loggedInEmail = prefs.getString('logged_in_email') ?? '';
    final firebaseUser = FirebaseAuth.instance.currentUser;

    final accepted = await TermsService.isAccepted();

    if (!mounted) return;

    setState(() {
      isAccepted = accepted;
      isLoggedIn =
          (firebaseUser != null && (firebaseUser.email?.isNotEmpty ?? false)) ||
          loggedInEmail.isNotEmpty;
      isLoading = false;
    });
  }

  Future<void> _agreeAndReturn() async {
    await TermsService.setAccepted(true);

    if (!mounted) return;

    setState(() {
      isAccepted = true;
    });

    context.go('/signin');
  }

  void _handleBack() {
    if (isLoggedIn) {
      context.go('/home');
    } else {
      context.go('/signin');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) {
            _handleBack();
          }
        },
        child: Scaffold(
          backgroundColor: const Color(0xFFBCEAA9),
          appBar: AppBar(
            backgroundColor: const Color(0xFFBCEAA9),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black87),
              onPressed: _handleBack,
            ),
          ),
          body: isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF7A2D00)),
                )
              : SafeArea(
                  child: Column(
                    children: [
                      const SizedBox(height: 10),

                      const Text(
                        "TERMS & CONDITIONS",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF7A2D00),
                        ),
                      ),

                      const SizedBox(height: 20),

                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              buildPoint(
                                "This app provides recipe suggestions based on the ingredients you enter.",
                              ),
                              buildPoint(
                                "AI-generated recipes and images are for guidance purposes only.",
                              ),
                              buildPoint(
                                "Nutritional information (e.g., calories) is estimated and may not be exact.",
                              ),
                              buildPoint(
                                "Users must consider allergies and dietary restrictions before cooking.",
                              ),
                              buildPoint(
                                "The app does not guarantee ingredient availability or cooking results.",
                              ),
                              buildPoint(
                                "User data will be handled securely and not shared without consent.",
                              ),
                              buildPoint(
                                "This app helps reduce food waste by suggesting efficient meal options.",
                              ),
                              buildPoint(
                                "By using this app, you agree to future updates of these terms.",
                              ),
                            ],
                          ),
                        ),
                      ),

                      if (!isLoggedIn) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Checkbox(
                                value: isAccepted,
                                activeColor: const Color(0xFF7A2D00),
                                onChanged: (value) {
                                  setState(() {
                                    isAccepted = value ?? false;
                                  });
                                },
                              ),
                              const Expanded(
                                child: Text(
                                  "I agree to the Terms & Conditions",
                                  style: TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 10),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: isAccepted ? _agreeAndReturn : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF7A2D00),
                                disabledBackgroundColor: Colors.grey,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                              child: const Text(
                                "Ok I Agreed",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            "You accepted all Terms & Conditions",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],

                      const SizedBox(height: 10),
                    ],
                  ),
                ),
          bottomNavigationBar: Container(
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
        ),
      ),
    );
  }

  Widget buildPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "• ",
            style: TextStyle(fontSize: 18, color: Color(0xFF7A2D00)),
          ),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}
