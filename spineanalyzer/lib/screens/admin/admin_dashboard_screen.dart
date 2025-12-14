import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart'; // Your database helper/service
import 'manage_users_screen.dart';
import 'manage_analyses_screen.dart';
import 'admin_settings_screen.dart';
import 'reports_screen.dart';
import 'manage_interpretation_screen.dart';
import '../main_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  @override
  _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int totalUsers = 0;
  int totalAnalyses = 0;
  int todayAnalyses = 0;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    final api = Provider.of<ApiService>(context, listen: false);
    final users = await api.getTotalUsersCount();
    final analyses = await api.getTotalAnalysesCount();
    final today = await api.getTodayAnalysesCount();
    setState(() {
      totalUsers = users;
      totalAnalyses = analyses;
      todayAnalyses = today;
    });
  }

  void _performBackup() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Backup feature coming soon')),
    );
  }

  void _logout() async {
    // Clear admin session (use your session manager or shared_preferences)
    // For example:
    // await Provider.of<SessionManager>(context, listen: false).logoutAdmin();
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/login',
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Statistics
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatCard('Total Users', totalUsers),
                _buildStatCard('Total Analyses', totalAnalyses),
                _buildStatCard('Today\'s Analyses', todayAnalyses),
              ],
            ),
            SizedBox(height: 24),
            // Cards
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildDashboardCard(
                    icon: Icons.people,
                    label: 'Manage Users',
                    onTap: () => Navigator.pushNamed(context, ManageUsersScreen.routeName),
                  ),
                  _buildDashboardCard(
                    icon: Icons.analytics,
                    label: 'Manage Analyses',
                    onTap: () => Navigator.pushNamed(context, ManageAnalysesScreen.routeName),
                  ),
                  _buildDashboardCard(
                    icon: Icons.settings,
                    label: 'Settings',
                    onTap: () => Navigator.pushNamed(context, AdminSettingsScreen.routeName),
                  ),
                  _buildDashboardCard(
                    icon: Icons.report,
                    label: 'Reports',
                    onTap: () => Navigator.pushNamed(context, ReportsScreen.routeName),
                  ),
                  _buildDashboardCard(
                    icon: Icons.interpreter_mode,
                    label: 'Interpretation',
                    onTap: () => Navigator.pushNamed(context, ManageInterpretationScreen.routeName),
                  ),
                  _buildDashboardCard(
                    icon: Icons.backup,
                    label: 'Backup',
                    onTap: _performBackup,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, int value) {
    return Card(
      elevation: 4,
      child: Container(
        width: 100,
        height: 80,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('$value', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text(label, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard({required IconData icon, required String label, required VoidCallback onTap}) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48),
              SizedBox(height: 8),
              Text(label, style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }
}