import '../../core/services/api_client.dart';

// ── Modelo ─────────────────────────────────────────────────────────────────────

class FichaPagoItem {
  final int id;
  final int pago;
  final String codigoReferencia;
  final String clabeInterbancaria;
  final String banco;
  final String? archivoPdf;
  final String fechaGeneracion;

  const FichaPagoItem({
    required this.id,
    required this.pago,
    required this.codigoReferencia,
    required this.clabeInterbancaria,
    required this.banco,
    this.archivoPdf,
    required this.fechaGeneracion,
  });

  factory FichaPagoItem.fromJson(Map<String, dynamic> json) {
    return FichaPagoItem(
      id:                  json['id'] as int,
      pago:                json['pago'] as int,
      codigoReferencia:    json['codigo_referencia'] ?? '',
      clabeInterbancaria:  json['clabe_interbancaria'] ?? '',
      banco:               json['banco'] ?? '',
      archivoPdf:          json['archivo_pdf'] as String?,
      fechaGeneracion:     json['fecha_generacion'] ?? '',
    );
  }
}

// ── Servicio ───────────────────────────────────────────────────────────────────

class FichasPagoService {
  /// GET /fichas-pago/?pago=...
  static Future<List<FichaPagoItem>> listar({int? pagoId}) async {
    final q = pagoId != null ? '?pago=$pagoId' : '';
    final data = await ApiClient.get('/fichas-pago/$q');
    final results = data is Map && data.containsKey('results')
        ? data['results'] as List
        : data as List;
    return results.map((e) => FichaPagoItem.fromJson(e)).toList();
  }

  /// GET /fichas-pago/{id}/
  static Future<FichaPagoItem> detalle(int id) async {
    final data = await ApiClient.get('/fichas-pago/$id/');
    return FichaPagoItem.fromJson(data);
  }

  /// POST /fichas-pago/
  static Future<FichaPagoItem> crear(Map<String, dynamic> body) async {
    final data = await ApiClient.post('/fichas-pago/', body);
    return FichaPagoItem.fromJson(data);
  }

  /// PATCH /fichas-pago/{id}/
  static Future<FichaPagoItem> actualizar(
    int id, Map<String, dynamic> body,
  ) async {
    final data = await ApiClient.patch('/fichas-pago/$id/', body);
    return FichaPagoItem.fromJson(data);
  }

  /// DELETE /fichas-pago/{id}/
  static Future<void> eliminar(int id) async {
    await ApiClient.delete('/fichas-pago/$id/');
  }
}
