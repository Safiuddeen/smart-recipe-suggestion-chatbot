import 'package:shared_preferences/shared_preferences.dart';

class TermsService {
  static const String _termsAcceptedKey = 'terms_accepted';

  static Future<bool> isAccepted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_termsAcceptedKey) ?? false;
  }

  static Future<void> setAccepted(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_termsAcceptedKey, value);
  }
}
