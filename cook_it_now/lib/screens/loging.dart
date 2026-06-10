import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/email_login_service.dart';

class Loging extends StatefulWidget {
  const Loging({super.key});

  @override
  State<Loging> createState() => _LogingState();
}

class _LogingState extends State<Loging> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final EmailLoginService _emailLoginService = EmailLoginService();

  bool obscurePassword = true;
  bool isLoading = false;

  String? emailError;
  String? passwordError;
  String? loginError;

  final RegExp emailRegex = RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$');

  Future<void> validateAndLogin() async {
    setState(() {
      emailError = null;
      passwordError = null;
      loginError = null;
    });

    bool isValid = true;

    if (emailController.text.trim().isEmpty) {
      emailError = "Email is required";
      isValid = false;
    } else if (!emailRegex.hasMatch(emailController.text.trim())) {
      emailError = "Enter a valid email (example@email.com)";
      isValid = false;
    }

    if (passwordController.text.isEmpty) {
      passwordError = "Password is required";
      isValid = false;
    }

    setState(() {});

    if (!isValid) return;

    setState(() {
      isLoading = true;
    });

    final result = await _emailLoginService.login(
      email: emailController.text.trim(),
      password: passwordController.text,
    );

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });

    if (result['success'] == true) {
      final data = result['data'];
      final user = data['user'];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('logged_in_email', user['email'] ?? '');
      await prefs.setString('logged_in_name', user['name'] ?? '');
      await prefs.setString('logged_in_provider', user['provider'] ?? 'Email');

      if (!mounted) return;
      context.go('/home');
    } else {
      setState(() {
        loginError = "Username or password incorrect";
      });
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _hideKeyboard() {
    FocusScope.of(context).unfocus();
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
            context.go('/signin');
          }
        },
        child: Scaffold(
          backgroundColor: const Color(0xFFBCEAA9),
          appBar: AppBar(
            backgroundColor: const Color(0xFFBCEAA9),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black87),
              onPressed: () => context.go('/signin'),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Column(
              children: [
                SizedBox(height: screen.height * 0.03),

                Image.asset(
                  "assets/appIcon/logo2.jpg",
                  height: screen.height * 0.16,
                ),

                const SizedBox(height: 20),

                const Text(
                  "Create an account and cook smarter\nusing what's already in your kitchen",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Color(0xFF6B3B1F)),
                ),

                const SizedBox(height: 25),

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

                const SizedBox(height: 15),

                TextField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  decoration: InputDecoration(
                    hintText: "Password",
                    errorText: passwordError,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 16,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.brown,
                      ),
                      onPressed: () {
                        setState(() {
                          obscurePassword = !obscurePassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () {
                      context.go('/forgot-password-email');
                    },
                    child: const Text(
                      "Forget Password?",
                      style: TextStyle(
                        color: Color(0xFF7A2D00),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),

                if (loginError != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    loginError!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],

                const SizedBox(height: 16),

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
                    onPressed: isLoading ? null : validateAndLogin,
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
                            "Login",
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                  ),
                ),

                const SizedBox(height: 40),
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
