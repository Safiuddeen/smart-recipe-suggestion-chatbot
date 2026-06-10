class AiFeedbackModel {
  final String aboutRecipe;
  final String suitableForYou;

  AiFeedbackModel({required this.aboutRecipe, required this.suitableForYou});

  factory AiFeedbackModel.fromJson(Map<String, dynamic> json) {
    return AiFeedbackModel(
      aboutRecipe: json['about_recipe']?.toString() ?? '',
      suitableForYou: json['suitable_for_you']?.toString() ?? '',
    );
  }
}
