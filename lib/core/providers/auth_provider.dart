import 'package:flutter/foundation.dart';
import '../models/propietario_model.dart';
import '../models/admin_model.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

/// Estado global de autenticacion.
class AuthProvider extends ChangeNotifier {
  dynamic _usuario;
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

  /// Intenta restaurar la sesion al abrir la app o hacer F5.
  Future<void> inicializar() async {
    _cargando = true;
    notifyListeners();

    final loggedIn = await StorageService.isLoggedIn();
    if (!loggedIn) {
      _cargando = false;
      notifyListeners();
      return;
    }

    // Intento 1: access token vigente
    try {
      final result = await AuthService.me();
      _usuario = result.usuario;
      _userType = result.userType;
      _cargando = false;
      notifyListeners();
      return;
    } on ApiException catch (e) {
      // Solo si es 401 intentamos refresh; cualquier otro error (red, etc.) no borra sesión
      if (e.statusCode != 401) {
        // Error de red u otro — mantenemos la sesión guardada, dejamos al usuario entrar
        _cargando = false;
        notifyListeners();
        return;
      }
    } catch (_) {
      // Error inesperado de red — no borrar sesión
      _cargando = false;
      notifyListeners();
      return;
    }

    // Intento 2: access expiró (401) — hacer refresh y reintentar
    try {
      final refreshed = await ApiClient.refreshToken();
      if (refreshed) {
        final result = await AuthService.me();
        _usuario = result.usuario;
        _userType = result.userType;
      } else {
        // Refresh token también expiró — sesión inválida, limpiar
        await StorageService.clear();
      }
    } catch (_) {
      // Refresh falló por red — no borrar, dejar tokens para el próximo intento
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
    final result = await AuthService.login(email: email, password: password);
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
