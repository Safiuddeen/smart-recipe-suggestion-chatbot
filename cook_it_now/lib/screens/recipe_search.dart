import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/recipe_model.dart';
import '../services/account_service.dart';
import '../services/profile_service.dart';
import '../services/recipe_search_service.dart';
import '../services/session_service.dart';

class RecipeSearch extends StatefulWidget {
  const RecipeSearch({super.key});

  @override
  State<RecipeSearch> createState() => _RecipeSearchState();
}

class _RecipeSearchState extends State<RecipeSearch> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  final ProfileService _profileService = ProfileService();
  final AccountService _accountService = AccountService();
  final RecipeSearchService _recipeSearchService = RecipeSearchService();

  String _displayName = "";
  String _email = "";

  bool _isSigningOut = false;
  bool _isDeletingAccount = false;
  bool _isLoadingRecipes = false;

  List<RecipeModel> _recipes = [];
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserProfile();
  }

  Future<String?> _getCurrentEmail() async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null && currentUser.email != null) {
      await SessionService.saveEmail(currentUser.email!);
      return currentUser.email!;
    }

    return await SessionService.getEmail();
  }

  Future<void> _loadCurrentUserProfile() async {
    try {
      final email = await _getCurrentEmail();

      if (email == null || email.isEmpty) return;

      final data = await _profileService.getUserProfile(email);

      if (!mounted) return;

      setState(() {
        _displayName = (data['name'] ?? '').toString().trim().isNotEmpty
            ? data['name'].toString().trim()
            : "User";
        _email = (data['email'] ?? '').toString();
      });
    } catch (e) {
      final currentUser = FirebaseAuth.instance.currentUser;

      if (!mounted) return;

      setState(() {
        _displayName =
            (currentUser?.displayName != null &&
                currentUser!.displayName!.trim().isNotEmpty)
            ? currentUser.displayName!.trim()
            : "User";
        _email = currentUser?.email ?? "";
      });
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();

    setState(() {});

    _debounce = Timer(const Duration(milliseconds: 350), () async {
      final query = value.trim();

      if (query.isEmpty) {
        if (!mounted) return;
        setState(() {
          _recipes = [];
          _isLoadingRecipes = false;
        });
        return;
      }

      setState(() {
        _isLoadingRecipes = true;
      });

      try {
        final result = await _recipeSearchService.searchRecipes(query);

        if (!mounted) return;

        setState(() {
          _recipes = result;
          _isLoadingRecipes = false;
        });
      } catch (e) {
        if (!mounted) return;

        setState(() {
          _recipes = [];
          _isLoadingRecipes = false;
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Recipe search failed: $e")));
      }
    });
  }

  void _clearText() {
    _searchController.clear();
    setState(() {
      _recipes = [];
    });
    _searchFocusNode.unfocus();
    FocusScope.of(context).unfocus();
  }

  void _startNewChat() {
    context.go('/home', extra: "");
  }

  Future<void> _signOut() async {
    if (_isSigningOut) return;

    setState(() {
      _isSigningOut = true;
    });

    try {
      Navigator.pop(context);

      await GoogleSignIn().signOut();
      await FirebaseAuth.instance.signOut();
      await SessionService.clearSession();

      if (!mounted) return;
      context.go('/signin');
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Logout failed: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isSigningOut = false;
        });
      }
    }
  }

  Future<void> _showLogoutDialog() async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Sign Out"),
          content: const Text("Are you sure you want to sign out?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7A2D00),
              ),
              onPressed: () async {
                Navigator.pop(context);
                await _signOut();
              },
              child: const Text(
                "Sign Out",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteAccount() async {
    if (_isDeletingAccount) return;

    setState(() {
      _isDeletingAccount = true;
    });

    try {
      final email = await _getCurrentEmail();

      if (email == null || email.trim().isEmpty) {
        throw Exception("User email not found");
      }

      await _accountService.deleteAccount(email);

      try {
        await GoogleSignIn().signOut();
      } catch (_) {}

      try {
        await FirebaseAuth.instance.signOut();
      } catch (_) {}

      await SessionService.clearSession();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Account deleted successfully")),
      );

      context.go('/signin');
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Delete account failed: $e")));
    } finally {
      if (mounted) {
        setState(() {
          _isDeletingAccount = false;
        });
      }
    }
  }

  Future<void> _showDeleteAccountFirstDialog() async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Delete Account?"),
          content: const Text("Are you sure you want to delete your account?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("No"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.pop(context);
                _showDeleteAccountSecondDialog();
              },
              child: const Text(
                "Yes, Continue",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showDeleteAccountSecondDialog() async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Final Confirmation"),
          content: const Text(
            "This action is permanent. Your account, saved recipes, and chat history will be deleted permanently. Do you really want to continue?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                Navigator.pop(context);
                await _deleteAccount();
              },
              child: const Text(
                "Delete Permanently",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget menuButton({
    required String title,
    required String iconPath,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        color: const Color(0xFFEFE0D7),
        child: Row(
          children: [
            Image.asset(iconPath, width: 24, height: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(color: Color(0xFF7A2D00)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipeCard(RecipeModel recipe, Size screen) {
    return GestureDetector(
      onTap: () async {
        final result = await context.push(
          '/savedRecipeDetails', // ✅ IMPORTANT
          extra: {
            "recipe_id": recipe.id, // ✅ REQUIRED
            "recipe_title": recipe.recipeTitle,
            "url": recipe.url,
            "record_health": recipe.recordHealth,
            "vote_count": recipe.voteCount,
            "rating": recipe.rating,
            "description": recipe.description,
            "cuisine": recipe.cuisine,
            "course": recipe.course,
            "diet": recipe.diet,
            "prep_time": recipe.prepTime,
            "cook_time": recipe.cookTime,
            "ingredients": recipe.ingredients,
            "instructions": recipe.instructions,
            "author": recipe.author,
            "tags": recipe.tags,
            "category": recipe.category,
          },
        );

        // optional refresh
        if (result == true) {
          setState(() {});
        }
      },
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
              recipe.recipeTitle.isNotEmpty
                  ? recipe.recipeTitle
                  : "Untitled Recipe",
              style: const TextStyle(
                color: Color(0xFF7A2D00),
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Cuisine: ${recipe.cuisine.isNotEmpty ? recipe.cuisine : "-"}",
              style: const TextStyle(color: Color(0xFF7A2D00)),
            ),
            Text(
              "Diet: ${recipe.diet.isNotEmpty ? recipe.diet : "-"}",
              style: const TextStyle(color: Color(0xFF7A2D00)),
            ),
            Text(
              "Rating: ${recipe.rating.toStringAsFixed(5)}",
              style: const TextStyle(color: Color(0xFF7A2D00)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;

    return GestureDetector(
      onTap: () {
        _searchFocusNode.unfocus();
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

          endDrawer: Drawer(
            width: screen.width * 0.60,
            child: Container(
              color: const Color.fromARGB(255, 255, 255, 255),
              padding: const EdgeInsets.only(left: 15),
              child: Column(
                children: [
                  const SizedBox(height: 50),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/userProfile');
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFE0D7),
                        borderRadius: BorderRadius.circular(0),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Image.asset(
                            "assets/icons/user.png",
                            width: 32,
                            height: 32,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _displayName,
                                  style: const TextStyle(
                                    color: Color(0xFF7A2D00),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (_email.isNotEmpty)
                                  Text(
                                    _email,
                                    style: const TextStyle(
                                      color: Color(0xFF7A2D00),
                                      fontSize: 11,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  menuButton(
                    title: "New Chat",
                    iconPath: "assets/icons/new-message.png",
                    onTap: () {
                      Navigator.pop(context);
                      _startNewChat();
                    },
                  ),
                  const SizedBox(height: 10),
                  const Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: Color(0xFF7A2D00),
                          thickness: 1.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  menuButton(
                    title: "View Your\nchat History",
                    iconPath: "assets/icons/history.png",
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/history');
                    },
                  ),
                  const SizedBox(height: 10),
                  menuButton(
                    title: "View saved\nRecipes History",
                    iconPath: "assets/icons/history.png",
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/recipeChatHistory');
                    },
                  ),
                  const SizedBox(height: 10),
                  const Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: Color(0xFF7A2D00),
                          thickness: 1.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  menuButton(
                    title: _isDeletingAccount
                        ? "Deleting Account..."
                        : "Delete Account",
                    iconPath: "assets/icons/delete.png",
                    onTap: _isDeletingAccount
                        ? () {}
                        : () {
                            Navigator.pop(context);
                            _showDeleteAccountFirstDialog();
                          },
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: _isSigningOut ? null : _showLogoutDialog,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 10,
                      ),
                      color: const Color(0xFFEFE0D7),
                      child: Row(
                        children: [
                          Image.asset(
                            "assets/icons/logout.png",
                            width: 24,
                            height: 24,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _isSigningOut ? "Signing Out..." : "Sign Out",
                              style: const TextStyle(color: Color(0xFF7A2D00)),
                            ),
                          ),
                          if (_isSigningOut)
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Image.asset(
                      "assets/appIcon/footerlogo2.jpg",
                      height: 60,
                    ),
                  ),
                ],
              ),
            ),
          ),

          appBar: AppBar(
            backgroundColor: const Color(0xFFBCEAA9),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black87),
              onPressed: () => context.go('/home'),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: GestureDetector(
                  onTap: () {
                    _searchFocusNode.unfocus();
                    FocusScope.of(context).unfocus();
                    _scaffoldKey.currentState!.openEndDrawer();
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/appIcon/footerlogo.jpg',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.person, color: Colors.black87),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: screen.width * 0.06),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Find Your Perfect Recipe",
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
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            onChanged: _onSearchChanged,
                            decoration: const InputDecoration(
                              hintText: "Search recipe name or tags",
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        if (_searchController.text.isNotEmpty)
                          GestureDetector(
                            onTap: _clearText,
                            child: const Icon(
                              Icons.close,
                              color: Colors.black54,
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  Expanded(
                    child: _isLoadingRecipes
                        ? const Center(child: CircularProgressIndicator())
                        : _searchController.text.trim().isNotEmpty &&
                              _recipes.isEmpty
                        ? const Center(
                            child: Text(
                              "No recipes found",
                              style: TextStyle(color: Color(0xFF7A2D00)),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _recipes.length,
                            itemBuilder: (context, index) {
                              return _buildRecipeCard(_recipes[index], screen);
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
