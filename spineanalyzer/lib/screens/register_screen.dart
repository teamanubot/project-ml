import 'package:flutter/material.dart';

class RegisterScreen extends StatefulWidget {
    static Map<String, dynamic>? lastRegisteredUser;
  final Future<bool> Function(String name, String email, String password) onRegister;
  final VoidCallback onLoginTap;
  const RegisterScreen({Key? key, required this.onRegister, required this.onLoginTap}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
    bool _showPassword = false;
    bool _showConfirmPassword = false;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  bool isLoading = false;

  void _registerUser() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;

    if (name.isEmpty) {
      _showError('Nama harus diisi');
      return;
    }
    if (email.isEmpty) {
      _showError('Email harus diisi');
      return;
    }
    if (!_isValidEmail(email)) {
      _showError('Format email tidak valid. Contoh: user@example.com');
      return;
    }
    if (password.isEmpty) {
      _showError('Password harus diisi');
      return;
    }
    if (password.length < 6) {
      _showError('Password minimal 6 karakter');
      return;
    }
    if (confirmPassword.isEmpty) {
      _showError('Konfirmasi password harus diisi');
      return;
    }
    if (password != confirmPassword) {
      _showError('Password tidak cocok');
      return;
    }
    setState(() => isLoading = true);
    final success = await widget.onRegister(name, email, password);
    setState(() => isLoading = false);
    if (!success) {
      _showError('Registrasi gagal, silakan coba lagi atau email sudah terdaftar');
    } else {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Sukses'),
          content: const Text('Pendaftaran akun berhasil'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Ambil user dari static var, lalu ke /home dengan argumen user
                final user = RegisterScreen.lastRegisteredUser;
                Navigator.of(context).pushReplacementNamed(
                  '/home',
                  arguments: user != null
                      ? {'userName': user['name'], 'userId': user['id']}
                      : null,
                );
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  bool _isValidEmail(String email) {
    final pattern = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    return pattern.hasMatch(email);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.local_hospital, color: Colors.blue, size: 40),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'SpineAnalyzer',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[900],
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Daftar Akun Pasien',
                      style: TextStyle(color: Colors.blueGrey[700], fontSize: 14),
                    ),
                  ],
                ),
              ),
              Card(
                elevation: 6,
                margin: const EdgeInsets.symmetric(horizontal: 24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nama',
                          prefixIcon: Icon(Icons.person_outline),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: passwordController,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(_showPassword ? Icons.visibility : Icons.visibility_off),
                            onPressed: () {
                              setState(() => _showPassword = !_showPassword);
                            },
                          ),
                        ),
                        obscureText: !_showPassword,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: confirmPasswordController,
                        decoration: InputDecoration(
                          labelText: 'Konfirmasi Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(_showConfirmPassword ? Icons.visibility : Icons.visibility_off),
                            onPressed: () {
                              setState(() => _showConfirmPassword = !_showConfirmPassword);
                            },
                          ),
                        ),
                        obscureText: !_showConfirmPassword,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[800],
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: isLoading ? null : _registerUser,
                          child: isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('Daftar', style: TextStyle(fontSize: 16, color: Colors.white)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: widget.onLoginTap,
                          child: const Text(
                            'Sudah punya akun? Masuk',
                            style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
