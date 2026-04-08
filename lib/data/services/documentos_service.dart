import 'dart:io';
import '../../core/services/api_client.dart';

// ── Modelos ────────────────────────────────────────────────────────────────────

class DocumentoItem {
  final int id;
  final String tipoEntidad;
  final int entidadId;
  final String tipoDocumento;
  final String nombreArchivo;
  final String createdAt;

  const DocumentoItem({
    required this.id,
    required this.tipoEntidad,
    required this.entidadId,
    required this.tipoDocumento,
    required this.nombreArchivo,
    required this.createdAt,
  });

  factory DocumentoItem.fromJson(Map<String, dynamic> json) {
    return DocumentoItem(
      id:             json['id'] as int,
      tipoEntidad:    json['tipo_entidad'] ?? '',
      entidadId:      json['entidad_id'] as int,
      tipoDocumento:  json['tipo_documento'] ?? '',
      nombreArchivo:  json['nombre_archivo'] ?? '',
      createdAt:      json['created_at'] ?? '',
    );
  }
}

class DocumentoDetalle {
  final int id;
  final String tipoEntidad;
  final int entidadId;
  final String tipoDocumento;
  final String nombreArchivo;
  final String? rutaArchivo;
  final String descripcion;
  final String createdAt;

  const DocumentoDetalle({
    required this.id,
    required this.tipoEntidad,
    required this.entidadId,
    required this.tipoDocumento,
    required this.nombreArchivo,
    this.rutaArchivo,
    required this.descripcion,
    required this.createdAt,
  });

  factory DocumentoDetalle.fromJson(Map<String, dynamic> json) {
    return DocumentoDetalle(
      id:             json['id'] as int,
      tipoEntidad:    json['tipo_entidad'] ?? '',
      entidadId:      json['entidad_id'] as int,
      tipoDocumento:  json['tipo_documento'] ?? '',
      nombreArchivo:  json['nombre_archivo'] ?? '',
      rutaArchivo:    json['ruta_archivo'] as String?,
      descripcion:    json['descripcion'] ?? '',
      createdAt:      json['created_at'] ?? '',
    );
  }
}

// ── Servicio ───────────────────────────────────────────────────────────────────

class DocumentosService {
  /// GET /documentos/?tipo_entidad=...&entidad_id=...&page=N
  static Future<List<DocumentoItem>> listar({
    String? tipoEntidad,
    int? entidadId,
    int page = 1,
  }) async {
    final params = <String, String>{'page': page.toString()};
    if (tipoEntidad != null) params['tipo_entidad'] = tipoEntidad;
    if (entidadId != null) params['entidad_id'] = entidadId.toString();

    final query = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    final data = await ApiClient.get('/documentos/?$query');
    final results = data is Map && data.containsKey('results')
        ? data['results'] as List
        : data as List;
    return results.map((e) => DocumentoItem.fromJson(e)).toList();
  }

  /// GET /documentos/{id}/
  static Future<DocumentoDetalle> detalle(int id) async {
    final data = await ApiClient.get('/documentos/$id/');
    return DocumentoDetalle.fromJson(data);
  }

  /// POST /documentos/ (multipart — sube archivo)
  static Future<DocumentoDetalle> subir({
    required String tipoEntidad,
    required int entidadId,
    required String tipoDocumento,
    required String nombreArchivo,
    required File archivo,
    String descripcion = '',
  }) async {
    const maxBytes = 20 * 1024 * 1024; // 20 MB — mismo límite que nginx
    final size = await archivo.length();
    if (size > maxBytes) {
      final mb = (size / (1024 * 1024)).toStringAsFixed(1);
      throw Exception('El archivo pesa ${mb} MB. El límite es 20 MB. Comprime o elige otro archivo.');
    }

    final data = await ApiClient.multipart(
      'POST',
      '/documentos/',
      fields: {
        'tipo_entidad':   tipoEntidad,
        'entidad_id':     entidadId.toString(),
        'tipo_documento': tipoDocumento,
        'nombre_archivo': nombreArchivo,
        'descripcion':    descripcion,
      },
      file: archivo,
      fileField: 'ruta_archivo',
    );
    return DocumentoDetalle.fromJson(data);
  }

  /// DELETE /documentos/{id}/
  static Future<void> eliminar(int id) async {
    await ApiClient.delete('/documentos/$id/');
  }
}
