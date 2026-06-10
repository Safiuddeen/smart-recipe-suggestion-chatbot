import 'dart:convert';
import 'package:http/http.dart' as http;

class AccountService {
  /// FOR ANDROID EMULATOR:
  /// static const String baseUrl = "http://10.0.2.2:8000";

  /// FOR REAL DEVICE:
  // static const String baseUrl = "http://192.168.8.122:8000";
  // static const String baseUrl = "http://192.168.100.219:8000";
  static const String baseUrl = "http://172.20.10.2:8000";

  Future<Map<String, dynamic>> deleteAccount(String email) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/account/delete'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['detail'] ?? 'Failed to delete account');
    }
  }
}
