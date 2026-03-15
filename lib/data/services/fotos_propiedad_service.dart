import 'dart:io';
import '../../core/services/api_client.dart';

// ── Modelo ─────────────────────────────────────────────────────────────────────

class FotoPropiedadItem {
  final int id;
  final int propiedad;
  final String? imagen;
  final String? descripcion;
  final bool esPrincipal;
  final int orden;
  final String createdAt;

  const FotoPropiedadItem({
    required this.id,
    required this.propiedad,
    this.imagen,
    this.descripcion,
    required this.esPrincipal,
    required this.orden,
    required this.createdAt,
  });

  factory FotoPropiedadItem.fromJson(Map<String, dynamic> json) {
    return FotoPropiedadItem(
      id:           json['id'] as int,
      propiedad:    json['propiedad'] as int,
      imagen:       json['imagen'] as String?,
      descripcion:  json['descripcion'] as String?,
      esPrincipal:  json['es_principal'] ?? false,
      orden:        json['orden'] ?? 0,
      createdAt:    json['created_at'] ?? '',
    );
  }
}

// ── Servicio ───────────────────────────────────────────────────────────────────

class FotosPropiedadService {
  /// GET /fotos-propiedad/?propiedad=...
  static Future<List<FotoPropiedadItem>> listar({required int propiedadId}) async {
    final data = await ApiClient.get('/fotos-propiedad/?propiedad=$propiedadId');
    final results = data is Map && data.containsKey('results')
        ? data['results'] as List
        : data as List;
    return results.map((e) => FotoPropiedadItem.fromJson(e)).toList();
  }

  /// POST /fotos-propiedad/ (multipart)
  static Future<FotoPropiedadItem> subir({
    required int propiedadId,
    required File imagen,
    String? descripcion,
    bool esPrincipal = false,
    int orden = 0,
  }) async {
    final data = await ApiClient.multipart(
      'POST',
      '/fotos-propiedad/',
      fields: {
        'propiedad': propiedadId.toString(),
        'es_principal': esPrincipal.toString(),
        'orden': orden.toString(),
        if (descripcion != null) 'descripcion': descripcion,
      },
      file: imagen,
      fileField: 'imagen',
    );
    return FotoPropiedadItem.fromJson(data);
  }

  /// DELETE /fotos-propiedad/{id}/
  static Future<void> eliminar(int id) async {
    await ApiClient.delete('/fotos-propiedad/$id/');
  }

  /// PATCH /fotos-propiedad/{id}/
  static Future<FotoPropiedadItem> actualizar(
    int id,
    Map<String, dynamic> body,
  ) async {
    final data = await ApiClient.patch('/fotos-propiedad/$id/', body);
    return FotoPropiedadItem.fromJson(data);
  }
}
