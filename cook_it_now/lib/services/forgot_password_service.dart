import 'dart:convert';
import 'package:http/http.dart' as http;

class ForgotPasswordService {
  // ANDROID EMULATOR
  // static const String baseUrl = "http://10.0.2.2:8000";

  // REAL DEVICE
  //static const String baseUrl = "http://192.168.8.122:8000";
  static const String baseUrl = "http://192.168.100.219:8000";

  static Future<Map<String, dynamic>> requestResetOtp({
    required String email,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/forgot-password/request-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"email": email}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {"success": true, "data": data};
      } else {
        return {
          "success": false,
          "message": data["detail"] ?? "Failed to send OTP",
        };
      }
    } catch (e) {
      return {"success": false, "message": "Server connection error"};
    }
  }

  static Future<Map<String, dynamic>> resendResetOtp({
    required String email,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/forgot-password/resend-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"email": email}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {"success": true, "data": data};
      } else {
        return {
          "success": false,
          "message": data["detail"] ?? "Failed to resend OTP",
        };
      }
    } catch (e) {
      return {"success": false, "message": "Server connection error"};
    }
  }

  static Future<Map<String, dynamic>> verifyResetOtp({
    required String email,
    required String otpCode,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/forgot-password/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"email": email, "otp_code": otpCode}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {"success": true, "data": data};
      } else {
        return {
          "success": false,
          "message": data["detail"] ?? "OTP verification failed",
        };
      }
    } catch (e) {
      return {"success": false, "message": "Server connection error"};
    }
  }

  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/forgot-password/reset'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "email": email,
          "new_password": newPassword,
          "confirm_password": confirmPassword,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {"success": true, "data": data};
      } else {
        return {
          "success": false,
          "message": data["detail"] ?? "Password update failed",
        };
      }
    } catch (e) {
      return {"success": false, "message": "Server connection error"};
    }
  }
}
