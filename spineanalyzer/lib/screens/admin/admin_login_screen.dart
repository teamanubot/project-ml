import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import 'admin_dashboard_screen.dart';

class AdminLoginScreen extends StatefulWidget {
  static const routeName = '/admin/login';
  @override
  _AdminLoginScreenState createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final TextEditingController _passwordController = TextEditingController();
  int _loginAttempts = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _updateLoginAttempts();
  }

  Future<void> _updateLoginAttempts() async {
    final api = Provider.of<ApiService>(context, listen: false);
    final attempts = await api.getAdminLoginAttempts();
    setState(() {
      _loginAttempts = attempts;
    });
  }

  Future<void> _attemptLogin() async {
    final password = _passwordController.text.trim();
    if (password.isEmpty) {
      _showError('Password is required');
      return;
    }
    setState(() { _isLoading = true; });
    final api = Provider.of<ApiService>(context, listen: false);
    final attempts = await api.getAdminLoginAttempts();
    if (attempts >= 5) {
      _showResetPasswordOption();
      _showToast('Too many failed attempts. Please reset password or try again later.');
      setState(() { _isLoading = false; });
      return;
    }
    final isValid = await api.verifyAdminPassword(password);
    if (isValid) {
      await api.setAdminLoggedIn(true);
      _showToast('Login successful');
      Navigator.pushReplacementNamed(context, '/admin/dashboard');
    } else {
      _showError('Incorrect password');
      _passwordController.clear();
      await _updateLoginAttempts();
      final currentAttempts = await api.getAdminLoginAttempts();
      _showToast('Incorrect password. Attempt $currentAttempts of 5');
      if (currentAttempts >= 3) {
        _showResetPasswordOption();
      }
    }
    setState(() { _isLoading = false; });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showForgotPasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Forgot Password?'),
        content: Text(
          'To reset your admin password, you can:\n\n'
          '1. Contact system administrator\n'
          '2. Use the reset option below\n'
          '3. Long press the Login button\n\n'
          'Default password is \'admin123\' for new installations.'
        ),
        actions: [
          TextButton(
            child: Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text('Reset to Default'),
            onPressed: () {
              Navigator.pop(context);
              _showResetConfirmationDialog();
            },
          ),
        ],
      ),
    );
  }

  void _showResetPasswordOption() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Too Many Failed Attempts'),
        content: Text('Would you like to reset the admin password to default?'),
        actions: [
          TextButton(
            child: Text('Reset to Default'),
            onPressed: () {
              Navigator.pop(context);
              _showResetConfirmationDialog();
            },
          ),
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showResetConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reset to Default Password'),
        content: Text("This will reset the admin password to 'admin123'. Continue?"),
        actions: [
          TextButton(
            child: Text('Reset'),
            onPressed: () async {
              final api = Provider.of<ApiService>(context, listen: false);
              final success = await api.resetAdminPassword();
              Navigator.pop(context);
              if (success) {
                _showToast("Password reset to: admin123");
                await _updateLoginAttempts();
                _passwordController.clear();
              } else {
                _showError('Failed to reset password');
              }
            },
          ),
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateLoginAttempts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Login'),
        leading: BackButton(),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Admin Password',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
              onSubmitted: (_) => _attemptLogin(),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Failed attempts: $_loginAttempts/5',
                  style: TextStyle(
                    color: _loginAttempts >= 3 ? Colors.red : Colors.black54,
                  ),
                ),
                GestureDetector(
                  onTap: _showForgotPasswordDialog,
                  child: Text('Forgot Password?',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _attemptLogin,
                onLongPress: _showResetPasswordOption,
                child: _isLoading
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text('Login'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
