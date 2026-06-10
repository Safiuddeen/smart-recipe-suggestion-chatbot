import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/chat_response_model.dart';
import '../services/save_chat_service.dart';
import '../services/nlp_service.dart';
import '../services/profile_service.dart';
import '../services/session_service.dart';

class ChatPage extends StatefulWidget {
  final String initialMessage;
  final int? sessionId;
  final List<Map<String, dynamic>>? existingMessages;

  const ChatPage({
    super.key,
    required this.initialMessage,
    this.sessionId,
    this.existingMessages,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _ingredientController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();

  final ProfileService _profileService = ProfileService();
  final ChatSessionService _chatSessionService = ChatSessionService();

  final List<Map<String, dynamic>> _messages = [];

  bool _isLoading = false;
  bool _isSigningOut = false;
  bool _hasSentInitialMessage = false;

  String _displayName = "User";
  String _email = "";
  int? _sessionId;

  @override
  void initState() {
    super.initState();

    _sessionId = widget.sessionId;

    if (widget.existingMessages != null &&
        widget.existingMessages!.isNotEmpty) {
      _messages.addAll(widget.existingMessages!);
    }

    _loadCurrentUserProfile();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _messageFocusNode.unfocus();
      FocusScope.of(context).unfocus();

      _sendInitialMessageIfNeeded();
      _scrollToBottom();
    });
  }

  void _sendInitialMessageIfNeeded() {
    if (_hasSentInitialMessage) return;
    if (_messages.isNotEmpty) return;

    final text = widget.initialMessage.trim();
    if (text.isEmpty) return;

    _hasSentInitialMessage = true;
    _sendMessage(text);
  }

