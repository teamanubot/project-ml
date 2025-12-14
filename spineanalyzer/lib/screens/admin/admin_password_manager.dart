import 'package:shared_preferences/shared_preferences.dart';

class AdminPasswordManager {
  static const String _prefName = 'AdminPreferences';
  static const String _keyAdminPassword = 'admin_password';
  static const String _defaultPassword = 'admin123';

  SharedPreferences? _prefs;

  AdminPasswordManager();

  // Initialize preferences and default password if needed
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    if (!_prefs!.containsKey(_keyAdminPassword)) {
      await _prefs!.setString(_keyAdminPassword, _defaultPassword);
    }
  }

  // Get current admin password
  String getCurrentPassword() {
    return _prefs?.getString(_keyAdminPassword) ?? _defaultPassword;
  }

  // Verify password
  bool verifyPassword(String? inputPassword) {
    if (inputPassword == null) return false;
    final currentPassword = getCurrentPassword();
    return inputPassword == currentPassword;
  }

  // Change password
  Future<bool> changePassword(String oldPassword, String newPassword) async {
    if (!verifyPassword(oldPassword)) {
      return false;
    }
    if (newPassword.trim().length < 6) {
      return false;
    }
    final success = await _prefs?.setString(_keyAdminPassword, newPassword.trim()) ?? false;
    if (success) {
      final savedPassword = _prefs?.getString(_keyAdminPassword) ?? '';
      return newPassword.trim() == savedPassword;
    }
    return false;
  }

  // Reset to default password
  Future<bool> resetPassword() async {
    return await _prefs?.setString(_keyAdminPassword, _defaultPassword) ?? false;
  }

  // Force clear and reset
  Future<bool> forceClearAndReset() async {
    final cleared = await _prefs?.clear() ?? false;
    final reset = await _prefs?.setString(_keyAdminPassword, _defaultPassword) ?? false;
    return cleared && reset;
  }

  // Debug method - remove in production
  void debugCurrentPassword() {
    final currentPassword = getCurrentPassword();
    print('Current admin password: $currentPassword');
  }
}
