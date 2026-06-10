import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/ai_feedback_service.dart';
import '../services/nlp_service.dart';
import '../services/saved_recipe_service.dart';
import '../services/session_service.dart';

class SavedRecipeDetailsPage extends StatefulWidget {
  final Map<String, dynamic> recipe;

  const SavedRecipeDetailsPage({super.key, required this.recipe});

  @override
  State<SavedRecipeDetailsPage> createState() => _SavedRecipeDetailsPageState();
}

class _SavedRecipeDetailsPageState extends State<SavedRecipeDetailsPage> {
  final SavedRecipeService _savedRecipeService = SavedRecipeService();
  final AiFeedbackService _aiFeedbackService = AiFeedbackService();

  bool _isSaved = false;
  bool _isSaving = false;
  bool _isCheckingSaved = true;

  bool _isGeneratingAi = false;
  String? _aiError;
  String? _aboutRecipe;
  String? _suitableForYou;

  Map<String, dynamic> get recipe => widget.recipe;

  int? get _recipeId {
    final value = recipe["recipe_id"];
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? "");
  }

  String? get _recipeUrl => recipe["url"]?.toString();

  @override
  void initState() {
    super.initState();
    _checkIfSaved();
  }

  Future<String?> _getCurrentEmail() async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null && currentUser.email != null) {
      await SessionService.saveEmail(currentUser.email!);
      return currentUser.email!;
    }

    return await SessionService.getEmail();
  }

  Future<void> _checkIfSaved() async {
    try {
      final email = await _getCurrentEmail();

      if (email == null || email.isEmpty || _recipeId == null) {
        if (!mounted) return;
        setState(() {
          _isSaved = false;
          _isCheckingSaved = false;
        });
        return;
      }

      final saved = await _savedRecipeService.isRecipeSaved(email, _recipeId!);

      if (!mounted) return;
      setState(() {
        _isSaved = saved;
        _isCheckingSaved = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSaved = false;
        _isCheckingSaved = false;
      });
    }
  }

  Future<void> _toggleSaveRecipe() async {
    if (_isSaving || _recipeId == null) return;

    final email = await _getCurrentEmail();

    if (email == null || email.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User email not found. Please login again.'),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      if (_isSaved) {
        await _savedRecipeService.removeRecipe(email, _recipeId!);

        if (!mounted) return;

        setState(() {
          _isSaved = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recipe removed successfully')),
        );

        context.pop(true);
        return;
      } else {
        await _savedRecipeService.saveRecipe(email, _recipeId!);

        if (!mounted) return;
        setState(() {
          _isSaved = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recipe saved successfully')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _generateAiFeedback() async {
    if (_isGeneratingAi) return;

    final email = await _getCurrentEmail();

    if (email == null || email.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User email not found. Please login again.'),
        ),
      );
      return;
    }

    setState(() {
      _isGeneratingAi = true;
      _aiError = null;
      _aboutRecipe = null;
      _suitableForYou = null;
    });

    try {
      final result = await _aiFeedbackService.getAiFeedback(
        userEmail: email,
        recipe: {
          "recipe_id": _recipeId,
          "recipe_title": recipe["recipe_title"]?.toString() ?? "",
          "record_health": recipe["record_health"]?.toString() ?? "",
          "rating": recipe["rating"],
          "description": recipe["description"]?.toString() ?? "",
          "cuisine": recipe["cuisine"]?.toString() ?? "",
          "diet": recipe["diet"]?.toString() ?? "",
          "prep_time": recipe["prep_time"]?.toString() ?? "",
          "cook_time": recipe["cook_time"]?.toString() ?? "",
          "ingredients": recipe["ingredients"]?.toString() ?? "",
          "instructions": recipe["instructions"]?.toString() ?? "",
        },
      );

      if (!mounted) return;
      setState(() {
        _aboutRecipe = result.aboutRecipe;
        _suitableForYou = result.suitableForYou;
      });
    } on AiFeedbackIncompleteProfileException catch (_) {
      if (!mounted) return;

      final goFill = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text("Health Profile Required"),
          content: const Text(
            "Please fill your health information first to generate AI feedback.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text("Let's Fill"),
            ),
          ],
        ),
      );

      if (goFill == true && mounted) {
        context.go('/healthProfile');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _aiError = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingAi = false;
        });
      }
    }
  }

  Widget _detailTile(String title, String? value) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            color: Color(0xFF7A2D00),
            fontSize: 14,
            height: 1.6,
          ),
          children: [
            TextSpan(
              text: "$title: ",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(
              text: (value == null || value.trim().isEmpty) ? "-" : value,
            ),
          ],
        ),
      ),
    );
  }

  Widget _imageSection() {
    if (_recipeUrl == null || _recipeUrl!.trim().isEmpty) {
      return _emptyImage();
    }

    return FutureBuilder<String?>(
      future: NlpService.getRecipeImage(_recipeUrl!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _loadingImage();
        }

        final imageUrl = snapshot.data;

        if (imageUrl == null || imageUrl.isEmpty) {
          return _emptyImage();
        }

        return Container(
          width: double.infinity,
          height: 300,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: 300,
              filterQuality: FilterQuality.high,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return _loadingImage();
              },
              errorBuilder: (context, error, stackTrace) {
                return _emptyImage();
              },
            ),
          ),
        );
      },
    );
  }

  Widget _loadingImage() {
    return Container(
      width: double.infinity,
      height: 300,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _emptyImage() {
    return Container(
      width: double.infinity,
      height: 300,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: Icon(Icons.restaurant, size: 70, color: Color(0xFF7A2D00)),
      ),
    );
  }

  Widget _buildAiSection() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF5E0),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "AI Feedback",
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
              onPressed: _isGeneratingAi ? null : _generateAiFeedback,
              icon: _isGeneratingAi
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
                _isGeneratingAi ? "Generating..." : "Generate AI Feedback",
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7A2D00),
                foregroundColor: Colors.white,
              ),
            ),
          ),
          if (_aiError != null) ...[
            const SizedBox(height: 10),
            Text(
              _aiError!,
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          ],
          if (_aboutRecipe != null) ...[
            const SizedBox(height: 12),
            _detailTile("About Recipe", _aboutRecipe),
          ],
          if (_suitableForYou != null) ...[
            _detailTile("Suitable for You", _suitableForYou),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFBCEAA9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFBCEAA9),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.pop(false),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              onPressed: (_isSaving || _isCheckingSaved || _recipeId == null)
                  ? null
                  : _toggleSaveRecipe,
              icon: _isCheckingSaved
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      _isSaved ? Icons.bookmark : Icons.bookmark_border,
                      color: const Color(0xFF7A2D00),
                    ),
              tooltip: _isSaved ? "Remove saved recipe" : "Save recipe",
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFD8E9C8),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recipe["recipe_title"]?.toString() ?? "",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF7A2D00),
                  ),
                ),
                const SizedBox(height: 12),
                _imageSection(),
                const SizedBox(height: 12),
                _detailTile(
                  "Record Health",
                  recipe["record_health"]?.toString(),
                ),
                _detailTile("Rating", recipe["rating"]?.toString()),
                _detailTile("Description", recipe["description"]?.toString()),
                _detailTile("Cuisine", recipe["cuisine"]?.toString()),
                _detailTile("Diet", recipe["diet"]?.toString()),
                _detailTile("Prep Time", recipe["prep_time"]?.toString()),
                _detailTile("Cook Time", recipe["cook_time"]?.toString()),
                _detailTile("Ingredients", recipe["ingredients"]?.toString()),
                _detailTile("Instructions", recipe["instructions"]?.toString()),
                _buildAiSection(),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        height: 40,
        width: double.infinity,
        color: Colors.white,
        padding: const EdgeInsets.only(right: 16),
        alignment: Alignment.centerRight,
        child: Image.asset(
          'assets/appIcon/footerlogo2.jpg',
          height: 30,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
