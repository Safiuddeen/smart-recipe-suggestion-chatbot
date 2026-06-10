import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/ai_feedback_model.dart';
import '../services/ai_feedback_service.dart';

class AiFeedbackSection extends StatefulWidget {
  final Map<String, dynamic> recipeData;
  final Future<String?> Function() getCurrentEmail;

  const AiFeedbackSection({
    super.key,
    required this.recipeData,
    required this.getCurrentEmail,
  });

  @override
  State<AiFeedbackSection> createState() => _AiFeedbackSectionState();
}

class _AiFeedbackSectionState extends State<AiFeedbackSection> {
  final AiFeedbackService _aiFeedbackService = AiFeedbackService();

  bool _isLoading = false;
  String? _error;
  AiFeedbackModel? _feedback;

  String _beautifyFieldName(String field) {
    switch (field) {
      case "age":
        return "Age";
      case "gender":
        return "Gender";
      case "height_cm":
        return "Height";
      case "weight_kg":
        return "Weight";
      case "bmr":
        return "BMR";
      default:
        return field;
    }
  }

  Future<void> _showIncompleteProfileDialog(List<String> missingFields) async {
    final prettyFields = missingFields.map(_beautifyFieldName).join(", ");

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Profile Information Required"),
          content: Text(
            "Please fill your health information first to generate AI feedback.\n\nMissing fields:\n$prettyFields",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.go('/healthProfile');
              },
              child: const Text("Let's Fill"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _generateFeedback() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _feedback = null;
    });

    try {
      final email = await widget.getCurrentEmail();

      if (email == null || email.isEmpty) {
        throw Exception("User email not found. Please login again.");
      }

      final result = await _aiFeedbackService.getAiFeedback(
        userEmail: email,
        recipe: widget.recipeData,
      );

      if (!mounted) return;
      setState(() {
        _feedback = result;
      });
    } on AiFeedbackIncompleteProfileException catch (e) {
      if (!mounted) return;
      setState(() {
        _feedback = null;
        _error = null;
      });
      await _showIncompleteProfileDialog(e.missingFields);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _feedback = null;
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _sectionCard({required String title, required String content}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF7A2D00),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content.trim().isEmpty ? "-" : content,
            style: const TextStyle(
              color: Color(0xFF7A2D00),
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF5E0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFB7D7A8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "AI Recipe Feedback",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF7A2D00),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _generateFeedback,
              icon: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(
                _isLoading ? "Generating..." : "Generate AI Feedback",
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7A2D00),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
            ),
          if (_feedback != null) ...[
            _sectionCard(
              title: "About Recipe",
              content: _feedback!.aboutRecipe,
            ),
            _sectionCard(
              title: "Suitable for You",
              content: _feedback!.suitableForYou,
            ),
          ],
        ],
      ),
    );
  }
}
