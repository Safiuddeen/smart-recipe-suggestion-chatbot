import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/forgot_password_service.dart';

class ForgotPasswordEmailPage extends StatefulWidget {
  const ForgotPasswordEmailPage({super.key});

  @override
  State<ForgotPasswordEmailPage> createState() =>
      _ForgotPasswordEmailPageState();
}

class _ForgotPasswordEmailPageState extends State<ForgotPasswordEmailPage> {
  final TextEditingController emailController = TextEditingController();

  bool isLoading = false;
  String? emailError;
  String? apiError;

  final RegExp emailRegex = RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$');

  void _hideKeyboard() {
    FocusScope.of(context).unfocus();
  }

  Future<void> sendResetOtp() async {
    setState(() {
      emailError = null;
      apiError = null;
    });

    final email = emailController.text.trim();

    if (email.isEmpty) {
      setState(() {
        emailError = "Email is required";
      });
      return;
    }

    if (!emailRegex.hasMatch(email)) {
      setState(() {
        emailError = "Enter a valid email";
      });
      return;
    }

    setState(() {
      isLoading = true;
    });

    final result = await ForgotPasswordService.requestResetOtp(email: email);

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });

    if (result["success"] == true) {
      context.push('/reset-verification', extra: {"email": email});
    } else {
      setState(() {
        apiError = result["message"] ?? "Failed to send OTP";
      });
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;

    return GestureDetector(
      onTap: _hideKeyboard,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) {
            context.go('/loging');
          }
        },
        child: Scaffold(
          backgroundColor: const Color(0xFFBCEAA9),
          appBar: AppBar(
            backgroundColor: const Color(0xFFBCEAA9),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black87),
              onPressed: () => context.go('/loging'),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Column(
              children: [
                SizedBox(height: screen.height * 0.05),

                Image.asset(
                  "assets/appIcon/logo2.jpg",
                  height: screen.height * 0.16,
                ),

                const SizedBox(height: 20),

                const Text(
                  "Forgot Password",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF7A2D00),
                  ),
                ),

                const SizedBox(height: 15),

                const Text(
                  "Enter your email address to receive a 6-digit verification code",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Color(0xFF6B3B1F)),
                ),

                const SizedBox(height: 30),

                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: "Email Address",
                    errorText: emailError,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                if (apiError != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    apiError!,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],

                const SizedBox(height: 25),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7A2D00),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    onPressed: isLoading ? null : sendResetOtp,
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            "Send Code",
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                  ),
                ),
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
}
