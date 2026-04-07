import 'package:shared_preferences/shared_preferences.dart';

/// Maneja la persistencia local de tokens JWT y datos básicos del usuario.
class StorageService {
  static const _keyAccess        = 'access_token';
  static const _keyRefresh       = 'refresh_token';
  static const _keyUserId        = 'user_id';
  static const _keyUserRol       = 'user_type';
  static const _keyUserNombre    = 'user_nombre';
  static const _keyFechaNac      = 'user_fecha_nacimiento';
  static const _keyFolioIne      = 'user_folio_ine';
  static const _keyEmail         = 'user_email';
  static const _keyTelefono      = 'user_telefono';

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
    String? fechaNacimiento,
    String? folioIne,
    String? email,
    String? telefono,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyUserId, id);
    await prefs.setString(_keyUserRol, rol);
    await prefs.setString(_keyUserNombre, nombre);
    if (fechaNacimiento != null) await prefs.setString(_keyFechaNac, fechaNacimiento);
    if (folioIne != null)        await prefs.setString(_keyFolioIne, folioIne);
    if (email != null)           await prefs.setString(_keyEmail, email);
    if (telefono != null)        await prefs.setString(_keyTelefono, telefono);
  }

  static Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt(_keyUserId);
    if (id == null) return null;
    return {
      'id':                id,
      'rol':               prefs.getString(_keyUserRol) ?? '',
      'nombre':            prefs.getString(_keyUserNombre) ?? '',
      'fecha_nacimiento':  prefs.getString(_keyFechaNac) ?? '',
      'folio_ine':         prefs.getString(_keyFolioIne) ?? '',
      'email':             prefs.getString(_keyEmail) ?? '',
      'telefono':          prefs.getString(_keyTelefono) ?? '',
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
