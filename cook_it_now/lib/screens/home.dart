import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../services/account_service.dart';
import '../services/profile_service.dart';
import '../services/session_service.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final TextEditingController ingredientController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final FocusNode _ingredientFocusNode = FocusNode();

  final ProfileService _profileService = ProfileService();
  final AccountService _accountService = AccountService();

  String _displayName = "";
  String _email = "";
  bool _isSigningOut = false;
  bool _isDeletingAccount = false;
  DateTime? _lastBackPressedAt;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserProfile();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _ingredientFocusNode.unfocus();
        FocusScope.of(context).unfocus();
      }
    });
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

      if (email == null || email.isEmpty) {
        return;
      }

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

  void clearText() {
    ingredientController.clear();
    _ingredientFocusNode.unfocus();
    FocusScope.of(context).unfocus();
  }

  void submitIngredients() {
    _ingredientFocusNode.unfocus();
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      final text = ingredientController.text.trim();

      if (text.isEmpty) return;

      ingredientController.clear();
      context.push('/chatpage', extra: text);
    }
  }

  Future<void> _handleBackPress() async {
    final now = DateTime.now();

    if (_lastBackPressedAt == null ||
        now.difference(_lastBackPressedAt!) > const Duration(seconds: 2)) {
      _lastBackPressedAt = now;

      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Press back again to exit"),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    await SystemNavigator.pop();
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

  @override
  void dispose() {
    ingredientController.dispose();
    _ingredientFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;

    return GestureDetector(
      onTap: () {
        _ingredientFocusNode.unfocus();
        FocusScope.of(context).unfocus();
      },
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (!didPop) {
            await _handleBackPress();
          }
        },
        child: Scaffold(
          key: _scaffoldKey,
          resizeToAvoidBottomInset: true,
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
                    title: "Terms & Conditions",
                    iconPath: "assets/icons/terms-and-conditions.png",
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/terms');
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
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: GestureDetector(
                  onTap: () {
                    _ingredientFocusNode.unfocus();
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
          body: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: screen.height * 0.0),
                    Text(
                      "Hello!, $_displayName",
                      style: TextStyle(
                        fontSize: screen.width * 0.05,
                        fontWeight: FontWeight.bold,
                        color: Colors.brown[800],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: Image.asset(
                        "assets/appIcon/logo2.jpg",
                        height: screen.height * 0.15,
                      ),
                    ),
                    const SizedBox(height: 25),
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: ingredientController,
                            focusNode: _ingredientFocusNode,
                            autofocus: false,
                            textInputAction: TextInputAction.done,
                            onTapOutside: (_) {
                              _ingredientFocusNode.unfocus();
                              FocusScope.of(context).unfocus();
                            },
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return "Please enter at least one ingredient";
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                              hintText: "Enter ingredients you have!",
                              filled: true,
                              fillColor: const Color(0xFFFFFFFF),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: clearText,
                              ),
                            ),
                          ),
                          Row(
                            children: const [
                              Expanded(
                                child: Divider(
                                  color: Color(0xFF7A2D00),
                                  thickness: 1.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF7A2D00),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              onPressed: submitIngredients,
                              child: const Text(
                                "Submit",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),
                    const Center(
                      child: Text(
                        "Enter the ingredients you have at home,\nand we'll suggest recipes you can easily cook.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B3B1F),
                        ),
                      ),
                    ),
                    const SizedBox(height: 35),
                    Row(
                      children: const [
                        Expanded(
                          child: Divider(
                            color: Color(0xFF7A2D00),
                            thickness: 1.5,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text("OR search differently"),
                        ),
                        Expanded(
                          child: Divider(
                            color: Color(0xFF7A2D00),
                            thickness: 1.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),
                    Center(
                      child: SizedBox(
                        width: screen.width * 0.7,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7A2D00),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          onPressed: () {
                            _ingredientFocusNode.unfocus();
                            FocusScope.of(context).unfocus();
                            context.go('/recipepage');
                          },
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.restaurant_menu, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                "Search by recipe name",
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 80),
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
}
