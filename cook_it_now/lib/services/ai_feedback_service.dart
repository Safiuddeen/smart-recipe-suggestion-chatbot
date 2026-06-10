import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ai_feedback_model.dart';

class AiFeedbackIncompleteProfileException implements Exception {
  final String message;
  final List<String> missingFields;

  AiFeedbackIncompleteProfileException({
    required this.message,
    required this.missingFields,
  });
}

class AiFeedbackService {
  // ANDROID EMULATOR
  // static const String baseUrl = "http://10.0.2.2:8000";

  // REAL DEVICE
  // static const String baseUrl = "http://192.168.8.122:8000";
  // static const String baseUrl = "http://192.168.100.219:8000";
  static const String baseUrl = "http://172.20.10.2:8000";

  Future<AiFeedbackModel> getAiFeedback({
    required String userEmail,
    required Map<String, dynamic> recipe,
  }) async {
    final body = {
      "user_email": userEmail,
      "recipe_id": recipe["recipe_id"] ?? recipe["id"],
      "recipe_title": recipe["recipe_title"] ?? "",
      "description": recipe["description"] ?? "",
      "ingredients": recipe["ingredients"] ?? "",
      "instructions": recipe["instructions"] ?? "",
      "cuisine": recipe["cuisine"] ?? "",
      "diet": recipe["diet"] ?? "",
      "prep_time": recipe["prep_time"] ?? "",
      "cook_time": recipe["cook_time"] ?? "",
      "record_health": recipe["record_health"] ?? "",
      "rating": recipe["rating"],
    };

    final response = await http.post(
      Uri.parse("$baseUrl/ai/recipe-feedback"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    final responseData = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return AiFeedbackModel.fromJson(responseData);
    }

    if (response.statusCode == 400 &&
        responseData["detail"] == "PROFILE_INCOMPLETE") {
      throw AiFeedbackIncompleteProfileException(
        message:
            responseData["message"]?.toString() ??
            "Please fill your health information first.",
        missingFields: (responseData["missing_fields"] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
      );
    }

    throw Exception("Failed to load AI feedback: ${response.body}");
  }
}
