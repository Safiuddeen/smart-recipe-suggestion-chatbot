class RecipeItem {
  final int? id;
  final String recipeTitle;
  final String? url;
  final String? recordHealth;
  final int? voteCount;
  final double? rating;
  final String? description;
  final String? cuisine;
  final String? course;
  final String? diet;
  final String? prepTime;
  final String? cookTime;
  final String? ingredients;
  final String? instructions;
  final String? author;
  final String? tags;
  final String? category;
  final int? matchCount;
  final List<String> matchedIngredients;

  RecipeItem({
    this.id,
    required this.recipeTitle,
    this.url,
    this.recordHealth,
    this.voteCount,
    this.rating,
    this.description,
    this.cuisine,
    this.course,
    this.diet,
    this.prepTime,
    this.cookTime,
    this.ingredients,
    this.instructions,
    this.author,
    this.tags,
    this.category,
    this.matchCount,
    required this.matchedIngredients,
  });

  factory RecipeItem.fromJson(Map<String, dynamic> json) {
    return RecipeItem(
      id: json["id"] is int ? json["id"] : int.tryParse("${json["id"] ?? ""}"),
      recipeTitle: json["recipe_title"] ?? "",
      url: json["url"],
      recordHealth: json["record_health"],
      voteCount: json["vote_count"] is int
          ? json["vote_count"]
          : int.tryParse("${json["vote_count"] ?? ""}"),
      rating: json["rating"] == null
          ? null
          : double.tryParse(json["rating"].toString()),
      description: json["description"],
      cuisine: json["cuisine"],
      course: json["course"],
      diet: json["diet"],
      prepTime: json["prep_time"],
      cookTime: json["cook_time"],
      ingredients: json["ingredients"],
      instructions: json["instructions"],
      author: json["author"],
      tags: json["tags"],
      category: json["category"],
      matchCount: json["match_count"] is int
          ? json["match_count"]
          : int.tryParse("${json["match_count"] ?? ""}"),
      matchedIngredients: json["matched_ingredients"] == null
          ? []
          : List<String>.from(json["matched_ingredients"]),
    );
  }
}

class ChatResponseModel {
  final String intent;
  final String response;
  final List<String> ingredients;
  final List<RecipeItem> recipes;

  ChatResponseModel({
    required this.intent,
    required this.response,
    required this.ingredients,
    required this.recipes,
  });

  factory ChatResponseModel.fromJson(Map<String, dynamic> json) {
    return ChatResponseModel(
      intent: json["intent"] ?? "",
      response: json["response"] ?? "",
      ingredients: json["ingredients"] == null
          ? []
          : List<String>.from(json["ingredients"]),
      recipes: json["recipes"] == null
          ? []
          : (json["recipes"] as List)
                .map((item) => RecipeItem.fromJson(item))
                .toList(),
    );
  }
}
