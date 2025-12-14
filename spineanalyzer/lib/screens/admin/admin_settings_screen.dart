import 'package:flutter/material.dart';
import '../../widgets/custom_snackbar.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import '../../services/admin_password_manager.dart';
import '../main_screen.dart';

class AdminSettingsScreen extends StatefulWidget {
  static const routeName = '/admin/settings';
  @override
  _AdminSettingsScreenState createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  bool autoBackup = false;
  bool notifications = true;
  String lastBackup = 'Never';
  String dbSize = 'Unknown';
  String appVersion = '1.0';
  String adminLastLogin = '-';
  int loginAttempts = 0;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      autoBackup = prefs.getBool('auto_backup') ?? false;
      notifications = prefs.getBool('notifications') ?? true;
      lastBackup = prefs.getString('last_backup') ?? 'Never';
    });
    // Load admin info from ApiService
    final api = Provider.of<ApiService>(context, listen: false);
    final lastLogin = await api.getAdminLastLogin();
    final attempts = await api.getAdminLoginAttempts();
    setState(() {
      adminLastLogin = lastLogin?.toString() ?? '-';
      loginAttempts = attempts;
    });
    // TODO: Calculate dbSize if needed
    // TODO: Get appVersion from package_info_plus if needed
  }

  void _onAutoBackupChanged(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_backup', value);
    setState(() => autoBackup = value);
    CustomSnackbar.show(context, message: 'Auto backup ${value ? 'enabled' : 'disabled'}', type: SnackbarType.info);
  }

  void _onNotificationsChanged(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications', value);
    setState(() => notifications = value);
    CustomSnackbar.show(context, message: 'Notifications ${value ? 'enabled' : 'disabled'}', type: SnackbarType.info);
  }

  void _showChangePasswordDialog() {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Change Admin Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentController,
              obscureText: true,
              decoration: InputDecoration(labelText: 'Current Password'),
            ),
            TextField(
              controller: newController,
              obscureText: true,
              decoration: InputDecoration(labelText: 'New Password'),
            ),
            TextField(
              controller: confirmController,
              obscureText: true,
              decoration: InputDecoration(labelText: 'Confirm New Password'),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text('Change'),
            onPressed: () async {
              final current = currentController.text.trim();
              final newPass = newController.text.trim();
              final confirm = confirmController.text.trim();
              if (current.isEmpty || newPass.isEmpty || confirm.isEmpty) {
                _showToast('All fields are required');
                return;
              }
              if (newPass.length < 6) {
                _showToast('New password must be at least 6 characters');
                return;
              }
              if (newPass != confirm) {
                _showToast('New passwords do not match');
                return;
              }
              if (newPass == current) {
                _showToast('New password must be different from current password');
                return;
              }
              final api = Provider.of<ApiService>(context, listen: false);
              final changed = await api.changeAdminPassword(current, newPass);
              if (changed) {
                _showToast('Password changed successfully!');
                _loadSettings();
                Navigator.pop(context);
                _showPasswordChangeConfirmation();
              } else {
                final valid = await api.verifyAdminPassword(current);
                if (!valid) {
                  _showToast('Current password is incorrect');
                } else {
                  _showToast('Failed to change password. Please try again.');
                }
                _loadSettings();
              }
            },
          ),
        ],
      ),
    );
  }

  void _showPasswordChangeConfirmation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Password Changed Successfully'),
        content: Text(
          'Your admin password has been changed successfully!\n\n'
          'For security, you will be logged out. Please login again with your new password.',
        ),
        actions: [
          TextButton(
            child: Text('OK'),
            onPressed: () {
              // Clear admin login status
              // Use your session manager or shared_preferences
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }

  void _showResetPasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reset Admin Password'),
        content: Text("This will reset the admin password to the default 'admin123'. Continue?"),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text('Reset'),
            onPressed: () async {
              final api = Provider.of<ApiService>(context, listen: false);
              final success = await api.resetAdminPassword();
              Navigator.pop(context);
              if (success) {
                _showToast('Admin password reset to: admin123');
                _loadSettings();
              } else {
                _showToast('Failed to reset password');
              }
            },
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('About'),
        content: Text(
          'Spine Analyzer Admin Panel\n\n'
          'Version: 1.0\n'
          'Database Version: 2 (with Admin Settings)\n'
          'Developed for spine curvature analysis\n\n'
          'Features:\n'
          '• User Management\n'
          '• Analysis Management\n'
          '• Dynamic Interpretation Rules\n'
          '• Database Backup/Restore\n'
          '• Secure Admin Password Management\n'
          '• Login Attempt Tracking\n\n'
          'Security Features:\n'
          '• SHA-256 Password Hashing\n'
          '• Database-stored Admin Credentials\n'
          '• Failed Login Attempt Monitoring\n\n'
          'Debug Info:\n'
          '• Long press "Change Password" to test default password\n\n'
          '© 2024 Spine Analyzer',
        ),
        actions: [
          TextButton(
            child: Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showClearDataDialog() {
    final confirmController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear All Data'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'This will delete ALL users and analyses. Admin settings will be preserved. This action cannot be undone!',
            ),
            SizedBox(height: 12),
            TextField(
              controller: confirmController,
              decoration: InputDecoration(
                labelText: "Type 'DELETE' to confirm",
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text('Clear All'),
            onPressed: () async {
              if (confirmController.text.trim() == 'DELETE') {
                final api = Provider.of<ApiService>(context, listen: false);
                await api.clearAllUserData();
                _showToast('All user data cleared successfully. Admin settings preserved.');
                _loadSettings();
                Navigator.pop(context);
              } else {
                _showToast('Confirmation text incorrect. Data not cleared.');
              }
            },
          ),
        ],
      ),
    );
  }

  void _showRestoreDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Restore Database'),
        content: Text('This will replace current data with backup. Continue?'),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text('Restore'),
            onPressed: () {
              Navigator.pop(context);
              _showToast('Restore feature coming soon');
            },
          ),
        ],
      ),
    );
  }

  void _backupDatabase() {
    _showToast('Backup feature coming soon');
    // TODO: Implement backup logic
  }

  void _exportSettings() {
    _showToast('Export settings feature coming soon');
    // TODO: Implement export logic
  }

  void _showToast(String message) {
    CustomSnackbar.show(context, message: message, type: SnackbarType.error);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Settings'),
        leading: BackButton(),
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          ListTile(
            title: Text('Change Admin Password'),
            trailing: Icon(Icons.lock),
            onTap: _showChangePasswordDialog,
            onLongPress: () async {
              final api = Provider.of<ApiService>(context, listen: false);
              final isDefault = await api.verifyAdminPassword('admin123');
              _showToast('admin123 works: $isDefault');
            },
          ),
          SwitchListTile(
            title: Text('Auto Backup'),
            value: autoBackup,
            onChanged: _onAutoBackupChanged,
          ),
          SwitchListTile(
            title: Text('Notifications'),
            value: notifications,
            onChanged: _onNotificationsChanged,
          ),
          ListTile(
            title: Text('Backup Database'),
            trailing: Icon(Icons.backup),
            onTap: _backupDatabase,
          ),
          ListTile(
            title: Text('Restore Database'),
            trailing: Icon(Icons.restore),
            onTap: _showRestoreDialog,
          ),
          ListTile(
            title: Text('Clear All Data'),
            trailing: Icon(Icons.delete_forever),
            onTap: _showClearDataDialog,
          ),
          ListTile(
            title: Text('Export Settings'),
            trailing: Icon(Icons.file_upload),
            onTap: _exportSettings,
          ),
          ListTile(
            title: Text('About'),
            trailing: Icon(Icons.info_outline),
            onTap: _showAboutDialog,
          ),
          Divider(),
          ListTile(
            title: Text('Last Backup'),
            subtitle: Text(lastBackup),
          ),
          ListTile(
            title: Text('Database Size'),
            subtitle: Text(dbSize),
          ),
          ListTile(
            title: Text('App Version'),
            subtitle: Text(appVersion),
          ),
          Divider(),
          ListTile(
            title: Text('Admin Last Login'),
            subtitle: Text(adminLastLogin),
          ),
          ListTile(
            title: Text('Failed Login Attempts'),
            subtitle: Text('$loginAttempts'),
            textColor: loginAttempts > 3 ? Colors.red : null,
          ),
          ListTile(
            title: Text('Reset Admin Password'),
            trailing: Icon(Icons.refresh),
            onTap: _showResetPasswordDialog,
          ),
        ],
      ),
    );
  }
}