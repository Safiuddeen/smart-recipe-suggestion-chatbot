import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/recipe_model.dart';

class RecipeSearchService {
  /// FOR ANDROID EMULATOR:
  /// static const String baseUrl = "http://10.0.2.2:8000";

  /// FOR REAL DEVICE:
  // static const String baseUrl = "http://192.168.8.122:8000";
  // static const String baseUrl = "http://192.168.100.219:8000";
  static const String baseUrl = "http://172.20.10.2:8000";

  Future<List<RecipeModel>> searchRecipes(String query) async {
    final trimmed = query.trim();

    if (trimmed.isEmpty) {
      return [];
    }

    final uri = Uri.parse(
      "$baseUrl/recipes/search?query=${Uri.encodeComponent(trimmed)}",
    );

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => RecipeModel.fromJson(e)).toList();
    } else {
      throw Exception("Failed to search recipes: ${response.body}");
    }
  }
}
