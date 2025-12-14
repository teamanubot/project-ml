import 'package:flutter/material.dart';

import 'screens/login_screen.dart';
import 'services/api_service.dart';
import 'dart:convert';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/analysis_screen.dart';
import 'screens/history_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/admin/admin_login_screen.dart';
import 'screens/admin/admin_settings_screen.dart';
import 'screens/admin/manage_analyses_screen.dart';
import 'screens/admin/manage_interpretation_screen.dart';
import 'screens/admin/manage_users_screen.dart';
import 'screens/admin/reports_screen.dart';

void main() {
  runApp(SpineAnalyzerApp());
}

class SpineAnalyzerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spine Analyzer',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => LoginScreen(
          onLogin: (email, password) async {
            if (email.contains('admin')) {
              if (password == 'admin123') {
                Navigator.pushReplacementNamed(context, '/admin/dashboard');
                return true;
              }
              return false;
            } else {
              // User biasa, validasi ke backend FastAPI
              try {
                final response = await ApiService.login(email, password);
                if (response.statusCode == 200) {
                  final data = jsonDecode(response.body);
                  // Cek response model: bisa UserOut atau {success, user}
                  final user = data['user'] ?? data;
                  Navigator.pushReplacementNamed(
                    context,
                    '/home',
                    arguments: {
                      'userName': user['name'],
                      'userId': user['id'],
                    },
                  );
                  return true;
                }
                return false;
              } catch (_) {
                return false;
              }
            }
          },
          onRegisterTap: () {
            Navigator.pushNamed(context, '/register');
          },
        ),
        '/register': (context) => RegisterScreen(
          onRegister: (name, email, password) async {
            try {
              final response = await ApiService.register(name, email, password);
              if (response.statusCode == 200 || response.statusCode == 201) {
                final data = jsonDecode(response.body);
                final user = data['user'] ?? data;
                // Simpan user ke arg global agar bisa diakses di /home setelah klik OK
                // Atau gunakan state management jika ingin lebih advance
                // Untuk sekarang, return user agar bisa dipakai di register_screen.dart
                RegisterScreen.lastRegisteredUser = user;
                return true;
              }
              return false;
            } catch (_) {
              return false;
            }
          },
          onLoginTap: () {
            Navigator.pushReplacementNamed(context, '/login');
          },
        ),
        '/home': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          return HomeScreen(
            userName: args?['userName'] ?? 'User',
            userId: args?['userId'] ?? 1,
          );
        },
        '/profile': (context) => ProfileScreen(name: 'User', email: 'user@email.com'),
        '/analysis': (context) => AnalysisScreen(userId: 1, imagePath: ''),
        // TODO: Ganti dengan instance Database yang valid
        '/history': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          return HistoryScreen(userId: args?['userId'] ?? 1);
        },
        '/admin/login': (context) => AdminLoginScreen(),
        '/admin/dashboard': (context) => AdminDashboardScreen(),
        '/admin/settings': (context) => AdminSettingsScreen(),
        '/admin/manage-analyses': (context) => ManageAnalysesScreen(),
        '/admin/manage-interpretation': (context) => ManageInterpretationScreen(),
        '/admin/manage-users': (context) => ManageUsersScreen(),
        '/admin/reports': (context) => ReportsScreen(),
      },
    );
  }
}
