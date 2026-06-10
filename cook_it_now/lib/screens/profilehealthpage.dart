import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/health_profile_service.dart';
import '../services/session_service.dart';

class HealthPage extends StatefulWidget {
  const HealthPage({super.key});

  @override
  State<HealthPage> createState() => _HealthPageState();
}

class _HealthPageState extends State<HealthPage> {
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _bmrController = TextEditingController();

  final HealthProfileService _healthProfileService = HealthProfileService();

  bool _isLoading = true;
  bool _isSaving = false;

  String _email = '';
  String _gender = 'Male';

  bool _diabetes = false;
  bool _highBloodPressure = false;
  bool _cholesterol = false;
  bool _kidneyIssues = false;

  @override
  void initState() {
    super.initState();
    _ageController.addListener(_calculateBmr);
    _heightController.addListener(_calculateBmr);
    _weightController.addListener(_calculateBmr);
    _loadHealthProfile();
  }

  Future<String?> _getCurrentEmail() async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null && currentUser.email != null) {
      await SessionService.saveEmail(currentUser.email!);
      return currentUser.email!;
    }

    return await SessionService.getEmail();
  }

  Future<void> _loadHealthProfile() async {
    try {
      final email = await _getCurrentEmail();

      if (email == null || email.isEmpty) {
        throw Exception("No logged-in user found.");
      }

      _email = email;

      final data = await _healthProfileService.getHealthProfile(_email);

      setState(() {
        _ageController.text = data['age']?.toString() ?? '';
        _gender = (data['gender']?.toString().isNotEmpty == true)
            ? data['gender'].toString()
            : 'Male';
        _heightController.text = data['height_cm']?.toString() ?? '';
        _weightController.text = data['weight_kg']?.toString() ?? '';
        _bmrController.text = data['bmr']?.toString() ?? '';
        _diabetes = data['diabetes'] == true;
        _highBloodPressure = data['high_blood_pressure'] == true;
        _cholesterol = data['cholesterol'] == true;
        _kidneyIssues = data['kidney_issues'] == true;
        _isLoading = false;
      });

      _calculateBmr();
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading health profile: $e')),
      );
    }
  }

  void _calculateBmr() {
    final int? age = int.tryParse(_ageController.text.trim());
    final double? height = double.tryParse(_heightController.text.trim());
    final double? weight = double.tryParse(_weightController.text.trim());

    if (age == null || height == null || weight == null) {
      _bmrController.text = '';
      return;
    }

    double bmr;

    if (_gender.toLowerCase() == 'male') {
      bmr = (10 * weight) + (6.25 * height) - (5 * age) + 5;
    } else if (_gender.toLowerCase() == 'female') {
      bmr = (10 * weight) + (6.25 * height) - (5 * age) - 161;
    } else {
      bmr = (10 * weight) + (6.25 * height) - (5 * age) - 78;
    }

    _bmrController.text = bmr.toStringAsFixed(2);
  }

  Future<void> _saveHealthProfile() async {
    final age = int.tryParse(_ageController.text.trim());
    final height = double.tryParse(_heightController.text.trim());
    final weight = double.tryParse(_weightController.text.trim());

    if (_email.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User email not found. Please login again.'),
        ),
      );
      return;
    }

    if (age == null || age <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a valid age')));
      return;
    }

    if (height == null || height <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid height')),
      );
      return;
    }

    if (weight == null || weight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid weight')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final response = await _healthProfileService.updateHealthProfile(
        email: _email,
        age: age,
        gender: _gender,
        heightCm: height,
        weightKg: weight,
        diabetes: _diabetes,
        highBloodPressure: _highBloodPressure,
        cholesterol: _cholesterol,
        kidneyIssues: _kidneyIssues,
      );

      setState(() {
        _bmrController.text = (response['bmr'] ?? '').toString();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Health profile updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save health profile: $e')),
      );
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
    required TextEditingController controller,
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
            controller: controller,
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

  Widget _buildGenderDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Gender",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _gender,
            items: const [
              DropdownMenuItem(value: "Male", child: Text("Male")),
              DropdownMenuItem(value: "Female", child: Text("Female")),
              DropdownMenuItem(value: "Other", child: Text("Other")),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() => _gender = value);
              _calculateBmr();
            },
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.wc_outlined),
              filled: true,
              fillColor: Colors.white,
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

  Widget _buildYesNoToggle({
    required String title,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => onChanged(true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: value
                            ? const Color(0xFF622906)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          "YES",
                          style: TextStyle(
                            color: value ? Colors.white : Colors.black,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => onChanged(false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: !value
                            ? const Color(0xFF622906)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          "NO",
                          style: TextStyle(
                            color: !value ? Colors.white : Colors.black,
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
        ],
      ),
    );
  }

  @override
  void dispose() {
    _ageController.removeListener(_calculateBmr);
    _heightController.removeListener(_calculateBmr);
    _weightController.removeListener(_calculateBmr);

    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _bmrController.dispose();
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
                                child: GestureDetector(
                                  onTap: () => context.go('/userProfile'),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    child: const Center(
                                      child: Text(
                                        "User Details",
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
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
                                      "Health Details",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
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
                          title: "Age",
                          controller: _ageController,
                          icon: Icons.cake_outlined,
                          keyboardType: TextInputType.number,
                        ),
                        _buildGenderDropdown(),
                        _buildEditableField(
                          title: "Height (cm)",
                          controller: _heightController,
                          icon: Icons.height,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                        _buildEditableField(
                          title: "Weight (kg)",
                          controller: _weightController,
                          icon: Icons.monitor_weight_outlined,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                        _buildReadOnlyField(
                          title: "BMR",
                          controller: _bmrController,
                          icon: Icons.local_fire_department_outlined,
                        ),
                        const SizedBox(height: 10),
                        _buildYesNoToggle(
                          title: "Diabetes",
                          value: _diabetes,
                          onChanged: (value) =>
                              setState(() => _diabetes = value),
                        ),
                        _buildYesNoToggle(
                          title: "High Blood Pressure",
                          value: _highBloodPressure,
                          onChanged: (value) =>
                              setState(() => _highBloodPressure = value),
                        ),
                        _buildYesNoToggle(
                          title: "Cholesterol",
                          value: _cholesterol,
                          onChanged: (value) =>
                              setState(() => _cholesterol = value),
                        ),
                        _buildYesNoToggle(
                          title: "Kidney Issues",
                          value: _kidneyIssues,
                          onChanged: (value) =>
                              setState(() => _kidneyIssues = value),
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
                            onPressed: _isSaving ? null : _saveHealthProfile,
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
