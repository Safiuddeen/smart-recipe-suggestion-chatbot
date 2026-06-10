import 'dart:convert';
import 'package:http/http.dart' as http;

class EmailAuthService {
  // Android emulator
  // static const String baseUrl = "http://10.0.2.2:8000/auth";

  // For real device, replace with your PC IP
  // static const String baseUrl = "http://192.168.8.122:8000/auth";
  // static const String baseUrl = "http://192.168.100.219:8000";
  static const String baseUrl = "http://172.20.10.2:8000";

  static Future<Map<String, dynamic>> requestSignupOtp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/email/signup/request-otp"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"name": name, "email": email, "password": password}),
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

  static Future<Map<String, dynamic>> verifySignupOtp({
    required String email,
    required String otpCode,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/email/signup/verify-otp"),
        headers: {"Content-Type": "application/json"},
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

  static Future<Map<String, dynamic>> resendSignupOtp({
    required String email,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/email/signup/resend-otp"),
        headers: {"Content-Type": "application/json"},
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
}
