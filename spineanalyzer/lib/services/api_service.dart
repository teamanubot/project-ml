import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
    Future<List<dynamic>> getUserHistory(int userId) async {
      final response = await http.get(Uri.parse('$baseUrl/api/history/$userId'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    }
  static const String baseUrl = 'http://localhost:8000';

  static Future<http.Response> register(String name, String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );
    return response;
  }

  // Statistik untuk dashboard
  Future<int> getTotalUsersCount() async {
    final stats = await getDashboardStatistics();
    return stats['totalUsers'] ?? 0;
  }
  Future<int> getTotalAnalysesCount() async {
    final stats = await getDashboardStatistics();
    return stats['totalAnalyses'] ?? 0;
  }
  Future<int> getTodayAnalysesCount() async {
    final stats = await getDashboardStatistics();
    return stats['todayAnalyses'] ?? 0;
  }

  static Future<http.Response> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    return response;
  }

  // Admin stub
  Future<int> getAdminLoginAttempts() async => 0;
  Future<bool> verifyAdminPassword(String password) async => password == 'admin123';
  Future<void> setAdminLoggedIn(bool value) async {}
  Future<bool> resetAdminPassword() async => true;
  Future<DateTime?> getAdminLastLogin() async => DateTime.now();
  Future<bool> changeAdminPassword(String current, String newPass) async => true;
  Future<void> clearAllUserData() async {}

  Future<List<dynamic>> getAllAnalyses() async {
    final response = await http.get(Uri.parse('$baseUrl/api/analyses'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  Future<List<dynamic>> getAnalysesByDateRange(DateTime start, DateTime end) async {
    // Not implemented in backend, fallback to all analyses
    return getAllAnalyses();
  }

  Future<void> deleteAnalysis(String id) async {
    // Not implemented in backend
  }

  Future<List<dynamic>> getAllUsersWithAnalysisCount() async {
    final response = await http.get(Uri.parse('$baseUrl/api/users'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  Future<bool> updateUser(String id, String name, String email) async {
    // Not implemented in backend
    return false;
  }

  Future<bool> deleteUser(String id) async {
    // Not implemented in backend
    return false;
  }

  Future<Map<String, dynamic>> getDashboardStatistics() async {
    final response = await http.get(Uri.parse('$baseUrl/api/dashboard/statistics'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return {};
  }

  Future<Map<String, dynamic>> getStatisticsByDateRange(DateTime start, DateTime end) async {
    // Not implemented in backend
    return {};
  }
}
