import 'dart:convert';
import 'package:http/http.dart' as http;

class SavedRecipeService {
  // static const String baseUrl = "http://192.168.8.122:8000";
  // static const String baseUrl = "http://192.168.100.219:8000";
  static const String baseUrl = "http://172.20.10.2:8000";

  Future<void> saveRecipe(String email, int recipeId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/saved-recipes/save/$email/$recipeId'),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to save recipe: ${response.body}');
    }
  }

  Future<void> removeRecipe(String email, int recipeId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/saved-recipes/remove/$email/$recipeId'),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to remove recipe: ${response.body}');
    }
  }

  Future<bool> isRecipeSaved(String email, int recipeId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/saved-recipes/check/$email/$recipeId'),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["is_saved"] == true;
    } else {
      throw Exception('Failed to check recipe save: ${response.body}');
    }
  }

  Future<List<dynamic>> getSavedRecipes(String email) async {
    final response = await http.get(
      Uri.parse('$baseUrl/saved-recipes/list/$email'),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get saved recipes: ${response.body}');
    }
  }
}
