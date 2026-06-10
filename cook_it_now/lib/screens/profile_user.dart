import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/profile_service.dart';
import '../services/session_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();

  final ProfileService _profileService = ProfileService();

  bool _isLoading = true;
  bool _isSaving = false;

  String _email = '';
  String _provider = '';
  String _passwordText = '********';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<String?> _getCurrentEmail() async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null && currentUser.email != null) {
      await SessionService.saveEmail(currentUser.email!);
      return currentUser.email!;
    }

    return await SessionService.getEmail();
  }

  Future<void> _loadProfile() async {
    try {
      final email = await _getCurrentEmail();

      if (email == null || email.isEmpty) {
        throw Exception("No logged-in user found.");
      }

      final data = await _profileService.getUserProfile(email);

      setState(() {
        _email = data['email'] ?? '';
        _provider = data['provider'] ?? 'Email';
        _nameController.text = data['name'] ?? '';
        _contactController.text = data['contact_number'] ?? '';

        final providerLower = _provider.toLowerCase();
        if (providerLower == 'google') {
          _passwordText = 'Managed by Google';
        } else if (providerLower == 'facebook') {
          _passwordText = 'Managed by Facebook';
        } else {
          _passwordText = '********';
        }

        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading profile: $e')));
    }
  }

  Future<void> _saveProfile() async {
    if (_email.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User email not found. Please login again.'),
        ),
      );
      return;
    }

    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Username cannot be empty')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final updatedData = await _profileService.updateUserProfile(
        email: _email,
        name: _nameController.text.trim(),
        contactNumber: _contactController.text.trim(),
      );

      setState(() {
        _nameController.text = updatedData['name'] ?? _nameController.text;
        _contactController.text =
            updatedData['contact_number'] ?? _contactController.text;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Update failed: $e')));
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _hideKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  Widget _buildEditableField({
    required String title,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            onTapOutside: (_) => _hideKeyboard(),
            decoration: InputDecoration(
              prefixIcon: Icon(icon),
              suffixIcon: const Icon(Icons.edit),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyField({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: TextEditingController(text: value),
            readOnly: true,
            decoration: InputDecoration(
              prefixIcon: Icon(icon),
              suffixIcon: const Icon(Icons.lock_outline),
              filled: true,
              fillColor: Colors.grey.shade200,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;

    return GestureDetector(
      onTap: _hideKeyboard,
      child: Scaffold(
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
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: screen.width * 0.06,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Image.asset(
                            "assets/appIcon/logo2.jpg",
                            height: screen.height * 0.12,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF622906),
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      "User Details",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => context.go('/healthProfile'),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    child: const Center(
                                      child: Text(
                                        "Health Details",
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),
                        _buildEditableField(
                          title: "User name",
                          controller: _nameController,
                          icon: Icons.person_outline,
                        ),
                        _buildReadOnlyField(
                          title: "Email",
                          value: _email,
                          icon: Icons.email_outlined,
                        ),
                        _buildReadOnlyField(
                          title: "Login Provider",
                          value: _provider,
                          icon: Icons.verified_user_outlined,
                        ),
                        _buildReadOnlyField(
                          title: "Password",
                          value: _passwordText,
                          icon: Icons.lock_outline,
                        ),
                        _buildEditableField(
                          title: "Contact Number",
                          controller: _contactController,
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 30),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF622906),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            onPressed: _isSaving ? null : _saveProfile,
                            child: _isSaving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    "Save changes",
                                    style: TextStyle(color: Colors.white),
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
    );
  }
}
