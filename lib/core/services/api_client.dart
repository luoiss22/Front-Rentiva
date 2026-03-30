import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'storage_service.dart';

/// Error tipado que incluye el código HTTP y el mensaje del backend.
class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);

  @override
  String toString() => message;
}

class ApiClient {
  // -----------------------------------------------------------
  // CONFIGURA AQUÍ TU URL BASE
  // Android emulator → 10.0.2.2  |  iOS sim / Web → localhost
  // -----------------------------------------------------------
  static const String baseUrl = 'http://23.94.202.152:8080/api/v1';
  // static const String baseUrl = 'http://localhost:8000/api/v1';

  /// Bandera para evitar loops infinitos de refresh
  static bool _isRefreshing = false;

  // ── Headers ─────────────────────────────────────────────────
  static Future<Map<String, String>> _headers({bool auth = true}) async {
    final h = <String, String>{'Content-Type': 'application/json'};
    if (auth) {
      final token = await StorageService.getAccessToken();
      if (token != null) h['Authorization'] = 'Bearer $token';
    }
    return h;
  }

  // ── Parsear respuesta ────────────────────────────────────────
  static dynamic _parse(http.Response response) {
    final body = utf8.decode(response.bodyBytes);
    final data = jsonDecode(body);
    if (response.statusCode >= 200 && response.statusCode < 300) return data;

    String msg = 'Error desconocido';
    if (data is Map) {
      if (data.containsKey('detail')) {
        msg = data['detail'].toString();
      } else {
        msg = data.entries.map((e) {
          final v = e.value;
          return v is List ? v.join(', ') : v.toString();
        }).join(' | ');
      }
    }
    throw ApiException(response.statusCode, msg);
  }

  // ── Métodos HTTP con retry automático en 401 ─────────────────
  static Future<dynamic> get(String path, {bool auth = true}) async {
    return _withRetry(() async {
      final res = await http.get(
        Uri.parse('$baseUrl$path'),
        headers: await _headers(auth: auth),
      );
      return res;
    }, auth: auth);
  }

  static Future<dynamic> post(
    String path,
    Map<String, dynamic> body, {
    bool auth = true,
  }) async {
    return _withRetry(() async {
      final res = await http.post(
        Uri.parse('$baseUrl$path'),
        headers: await _headers(auth: auth),
        body: jsonEncode(body),
      );
      return res;
    }, auth: auth);
  }

  static Future<dynamic> patch(
    String path,
    Map<String, dynamic> body, {
    bool auth = true,
  }) async {
    return _withRetry(() async {
      final res = await http.patch(
        Uri.parse('$baseUrl$path'),
        headers: await _headers(auth: auth),
        body: jsonEncode(body),
      );
      return res;
    }, auth: auth);
  }

  static Future<dynamic> delete(String path, {bool auth = true}) async {
    return _withRetry(() async {
      final res = await http.delete(
        Uri.parse('$baseUrl$path'),
        headers: await _headers(auth: auth),
      );
      return res;
    }, auth: auth);
  }

  /// Ejecuta el request. Si recibe 401 y auth=true, intenta refresh y reintenta una vez.
  static Future<dynamic> _withRetry(
    Future<http.Response> Function() request, {
    bool auth = true,
  }) async {
    final response = await request();

    if (response.statusCode == 401 && auth && !_isRefreshing) {
      final refreshed = await refreshToken();
      if (refreshed) {
        // Reintentar con el nuevo token
        final retryResponse = await request();
        return _parse(retryResponse);
      }
    }

    return _parse(response);
  }

  // ── Multipart (subida de archivos) ───────────────────────────
  static Future<dynamic> multipart(
    String method,
    String path, {
    Map<String, String>? fields,
    File? file,
    Uint8List? webFileBytes,
    String? webFileName,
    String fileField = 'foto',
    bool auth = true,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final request = http.MultipartRequest(method.toUpperCase(), uri);

    if (auth) {
      final token = await StorageService.getAccessToken();
      if (token != null) request.headers['Authorization'] = 'Bearer $token';
    }

    if (fields != null) request.fields.addAll(fields);

    if (file != null) {
      final ext = file.path.split('.').last.toLowerCase();
      final mime = _mimeFromExt(ext);
      request.files.add(
        await http.MultipartFile.fromPath(fileField, file.path, contentType: mime),
      );
    } else if (webFileBytes != null) {
      final String filename = webFileName ?? 'imagen.jpg';
      final ext = filename.split('.').last.toLowerCase();
      final mime = _mimeFromExt(ext);
      request.files.add(
        http.MultipartFile.fromBytes(
          fileField,
          webFileBytes,
          filename: filename,
          contentType: mime,
        ),
      );
    }

    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    return _parse(res);
  }

  static MediaType _mimeFromExt(String ext) {
    switch (ext) {
      case 'png':  return MediaType('image', 'png');
      case 'gif':  return MediaType('image', 'gif');
      case 'webp': return MediaType('image', 'webp');
      case 'pdf':  return MediaType('application', 'pdf');
      case 'doc':  return MediaType('application', 'msword');
      case 'docx': return MediaType('application', 'vnd.openxmlformats-officedocument.wordprocessingml.document');
      case 'xls':  return MediaType('application', 'vnd.ms-excel');
      case 'xlsx': return MediaType('application', 'vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      default:     return MediaType('image', 'jpeg');
    }
  }

  // ── Refresh de token ─────────────────────────────────────────
  static Future<bool> refreshToken() async {
    if (_isRefreshing) return false;
    _isRefreshing = true;
    try {
      final refresh = await StorageService.getRefreshToken();
      if (refresh == null) return false;
      final res = await http.post(
        Uri.parse('$baseUrl/auth/token/refresh/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': refresh}),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        await StorageService.saveTokens(
          access: data['access'],
          refresh: data['refresh'] ?? refresh,
        );
        return true;
      }
    } catch (_) {
      // Refresh falló, el usuario deberá loguearse de nuevo
    } finally {
      _isRefreshing = false;
    }
    return false;
  }
}
