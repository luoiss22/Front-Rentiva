import 'api_client.dart';
import 'storage_service.dart';
import '../models/propietario_model.dart';
import '../models/admin_model.dart';

class AuthResult {
  /// Puede ser PropietarioModel o AdminModel
  final dynamic usuario;
  final String userType; // 'admin' o 'propietario'
  final String accessToken;
  final String refreshToken;

  AuthResult({
    required this.usuario,
    required this.userType,
    required this.accessToken,
    required this.refreshToken,
  });

  bool get esAdmin => userType == 'admin';

  String get nombre {
    if (usuario is PropietarioModel) return (usuario as PropietarioModel).nombreCompleto;
    if (usuario is AdminModel) return (usuario as AdminModel).nombreCompleto;
    return '';
  }
}

class AuthService {
  /// POST /auth/login/
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

  /// POST /auth/registro/
  static Future<AuthResult> register({
    required String nombre,
    required String apellidos,
    required String email,
    required String telefono,
    required String password,
    String? fechaNacimiento,
    String? folioIne,
  }) async {
    final payload = <String, dynamic>{
      'nombre': nombre,
      'apellidos': apellidos,
      'email': email,
      'telefono': telefono,
      'password': password,
    };
    if (fechaNacimiento != null && fechaNacimiento.isNotEmpty) {
      payload['fecha_nacimiento'] = fechaNacimiento;
    }
    if (folioIne != null && folioIne.isNotEmpty) {
      payload['folio_ine'] = folioIne;
    }

    final data = await ApiClient.post(
      '/auth/registro/',
      payload,
      auth: false,
    );
    return _processAuthResponse(data);
  }

  /// GET /auth/me/ — perfil del usuario autenticado
  static Future<AuthResult> me() async {
    final data = await ApiClient.get('/auth/me/');
    final userType = data['user_type'] as String? ?? 'propietario';
    final userData = data['usuario'] as Map<String, dynamic>;

    dynamic usuario;
    if (userType == 'admin') {
      usuario = AdminModel.fromJson(userData);
    } else {
      usuario = PropietarioModel.fromJson(userData);
    }

    return AuthResult(
      usuario: usuario,
      userType: userType,
      accessToken: '',
      refreshToken: '',
    );
  }

  /// POST /auth/logout/
  static Future<void> logout() async {
    try {
      final refresh = await StorageService.getRefreshToken();
      if (refresh != null) {
        await ApiClient.post('/auth/logout/', {'refresh': refresh});
      }
    } catch (_) {
    } finally {
      await StorageService.clear();
    }
  }

  // ── Helper interno ────────────────────────────────────────────
  static Future<AuthResult> _processAuthResponse(dynamic data) async {
    final userType = data['user_type'] as String? ?? 'propietario';
    final userData = data['usuario'] as Map<String, dynamic>;
    final access = data['tokens']['access'] as String;
    final refresh = data['tokens']['refresh'] as String;

    dynamic usuario;
    if (userType == 'admin') {
      usuario = AdminModel.fromJson(userData);
    } else {
      usuario = PropietarioModel.fromJson(userData);
    }

    await StorageService.saveTokens(access: access, refresh: refresh);
    await StorageService.saveUser(
      id:              userData['id'] as int,
      rol:             userType,
      nombre:          userType == 'admin'
          ? (usuario as AdminModel).nombreCompleto
          : (usuario as PropietarioModel).nombreCompleto,
      fechaNacimiento: userData['fecha_nacimiento'] as String?,
      folioIne:        userData['folio_ine'] as String?,
      email:           userData['email'] as String?,
      telefono:        userData['telefono'] as String?,
    );

    return AuthResult(
      usuario: usuario,
      userType: userType,
      accessToken: access,
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
      'password_nuevo': passwordNuevo,
    });
  }
}
