import 'dart:convert';
import 'package:http/http.dart' as http;

class ProfileService {
  // Android Emulator:
  // static const String baseUrl = "http://10.0.2.2:8000";

  // Real device:
  // static const String baseUrl = "http://192.168.8.122:8000";
  // static const String baseUrl = "http://192.168.100.219:8000";
  static const String baseUrl = "http://172.20.10.2:8000";

  Future<Map<String, dynamic>> getUserProfile(String email) async {
    final response = await http.get(
      Uri.parse('$baseUrl/profile/$email'),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load profile: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> updateUserProfile({
    required String email,
    required String name,
    required String contactNumber,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/profile/user/$email'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"name": name, "contact_number": contactNumber}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update profile: ${response.body}');
    }
  }
}
