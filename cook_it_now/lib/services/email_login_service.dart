import 'dart:convert';
import 'package:http/http.dart' as http;

class EmailLoginService {
  // ANDROID EMULATOR
  // static const String baseUrl = "http://10.0.2.2:8000/auth";

  // REAL DEVICE
  //static const String baseUrl = "http://192.168.8.122:8000/auth";
  //static const String baseUrl = "http://192.168.100.219:8000";
  static const String baseUrl = "http://172.20.10.2:8000";

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/email/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'message': data['detail'] ?? 'Username or password incorrect',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Server connection error'};
    }
  }
}
