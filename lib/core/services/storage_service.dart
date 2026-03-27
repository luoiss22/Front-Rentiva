import 'package:shared_preferences/shared_preferences.dart';

/// Maneja la persistencia local de tokens JWT y datos básicos del usuario.
class StorageService {
  static const _keyAccess     = 'access_token';
  static const _keyRefresh    = 'refresh_token';
  static const _keyUserId     = 'user_id';
  static const _keyUserRol    = 'user_type';
  static const _keyUserNombre = 'user_nombre';

  static Future<void> saveTokens({
    required String access,
    required String refresh,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAccess, access);
    await prefs.setString(_keyRefresh, refresh);
  }

  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAccess);
  }

  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyRefresh);
  }

  static Future<void> saveUser({
    required int id,
    required String rol,
    required String nombre,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyUserId, id);
    await prefs.setString(_keyUserRol, rol);
    await prefs.setString(_keyUserNombre, nombre);
  }


  static Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt(_keyUserId);
    if (id == null) return null;
    return {
      'id':     id,
      'rol':    prefs.getString(_keyUserRol) ?? '',
      'nombre': prefs.getString(_keyUserNombre) ?? '',
    };
  }

  static Future<String?> getUserRol() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserRol);
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAccess) != null;
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
