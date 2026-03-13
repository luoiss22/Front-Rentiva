import '../../core/services/api_client.dart';

// ── Modelos ────────────────────────────────────────────────────────────────────

class ContratoItem {
  final int id;
  final int propiedadId;
  final String propiedadNombre;
  final int arrendatarioId;
  final String arrendatarioNombre;
  final String fechaInicio;
  final String fechaFin;
  final double rentaAcordada;
  final String periodoPago;
  final String estado;

  const ContratoItem({
    required this.id,
    required this.propiedadId,
    required this.propiedadNombre,
    required this.arrendatarioId,
    required this.arrendatarioNombre,
    required this.fechaInicio,
    required this.fechaFin,
    required this.rentaAcordada,
    required this.periodoPago,
    required this.estado,
  });

  factory ContratoItem.fromJson(Map<String, dynamic> json) {
    return ContratoItem(
      id: json['id'] as int,
      propiedadId: json['propiedad'] as int,
      propiedadNombre: json['propiedad_nombre'] ?? '',
      arrendatarioId: json['arrendatario'] as int,
      arrendatarioNombre: json['arrendatario_nombre'] ?? '',
      fechaInicio: json['fecha_inicio'] ?? '',
      fechaFin: json['fecha_fin'] ?? '',
      rentaAcordada: double.tryParse(json['renta_acordada'].toString()) ?? 0,
      periodoPago: json['periodo_pago'] ?? 'mensual',
      estado: json['estado'] ?? 'borrador',
    );
  }
}

// ── Servicio ───────────────────────────────────────────────────────────────────

class ContratosService {
  /// GET /contratos/?estado=...&propiedad=...&page=N
  static Future<List<ContratoItem>> listar({
    String? estado,
    int? propiedadId,
    int? arrendatarioId,
    int page = 1,
  }) async {
    final params = <String, String>{'page': page.toString()};
    if (estado != null) params['estado'] = estado;
    if (propiedadId != null) params['propiedad'] = propiedadId.toString();
    if (arrendatarioId != null) params['arrendatario'] = arrendatarioId.toString();

    final query = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    final data = await ApiClient.get('/contratos/?$query');
    final results = data['results'] as List;
    return results.map((e) => ContratoItem.fromJson(e)).toList();
  }

  /// GET /contratos/{id}/
  static Future<Map<String, dynamic>> detalle(int id) async {
    return await ApiClient.get('/contratos/$id/');
  }

  /// POST /contratos/
  static Future<Map<String, dynamic>> crear(Map<String, dynamic> body) async {
    return await ApiClient.post('/contratos/', body);
  }

  /// PATCH /contratos/{id}/
  static Future<Map<String, dynamic>> actualizar(int id, Map<String, dynamic> body) async {
    return await ApiClient.patch('/contratos/$id/', body);
  }

  /// DELETE /contratos/{id}/
  static Future<void> eliminar(int id) async {
    await ApiClient.delete('/contratos/$id/');
  }
}
