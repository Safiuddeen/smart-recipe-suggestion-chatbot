import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../services/forgot_password_service.dart';

class ResetPasswordVerificationScreen extends StatefulWidget {
  final String email;

  const ResetPasswordVerificationScreen({super.key, required this.email});

  @override
  State<ResetPasswordVerificationScreen> createState() =>
      _ResetPasswordVerificationScreenState();
}

class _ResetPasswordVerificationScreenState
    extends State<ResetPasswordVerificationScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final int otpLength = 6;

  late List<TextEditingController> controllers;
  late List<FocusNode> focusNodes;

  String? errorText;
  String? apiError;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    controllers = List.generate(otpLength, (_) => TextEditingController());
    focusNodes = List.generate(otpLength, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final c in controllers) {
      c.dispose();
    }
    for (final f in focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void moveNext(int index) {
    if (index < otpLength - 1) {
      focusNodes[index + 1].requestFocus();
    } else {
      focusNodes[index].unfocus();
    }
  }

  void movePrevious(int index) {
    if (index > 0) {
      focusNodes[index - 1].requestFocus();
    }
  }

  String getOTP() {
    return controllers.map((e) => e.text.trim()).join();
  }

  bool validateOTP() {
    for (final c in controllers) {
      if (c.text.trim().isEmpty) {
        setState(() {
          errorText = "Please enter complete OTP";
          apiError = null;
        });
        return false;
      }
    }

    setState(() {
      errorText = null;
    });

    return true;
  }

  Future<void> verifyOtp() async {
    if (!validateOTP()) return;

    final otp = getOTP();

    setState(() {
      isLoading = true;
      apiError = null;
    });

    final result = await ForgotPasswordService.verifyResetOtp(
      email: widget.email,
      otpCode: otp,
    );

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });

    if (result["success"] == true) {
      context.go('/update-password', extra: {"email": widget.email});
    } else {
      setState(() {
        apiError = result["message"] ?? "OTP verification failed";
      });
    }
  }

  Future<void> resendOtp() async {
    setState(() {
      apiError = null;
    });

    final result = await ForgotPasswordService.resendResetOtp(
      email: widget.email,
    );

    if (!mounted) return;

    if (result["success"] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("OTP sent again successfully")),
      );
    } else {
      setState(() {
        apiError = result["message"] ?? "Failed to resend OTP";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          context.go('/forgot-password-email');
        }
      },
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          key: _scaffoldKey,
          backgroundColor: const Color(0xFFBCEAA9),
          appBar: AppBar(
            backgroundColor: const Color(0xFFBCEAA9),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black87),
              onPressed: () => context.go('/forgot-password-email'),
            ),
          ),
          body: Container(
            width: double.infinity,
            height: double.infinity,
            color: const Color(0xFFBCEAA9),
            padding: EdgeInsets.symmetric(
              horizontal: size.width * 0.08,
              vertical: size.height * 0.03,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: size.height * 0.04),

                Center(
                  child: Text(
                    "Verification Code",
                    style: TextStyle(
                      fontSize: size.width * 0.06,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF7A2D00),
                    ),
                  ),
                ),

                SizedBox(height: size.height * 0.015),

                Center(
                  child: Text(
                    "We have sent a 6-digit verification code to\n${widget.email}",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: size.width * 0.035,
                      color: const Color(0xFF7A2D00),
                    ),
                  ),
                ),

                SizedBox(height: size.height * 0.05),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(otpLength, (index) {
                    return SizedBox(
                      width: size.width * 0.12,
                      child: KeyboardListener(
                        focusNode: FocusNode(),
                        onKeyEvent: (event) {
                          if (event is KeyDownEvent &&
                              event.logicalKey ==
                                  LogicalKeyboardKey.backspace) {
                            if (controllers[index].text.isEmpty) {
                              movePrevious(index);
                            }
                          }
                        },
                        child: TextField(
                          controller: controllers[index],
                          focusNode: focusNodes[index],
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          maxLength: 1,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          style: TextStyle(fontSize: size.width * 0.05),
                          decoration: InputDecoration(
                            counterText: "",
                            filled: true,
                            fillColor: Colors.white,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: errorText != null
                                    ? Colors.red
                                    : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Color(0xFF7A2D00),
                                width: 1.5,
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onChanged: (value) {
                            if (value.isNotEmpty) {
                              moveNext(index);
                            }

                            if (controllers.every(
                              (c) => c.text.trim().isNotEmpty,
                            )) {
                              setState(() {
                                errorText = null;
                              });
                            }
                          },
                        ),
                      ),
                    );
                  }),
                ),

                if (errorText != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10, left: 10),
                    child: Text(
                      errorText!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),

                if (apiError != null)
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 10,
                      left: 10,
                      right: 10,
                    ),
                    child: Text(
                      apiError!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),

                SizedBox(height: size.height * 0.05),

                SizedBox(
                  width: double.infinity,
                  height: size.height * 0.06,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7A2D00),
                    ),
                    onPressed: isLoading ? null : verifyOtp,
                    child: isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.2,
                            ),
                          )
                        : Text(
                            "Confirm OTP",
                            style: TextStyle(
                              fontSize: size.width * 0.04,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),

                SizedBox(height: size.height * 0.02),

                Align(
                  alignment: Alignment.centerRight,
                  child: RichText(
                    text: TextSpan(
                      text: "Resend OTP ",
                      style: const TextStyle(color: Colors.black),
                      children: [
                        WidgetSpan(
                          child: GestureDetector(
                            onTap: isLoading ? null : resendOtp,
                            child: const Text(
                              "Click here",
                              style: TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),
                      ],
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
            child: Image.asset('assets/appIcon/footerlogo2.jpg', height: 30),
          ),
        ),
      ),
    );
  }
}
