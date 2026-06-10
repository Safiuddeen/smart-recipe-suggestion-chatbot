import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/saved_recipe_service.dart';
import '../services/session_service.dart';

class RecipeChatHistory extends StatefulWidget {
  const RecipeChatHistory({super.key});

  @override
  State<RecipeChatHistory> createState() => _RecipeChatHistoryState();
}

class _RecipeChatHistoryState extends State<RecipeChatHistory> {
  final TextEditingController searchController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final SavedRecipeService _savedRecipeService = SavedRecipeService();

  List<dynamic> _allRecipes = [];
  List<dynamic> _filteredRecipes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    searchController.addListener(_filterList);
    _loadSavedRecipes();
  }

  Future<String?> _getCurrentEmail() async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null && currentUser.email != null) {
      await SessionService.saveEmail(currentUser.email!);
      return currentUser.email!;
    }

    return await SessionService.getEmail();
  }

  Future<void> _loadSavedRecipes() async {
    try {
      final email = await _getCurrentEmail();
      if (email == null || email.isEmpty) {
        throw Exception("No logged-in user found");
      }

      final recipes = await _savedRecipeService.getSavedRecipes(email);

      if (!mounted) return;

      setState(() {
        _allRecipes = recipes;
        _filteredRecipes = recipes;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load saved recipes: $e")),
      );
    }
  }

  void _filterList() {
    final query = searchController.text.trim().toLowerCase();

    setState(() {
      _filteredRecipes = _allRecipes.where((item) {
        final title = (item["recipe_title"] ?? "").toString().toLowerCase();
        return title.contains(query);
      }).toList();
    });
  }

  int? _getRecipeId(dynamic item) {
    final value = item["recipe_id"];
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? "");
  }

  void _removeRecipeFromList(dynamic item) {
    final removedId = _getRecipeId(item);

    setState(() {
      _allRecipes.removeWhere((recipe) {
        final id = _getRecipeId(recipe);
        return id != null && id == removedId;
      });
    });

    _filterList();
  }

  Future<void> _openRecipeDetails(dynamic item) async {
    final result = await context.push('/savedRecipeDetails', extra: item);

    if (!mounted) return;

    if (result == true) {
      _removeRecipeFromList(item);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Recipe removed from saved list")),
      );
    }
  }

  Widget _recipeCard(dynamic item) {
    return GestureDetector(
      onTap: () => _openRecipeDetails(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item["recipe_title"] ?? "",
              style: const TextStyle(
                color: Color(0xFF7A2D00),
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Cuisine: ${item["cuisine"] ?? "-"}",
              style: const TextStyle(color: Color(0xFF7A2D00)),
            ),
            Text(
              "Diet: ${item["diet"] ?? "-"}",
              style: const TextStyle(color: Color(0xFF7A2D00)),
            ),
            Text(
              "Rating: ${(item["rating"] ?? "-").toString()}",
              style: const TextStyle(color: Color(0xFF7A2D00)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) {
            context.go('/home');
          }
        },
        child: Scaffold(
          key: _scaffoldKey,
          backgroundColor: const Color(0xFFBCEAA9),
          appBar: AppBar(
            backgroundColor: const Color(0xFFBCEAA9),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black87),
              onPressed: () => context.go('/home'),
            ),
          ),
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: screen.width * 0.06),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Pick or Search a saved recipe",
                    style: TextStyle(
                      fontSize: screen.width * 0.05,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown[800],
                    ),
                  ),
                  SizedBox(height: screen.height * 0.025),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: screen.width * 0.04,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: searchController,
                            decoration: const InputDecoration(
                              hintText: "Search saved recipes",
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            searchController.clear();
                          },
                          child: const Icon(Icons.close, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _filteredRecipes.isEmpty
                        ? const Center(
                            child: Text(
                              "No saved recipes found",
                              style: TextStyle(color: Color(0xFF7A2D00)),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _filteredRecipes.length,
                            itemBuilder: (context, index) {
                              return _recipeCard(_filteredRecipes[index]);
                            },
                          ),
                  ),
                ],
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
        ),
      ),
    );
  }
}
