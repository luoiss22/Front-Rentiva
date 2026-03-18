import 'api_client.dart';
import 'storage_service.dart';
import '../models/propietario_model.dart';

class AuthResult {
  final PropietarioModel propietario;
  final String accessToken;
  final String refreshToken;

  AuthResult({
    required this.propietario,
    required this.accessToken,
    required this.refreshToken,
  });
}

class AuthService {
  /// POST /auth/login/  → guarda tokens y retorna AuthResult
  static Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final data = await ApiClient.post(
      '/auth/login/',
      {'email': email, 'password': password},
      auth: false,
    );
    return _processAuthResponse(data);
  }

  /// POST /auth/registro/  → crea cuenta y devuelve AuthResult
  static Future<AuthResult> register({
    required String nombre,
    required String apellidos,
    required String email,
    required String telefono,
    required String password,
  }) async {
    final data = await ApiClient.post(
      '/auth/registro/',
      {
        'nombre':    nombre,
        'apellidos': apellidos,
        'email':     email,
        'telefono':  telefono,
        'password':  password,
      },
      auth: false,
    );
    return _processAuthResponse(data);
  }


  /// GET /auth/me/  → perfil del usuario autenticado
  static Future<PropietarioModel> me() async {
    final data = await ApiClient.get('/auth/me/');
    return PropietarioModel.fromJson(data);
  }

  /// POST /auth/logout/  → invalida el refresh token
  static Future<void> logout() async {
    try {
      final refresh = await StorageService.getRefreshToken();
      if (refresh != null) {
        await ApiClient.post('/auth/logout/', {'refresh': refresh});
      }
    } catch (_) {
      // Si el token ya expiró o hay red caída, igual limpiamos local
    } finally {
      await StorageService.clear();
    }
  }

  // ── Helpers internos ──────────────────────────────────────────
  static Future<AuthResult> _processAuthResponse(dynamic data) async {
    final propietario = PropietarioModel.fromJson(
      data['propietario'] as Map<String, dynamic>,
    );
    final access  = data['tokens']['access']  as String;
    final refresh = data['tokens']['refresh'] as String;

    await StorageService.saveTokens(access: access, refresh: refresh);
    await StorageService.saveUser(
      id:     propietario.id,
      rol:    propietario.rol,
      nombre: propietario.nombreCompleto,
    );

    return AuthResult(
      propietario:  propietario,
      accessToken:  access,
      refreshToken: refresh,
    );
  }

  /// POST /auth/cambio-password/
  static Future<void> cambiarPassword({
    required String passwordActual,
    required String passwordNuevo,
  }) async {
    await ApiClient.post('/auth/cambio-password/', {
      'password_actual': passwordActual,
      'password_nuevo':  passwordNuevo,
    });
  }
}