  @override
  void dispose() {
    _ingredientController.dispose();
    _scrollController.dispose();
    _messageFocusNode.dispose();
    super.dispose();
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
    } catch (_) {}
  }

  String _extractTitle() {
    for (final item in _messages) {
      if (item["type"] == "user") {
        final text = (item["text"] ?? "").toString().trim();
        if (text.isNotEmpty) {
          return text.length > 60 ? text.substring(0, 60) : text;
        }
      }
    }
    return "New Chat";
  }

  Future<void> _saveWholeChat() async {
    final email = await _getCurrentEmail();
    if (email == null || email.isEmpty) return;

    final result = await _chatSessionService.saveChatSession(
      email: email,
      messages: _messages,
      sessionId: _sessionId,
      title: _extractTitle(),
    );

    _sessionId = result["session_id"];
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add({"type": "user", "text": text});
      _isLoading = true;
    });

    _ingredientController.clear();
    _messageFocusNode.unfocus();
    FocusScope.of(context).unfocus();
    _scrollToBottom();

    try {
      final ChatResponseModel result = await NlpService.sendMessage(text);

      if (!mounted) return;

      final botMessage = {
        "type": "bot",
        "text": result.response,
        "intent": result.intent,
        "ingredients": result.ingredients,
        "recipes": result.recipes
            .map(
              (recipe) => {
                "id": recipe.id,
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
                "matched_ingredients": recipe.matchedIngredients,
              },
            )
            .toList(),
      };

      setState(() {
        _messages.add(botMessage);
      });

      await _saveWholeChat();
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _messages.add({
          "type": "bot",
          "text": "Failed to connect to backend.",
          "intent": "error",
          "ingredients": <String>[],
          "recipes": <Map<String, dynamic>>[],
        });
      });

      await _saveWholeChat();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      _scrollToBottom();
    }
  }

  void _submitMessage() {
    final text = _ingredientController.text.trim();
    if (text.isEmpty) return;

    _messageFocusNode.unfocus();
    FocusScope.of(context).unfocus();
    _sendMessage(text);
  }

  void _startNewChat() {
    context.go('/home', extra: "");
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 300,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
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

  Widget _userBubble(String text) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10, left: 50),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF7A2D00),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 15),
        ),
      ),
    );
  }

  Widget _botBubble({
    required String text,
    required List<String> ingredients,
    required List<dynamic> recipes,
  }) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14, right: 30),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFEFE0D7),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: const TextStyle(color: Color(0xFF7A2D00), fontSize: 15),
            ),
            if (ingredients.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                "Ingredients: ${ingredients.join(", ")}",
                style: const TextStyle(color: Color(0xFF8B5A3C), fontSize: 13),
              ),
            ],
            if (recipes.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...recipes.map((recipe) => _recipeCard(recipe)).toList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _recipeCard(dynamic recipe) {
    return GestureDetector(
      onTap: () {
        _messageFocusNode.unfocus();
        FocusScope.of(context).unfocus();

        if (recipe is RecipeItem) {
          context.push('/recipeDetails', extra: recipe);
        } else {
          context.push(
            '/savedRecipeDetails',
            extra: {
              "recipe_id": recipe["id"],
              "recipe_title": recipe["recipe_title"],
              "url": recipe["url"],
              "record_health": recipe["record_health"],
              "rating": recipe["rating"],
              "description": recipe["description"],
              "cuisine": recipe["cuisine"],
              "diet": recipe["diet"],
              "prep_time": recipe["prep_time"],
              "cook_time": recipe["cook_time"],
              "ingredients": recipe["ingredients"],
              "instructions": recipe["instructions"],
            },
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Recipe: ${recipe is RecipeItem ? recipe.recipeTitle : (recipe["recipe_title"] ?? "-")}",
            ),
            Text(
              "Rating: ${recipe is RecipeItem ? (recipe.rating?.toString() ?? "-") : ((recipe["rating"] ?? "-").toString())}",
            ),
            Text(
              "Diet: ${recipe is RecipeItem ? (recipe.diet ?? "-") : (recipe["diet"] ?? "-")}",
            ),
            if (recipe is RecipeItem) ...[
              Text("Diet: ${recipe.diet ?? "-"}"),
              Text("Ingredients: ${recipe.ingredients ?? "-"}"),
              Text(
                "Matched: ${recipe.matchedIngredients.isEmpty ? "-" : recipe.matchedIngredients.join(", ")}",
              ),
            ],
            const SizedBox(height: 8),
            const Align(
              alignment: Alignment.centerRight,
              child: Text(
                "Tap to view full details",
                style: TextStyle(
                  color: Color(0xFF7A2D00),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
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

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;

    return GestureDetector(
      onTap: () {
        _messageFocusNode.unfocus();
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        key: _scaffoldKey,
        resizeToAvoidBottomInset: true,
        backgroundColor: const Color(0xFFBCEAA9),
        endDrawer: Drawer(
          width: screen.width * 0.60,
          child: Container(
            color: Colors.white,
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
                      child: Divider(color: Color(0xFF7A2D00), thickness: 1.5),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                menuButton(
                  title: "View Your\nchatHistory",
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
                      child: Divider(color: Color(0xFF7A2D00), thickness: 1.5),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                menuButton(
                  title: "Delete Account",
                  iconPath: "assets/icons/delete.png",
                  onTap: () {},
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
            onPressed: () {
              _messageFocusNode.unfocus();
              FocusScope.of(context).unfocus();
              context.pop();
            },
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: GestureDetector(
                onTap: () {
                  _messageFocusNode.unfocus();
                  FocusScope.of(context).unfocus();
                  _scaffoldKey.currentState?.openEndDrawer();
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
          child: Column(
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD8E9C8),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ListView.builder(
                    controller: _scrollController,
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    itemCount: _messages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (_isLoading && index == _messages.length) {
                        return const Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      final message = _messages[index];
                      if (message["type"] == "user") {
                        return _userBubble((message["text"] ?? "").toString());
                      } else {
                        return _botBubble(
                          text: (message["text"] ?? "").toString(),
                          ingredients: List<String>.from(
                            message["ingredients"] ?? [],
                          ),
                          recipes: List<dynamic>.from(message["recipes"] ?? []),
                        );
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F1F1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _ingredientController,
                              focusNode: _messageFocusNode,
                              autofocus: false,
                              textInputAction: TextInputAction.done,
                              onTapOutside: (_) {
                                _messageFocusNode.unfocus();
                                FocusScope.of(context).unfocus();
                              },
                              decoration: const InputDecoration(
                                hintText: "Enter ingredients or message",
                                border: InputBorder.none,
                                hintStyle: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                              ),
                              onSubmitted: (_) => _submitMessage(),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              _ingredientController.clear();
                              _messageFocusNode.unfocus();
                              FocusScope.of(context).unfocus();
                            },
                            icon: const Icon(Icons.close),
                            color: Colors.black54,
                          ),
                        ],
                      ),
                    ),
                    Container(height: 1, color: Colors.black38),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          const Spacer(),
                          SizedBox(
                            height: 36,
                            child: ElevatedButton(
                              onPressed: _submitMessage,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF7A2D00),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: const Text(
                                "Submit",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
    );
  }
}
