import '../../core/services/api_client.dart';

// ── Modelos ────────────────────────────────────────────────────────────────────

class DatosFiscalesItem {
  final int id;
  final String tipoEntidad;
  final int entidadId;
  final String rfc;
  final String nombreORazonSocial;

  const DatosFiscalesItem({
    required this.id,
    required this.tipoEntidad,
    required this.entidadId,
    required this.rfc,
    required this.nombreORazonSocial,
  });

  factory DatosFiscalesItem.fromJson(Map<String, dynamic> json) {
    return DatosFiscalesItem(
      id:                  json['id'] as int,
      tipoEntidad:         json['tipo_entidad'] ?? '',
      entidadId:           json['entidad_id'] as int,
      rfc:                 json['rfc'] ?? '',
      nombreORazonSocial:  json['nombre_o_razon_social'] ?? '',
    );
  }
}

class DatosFiscalesDetalle {
  final int id;
  final String tipoEntidad;
  final int entidadId;
  final String nombreORazonSocial;
  final String rfc;
  final String regimenFiscal;
  final String usoCfdi;
  final String codigoPostal;
  final String correoFacturacion;
  final String createdAt;
  final String updatedAt;

  const DatosFiscalesDetalle({
    required this.id,
    required this.tipoEntidad,
    required this.entidadId,
    required this.nombreORazonSocial,
    required this.rfc,
    required this.regimenFiscal,
    required this.usoCfdi,
    required this.codigoPostal,
    required this.correoFacturacion,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DatosFiscalesDetalle.fromJson(Map<String, dynamic> json) {
    return DatosFiscalesDetalle(
      id:                  json['id'] as int,
      tipoEntidad:         json['tipo_entidad'] ?? '',
      entidadId:           json['entidad_id'] as int,
      nombreORazonSocial:  json['nombre_o_razon_social'] ?? '',
      rfc:                 json['rfc'] ?? '',
      regimenFiscal:       json['regimen_fiscal'] ?? '',
      usoCfdi:             json['uso_cfdi'] ?? '',
      codigoPostal:        json['codigo_postal'] ?? '',
      correoFacturacion:   json['correo_facturacion'] ?? '',
      createdAt:           json['created_at'] ?? '',
      updatedAt:           json['updated_at'] ?? '',
    );
  }
}

// ── Servicio ───────────────────────────────────────────────────────────────────

class DatosFiscalesService {
  /// GET /datos-fiscales/?tipo_entidad=...&entidad_id=...&page=N
  static Future<List<DatosFiscalesItem>> listar({
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

    final data = await ApiClient.get('/datos-fiscales/?$query');
    final results = data is Map && data.containsKey('results')
        ? data['results'] as List
        : data as List;
    return results
        .map((e) => DatosFiscalesItem.fromJson(e))
        .toList();
  }

  /// GET /datos-fiscales/{id}/
  static Future<DatosFiscalesDetalle> detalle(int id) async {
    final data = await ApiClient.get('/datos-fiscales/$id/');
    return DatosFiscalesDetalle.fromJson(data);
  }

  /// POST /datos-fiscales/
  static Future<DatosFiscalesDetalle> crear(
    Map<String, dynamic> body,
  ) async {
    final data = await ApiClient.post('/datos-fiscales/', body);
    return DatosFiscalesDetalle.fromJson(data);
  }

  /// PATCH /datos-fiscales/{id}/
  static Future<DatosFiscalesDetalle> actualizar(
    int id,
    Map<String, dynamic> body,
  ) async {
    final data = await ApiClient.patch('/datos-fiscales/$id/', body);
    return DatosFiscalesDetalle.fromJson(data);
  }

  /// DELETE /datos-fiscales/{id}/
  static Future<void> eliminar(int id) async {
    await ApiClient.delete('/datos-fiscales/$id/');
  }
}
