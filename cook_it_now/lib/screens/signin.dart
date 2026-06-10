import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/google_auth_service.dart';
import '../services/email_auth_service.dart';
import '../services/session_service.dart';

class SignIn extends StatefulWidget {
  const SignIn({super.key});

  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final GoogleAuthService _googleAuthService = GoogleAuthService();

  bool isChecked = false;
  bool obscurePassword = true;
  bool isGoogleLoading = false;
  bool isEmailLoading = false;

  String? nameError;
  String? emailError;
  String? passwordError;
  String? checkError;
  String? generalError;

  final RegExp emailRegex = RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$');

  Future<void> handleEmailSignup() async {
    FocusScope.of(context).unfocus();

    setState(() {
      nameError = null;
      emailError = null;
      passwordError = null;
      checkError = null;
      generalError = null;
    });

    bool isValid = true;

    if (nameController.text.trim().isEmpty) {
      nameError = "Name is required";
      isValid = false;
    }

    if (emailController.text.trim().isEmpty) {
      emailError = "Email is required";
      isValid = false;
    } else if (!emailRegex.hasMatch(emailController.text.trim())) {
      emailError = "Enter a valid email";
      isValid = false;
    }

    if (passwordController.text.trim().isEmpty) {
      passwordError = "Password is required";
      isValid = false;
    } else if (passwordController.text.trim().length < 6) {
      passwordError = "Password must be at least 6 characters";
      isValid = false;
    }

    if (!isChecked) {
      checkError = "You must agree to Terms & Conditions";
      isValid = false;
    }

    setState(() {});

    if (!isValid) return;

    setState(() {
      isEmailLoading = true;
    });

    final email = emailController.text.trim();

    final result = await EmailAuthService.requestSignupOtp(
      name: nameController.text.trim(),
      email: email,
      password: passwordController.text.trim(),
    );

    if (!mounted) return;

    setState(() {
      isEmailLoading = false;
    });

    if (result["success"] == true) {
      await SessionService.saveEmail(email);
      if (!mounted) return;
      context.push('/verification', extra: {"email": email, "isNewUser": true});
    } else {
      setState(() {
        generalError = result["message"] ?? "Failed to send OTP";
      });
    }
  }

  Future<void> handleGoogleSignIn() async {
    FocusScope.of(context).unfocus();

    setState(() {
      generalError = null;
      isGoogleLoading = true;
    });

    try {
      final result = await _googleAuthService.signInWithGoogle();

      final String? email = (result['email'] ?? '').toString().trim().isNotEmpty
          ? result['email'].toString().trim()
          : null;

      final bool isNewUser = result['is_new_user'] == true;

      if (email != null) {
        await SessionService.saveEmail(email);
      }

      if (!mounted) return;

      if (isNewUser) {
        context.go('/firstpage', extra: {'email': email, 'isNewUser': true});
      } else {
        context.go('/home');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        generalError = e.toString().replaceAll("Exception: ", "");
      });
    } finally {
      if (mounted) {
        setState(() {
          isGoogleLoading = false;
        });
      }
    }
  }

  void clearFieldErrors() {
    setState(() {
      nameError = null;
      emailError = null;
      passwordError = null;
      checkError = null;
      generalError = null;
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) {
            context.go('/welScreen');
          }
        },
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          backgroundColor: const Color(0xFFBCEAA9),
          appBar: AppBar(
            backgroundColor: const Color(0xFFBCEAA9),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black87),
              onPressed: () => context.go('/welScreen'),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 35),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: screen.height * 0.01),
                Image.asset(
                  "assets/appIcon/logo2.jpg",
                  height: screen.height * 0.15,
                ),
                const SizedBox(height: 5),
                const Text(
                  "Create an account and cook smarter\nusing what's already in your kitchen",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Color(0xFF6B3B1F)),
                ),
                const SizedBox(height: 25),
                TextField(
                  controller: nameController,
                  onChanged: (_) {
                    if (nameError != null || generalError != null) {
                      clearFieldErrors();
                    }
                  },
                  decoration: InputDecoration(
                    hintText: "Full Name",
                    errorText: nameError,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 10,
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
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (_) {
                    if (emailError != null || generalError != null) {
                      clearFieldErrors();
                    }
                  },
                  decoration: InputDecoration(
                    hintText: "Email Address",
                    errorText: emailError,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 10,
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
                  onChanged: (_) {
                    if (passwordError != null || generalError != null) {
                      clearFieldErrors();
                    }
                  },
                  decoration: InputDecoration(
                    hintText: "Password",
                    errorText: passwordError,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 10,
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: isChecked,
                          onChanged: (value) {
                            setState(() {
                              isChecked = value ?? false;
                              checkError = null;
                            });
                          },
                        ),
                        const Expanded(
                          child: Text(
                            "I agree to terms & conditions",
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                    if (checkError != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Text(
                          checkError!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7A2D00),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: isEmailLoading || isGoogleLoading
                        ? null
                        : handleEmailSignup,
                    child: isEmailLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.2,
                            ),
                          )
                        : const Text(
                            "Sign Up",
                            style: TextStyle(fontSize: 14, color: Colors.white),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: const [
                    Expanded(
                      child: Divider(color: Color(0xFF7A2D00), thickness: 1.5),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text("or"),
                    ),
                    Expanded(
                      child: Divider(color: Color(0xFF7A2D00), thickness: 1.5),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                socialButton(
                  icon: "assets/images/google.png",
                  text: isGoogleLoading
                      ? "Please wait..."
                      : "Sign in with Google",
                  onTap: isEmailLoading || isGoogleLoading
                      ? null
                      : handleGoogleSignIn,
                ),
                const SizedBox(height: 12),
                socialButton(
                  icon: "assets/images/facebook.png",
                  text: "Sign in with Face Book",
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Facebook sign-in is not added yet"),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                if (generalError != null)
                  Text(
                    generalError!,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                const SizedBox(height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Already have an account? "),
                    GestureDetector(
                      onTap: () {
                        context.go('/loging');
                      },
                      child: const Text(
                        "Login",
                        style: TextStyle(
                          color: Colors.brown,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
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

  Widget socialButton({
    required String icon,
    required String text,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 45,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(icon, height: 22),
            const SizedBox(width: 12),
            Text(text, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
