import 'dart:convert';
import 'package:http/http.dart' as http;

class HealthProfileService {
  // Android Emulator:
  // static const String baseUrl = "http://10.0.2.2:8000";

  // Real device:
  //static const String baseUrl = "http://192.168.8.122:8000";
  // static const String baseUrl = "http://192.168.100.219:8000";
  static const String baseUrl = "http://172.20.10.2:8000";

  Future<Map<String, dynamic>> getHealthProfile(String email) async {
    final response = await http.get(
      Uri.parse('$baseUrl/profile/health/$email'),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 404) {
      return {
        "email": email,
        "age": null,
        "gender": null,
        "height_cm": null,
        "weight_kg": null,
        "bmr": null,
        "diabetes": false,
        "high_blood_pressure": false,
        "cholesterol": false,
        "kidney_issues": false,
        "is_profile_completed": false,
      };
    } else {
      throw Exception('Failed to load health profile: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> updateHealthProfile({
    required String email,
    required int age,
    required String gender,
    required double heightCm,
    required double weightKg,
    required bool diabetes,
    required bool highBloodPressure,
    required bool cholesterol,
    required bool kidneyIssues,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/profile/health'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "age": age,
        "gender": gender,
        "height_cm": heightCm,
        "weight_kg": weightKg,
        "diabetes": diabetes,
        "high_blood_pressure": highBloodPressure,
        "cholesterol": cholesterol,
        "kidney_issues": kidneyIssues,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update health profile: ${response.body}');
    }
  }
}
