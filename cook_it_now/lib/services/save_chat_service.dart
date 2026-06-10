import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatSessionService {
  // static const String baseUrl = "http://192.168.8.122:8000";
  // static const String baseUrl = "http://192.168.100.219:8000";
  static const String baseUrl = "http://172.20.10.2:8000";

  Future<Map<String, dynamic>> saveChatSession({
    required String email,
    required List<Map<String, dynamic>> messages,
    int? sessionId,
    String? title,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/chat-sessions/save'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "session_id": sessionId,
        "title": title,
        "messages": messages,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to save chat session: ${response.body}');
    }
  }

  Future<List<dynamic>> getChatSessions(String email) async {
    final response = await http.get(
      Uri.parse('$baseUrl/chat-sessions/list/$email'),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load chat sessions: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getOneChatSession(
    String email,
    int sessionId,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/chat-sessions/one/$email/$sessionId'),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load chat session: ${response.body}');
    }
  }

  Future<void> deleteChatSession(String email, int sessionId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/chat-sessions/delete/$email/$sessionId'),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete chat session: ${response.body}');
    }
  }
}
