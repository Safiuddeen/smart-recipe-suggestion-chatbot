class RecipeModel {
  final int id;
  final String recipeTitle;
  final String url;
  final String recordHealth;
  final int voteCount;
  final double rating;
  final String description;
  final String cuisine;
  final String course;
  final String diet;
  final String prepTime;
  final String cookTime;
  final String ingredients;
  final String instructions;
  final String author;
  final String tags;
  final String category;

  RecipeModel({
    required this.id,
    required this.recipeTitle,
    required this.url,
    required this.recordHealth,
    required this.voteCount,
    required this.rating,
    required this.description,
    required this.cuisine,
    required this.course,
    required this.diet,
    required this.prepTime,
    required this.cookTime,
    required this.ingredients,
    required this.instructions,
    required this.author,
    required this.tags,
    required this.category,
  });

  factory RecipeModel.fromJson(Map<String, dynamic> json) {
    return RecipeModel(
      id: json['id'] ?? 0,
      recipeTitle: (json['recipe_title'] ?? '').toString(),
      url: (json['url'] ?? '').toString(),
      recordHealth: (json['record_health'] ?? '').toString(),
      voteCount: json['vote_count'] ?? 0,
      rating: (json['rating'] ?? 0).toDouble(),
      description: (json['description'] ?? '').toString(),
      cuisine: (json['cuisine'] ?? '').toString(),
      course: (json['course'] ?? '').toString(),
      diet: (json['diet'] ?? '').toString(),
      prepTime: (json['prep_time'] ?? '').toString(),
      cookTime: (json['cook_time'] ?? '').toString(),
      ingredients: (json['ingredients'] ?? '').toString(),
      instructions: (json['instructions'] ?? '').toString(),
      author: (json['author'] ?? '').toString(),
      tags: (json['tags'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
    );
  }
}
