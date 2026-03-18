import 'dart:convert';
import 'dart:io';
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
  static const String baseUrl = 'http://localhost:8000/api/v1';
  // static const String baseUrl = 'http://10.0.2.2:8000/api/v1'; // Android emulator

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

    // Construir mensaje de error desde DRF
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


  // ── Métodos HTTP ─────────────────────────────────────────────
  static Future<dynamic> get(String path, {bool auth = true}) async {
    final res = await http.get(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(auth: auth),
    );
    return _parse(res);
  }

  static Future<dynamic> post(
    String path,
    Map<String, dynamic> body, {
    bool auth = true,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(auth: auth),
      body: jsonEncode(body),
    );
    return _parse(res);
  }

  static Future<dynamic> patch(
    String path,
    Map<String, dynamic> body, {
    bool auth = true,
  }) async {
    final res = await http.patch(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(auth: auth),
      body: jsonEncode(body),
    );
    return _parse(res);
  }

  static Future<dynamic> delete(String path, {bool auth = true}) async {
    final res = await http.delete(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(auth: auth),
    );
    return _parse(res);
  }

  // ── Multipart (subida de archivos) ───────────────────────────
  static Future<dynamic> multipart(
    String method,
    String path, {
    Map<String, String>? fields,
    File? file,
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
      final mime = ext == 'png'
          ? MediaType('image', 'png')
          : MediaType('image', 'jpeg');
      request.files.add(
        await http.MultipartFile.fromPath(fileField, file.path, contentType: mime),
      );
    }

    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    return _parse(res);
  }

  // ── Refresh de token ─────────────────────────────────────────
  static Future<bool> refreshToken() async {
    final refresh = await StorageService.getRefreshToken();
    if (refresh == null) return false;
    try {
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
    } catch (_) {}
    return false;
  }
}
