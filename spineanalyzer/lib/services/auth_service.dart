import 'api_service.dart';

class AuthService {
  Future<bool> login(String email, String password) async {
    final response = await ApiService.login(email, password);
    if (response.statusCode == 200) {
      // Simpan token/session jika perlu
      return true;
    }
    return false;
  }
}
