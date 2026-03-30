import 'package:flutter/foundation.dart';
import '../models/propietario_model.dart';
import '../models/admin_model.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

/// Estado global de autenticacion.
class AuthProvider extends ChangeNotifier {
  dynamic _usuario; // PropietarioModel o AdminModel
  String _userType = 'propietario';
  bool _cargando = true;

  dynamic get usuario => _usuario;
  String get userType => _userType;
  bool get cargando => _cargando;
  bool get estaAutenticado => _usuario != null;
  bool get esAdmin => _userType == 'admin';

  String get nombreCompleto {
    if (_usuario is PropietarioModel) return (_usuario as PropietarioModel).nombreCompleto;
    if (_usuario is AdminModel) return (_usuario as AdminModel).nombreCompleto;
    return '';
  }

  /// Intenta restaurar la sesion al abrir la app.
  Future<void> inicializar() async {
    _cargando = true;
    notifyListeners();
    try {
      final loggedIn = await StorageService.isLoggedIn();
      if (!loggedIn) {
        _cargando = false;
        notifyListeners();
        return;
      }
      // Intento 1: con el access token actual
      try {
        final result = await AuthService.me();
        _usuario = result.usuario;
        _userType = result.userType;
        return;
      } catch (_) {
        // Access token vencido — intentar refresh antes de rendirse
      }
      // Intento 2: refrescar el token y reintentar
      final refreshed = await ApiClient.refreshToken();
      if (refreshed) {
        final result = await AuthService.me();
        _usuario = result.usuario;
        _userType = result.userType;
      } else {
        // Refresh también falló — sesión inválida, limpiar
        _usuario = null;
        _userType = 'propietario';
        await StorageService.clear();
      }
    } catch (_) {
      _usuario = null;
      _userType = 'propietario';
      await StorageService.clear();
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  /// Login: guarda tokens y actualiza el estado global.
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final result = await AuthService.login(
      email: email,
      password: password,
    );
    _usuario = result.usuario;
    _userType = result.userType;
    notifyListeners();
    return result;
  }

  /// Registro: crea cuenta propietario.
  Future<AuthResult> register({
    required String nombre,
    required String apellidos,
    required String email,
    required String telefono,
    required String password,
  }) async {
    final result = await AuthService.register(
      nombre: nombre,
      apellidos: apellidos,
      email: email,
      telefono: telefono,
      password: password,
    );
    _usuario = result.usuario;
    _userType = result.userType;
    notifyListeners();
    return result;
  }

  /// Cierra sesion y limpia el estado.
  Future<void> logout() async {
    await AuthService.logout();
    _usuario = null;
    _userType = 'propietario';
    notifyListeners();
  }

  /// Refresca los datos del usuario desde el backend.
  Future<void> refrescarPerfil() async {
    try {
      final result = await AuthService.me();
      _usuario = result.usuario;
      _userType = result.userType;
      notifyListeners();
    } catch (_) {}
  }
}
