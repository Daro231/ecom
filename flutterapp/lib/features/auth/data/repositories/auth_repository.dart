import '../../../../core/network/dio_client.dart';
import '../models/app_user.dart';

class AuthRepository {
  AuthRepository(this._api);
  final ApiClient _api;

  Future<AuthResult> login(String email, String password) async {
    final r = await _api.post(
      '/auth/login',
      body: {'email': email.trim(), 'password': password},
    );
    return AuthResult.fromJson((r.data as Map).cast<String, dynamic>());
  }

  Future<AuthResult> register({
    required String fullName,
    required String email,
    required String password,
    String? phone,
  }) async {
    final r = await _api.post(
      '/auth/register',
      body: {
        'fullName': fullName.trim(),
        'email': email.trim(),
        'password': password,
        if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
      },
    );
    return AuthResult.fromJson((r.data as Map).cast<String, dynamic>());
  }

  Future<AppUser> me() async {
    final r = await _api.get('/users/me');
    return AppUser.fromJson((r.data as Map).cast<String, dynamic>());
  }
}
