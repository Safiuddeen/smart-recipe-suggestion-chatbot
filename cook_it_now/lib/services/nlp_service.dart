import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chat_response_model.dart';

class NlpService {
  // Emulator:
  // static const String baseUrl = "http://10.0.2.2:8000";

  // Real device:
  // static const String baseUrl = "http://192.168.8.122:8000";
  // static const String baseUrl = "http://192.168.100.219:8000";
  static const String baseUrl = "http://172.20.10.2:8000";

  static Future<ChatResponseModel> sendMessage(String text) async {
    final response = await http.post(
      Uri.parse('$baseUrl/nlp/chat'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"text": text, "session_id": "chat_001"}),
    );

    if (response.statusCode == 200) {
      return ChatResponseModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("Failed to load chatbot response");
    }
  }

  static Future<String?> getRecipeImage(String url) async {
    final response = await http.get(
      Uri.parse('$baseUrl/nlp/recipe-image?url=${Uri.encodeComponent(url)}'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["image_url"];
    } else {
      return null;
    }
  }
}
