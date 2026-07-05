import 'package:hru_atms/features/auth/domain/models/auth_session.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthSessionStore {
  static const _tokenKey = 'auth_token';
  static const _userNameKey = 'auth_user_name';
  static const _userRoleKey = 'auth_user_role';

  Future<void> save(AuthSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, session.token);
    await prefs.setString(_userNameKey, session.user.name);
    await prefs.setString(_userRoleKey, session.user.role);
  }

  Future<bool> hasToken() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getString(_tokenKey) ?? '').isNotEmpty;
  }

  Future<String?> token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<String?> userName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey);
  }

  Future<String?> userRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userRoleKey);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_userRoleKey);
  }
}
