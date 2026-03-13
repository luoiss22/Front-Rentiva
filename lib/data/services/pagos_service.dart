import '../../core/services/api_client.dart';

// ── Modelos ────────────────────────────────────────────────────────────────────

class PagoItem {
  final int id;
  final int contratoId;
  final String periodo;
  final double monto;
  final String fechaLimite;
  final String? fechaPago;
  final String estado;
  final double recargaMora;

  const PagoItem({
    required this.id,
    required this.contratoId,
    required this.periodo,
    required this.monto,
    required this.fechaLimite,
    this.fechaPago,
    required this.estado,
    required this.recargaMora,
  });

  factory PagoItem.fromJson(Map<String, dynamic> json) {
    return PagoItem(
      id: json['id'] as int,
      contratoId: json['contrato_id'] as int,
      periodo: json['periodo'] ?? '',
      monto: double.tryParse(json['monto'].toString()) ?? 0,
      fechaLimite: json['fecha_limite'] ?? '',
      fechaPago: json['fecha_pago'] as String?,
      estado: json['estado'] ?? 'pendiente',
      recargaMora: double.tryParse(json['recargo_mora'].toString()) ?? 0,
    );
  }
}

class PagoDetalle {
  final int id;
  final String periodo;
  final double monto;
  final String fechaLimite;
  final String? fechaPago;
  final String? metodoPago;
  final String referencia;
  final String? comprobanteUrl;
  final double recargaMora;
  final String estado;
  final String createdAt;
  final Map<String, dynamic>? ficha;
  final Map<String, dynamic>? factura;

  const PagoDetalle({
    required this.id,
    required this.periodo,
    required this.monto,
    required this.fechaLimite,
    this.fechaPago,
    this.metodoPago,
    required this.referencia,
    this.comprobanteUrl,
    required this.recargaMora,
    required this.estado,
    required this.createdAt,
    this.ficha,
    this.factura,
  });

  factory PagoDetalle.fromJson(Map<String, dynamic> json) {
    return PagoDetalle(
      id: json['id'] as int,
      periodo: json['periodo'] ?? '',
      monto: double.tryParse(json['monto'].toString()) ?? 0,
      fechaLimite: json['fecha_limite'] ?? '',
      fechaPago: json['fecha_pago'] as String?,
      metodoPago: json['metodo_pago'] as String?,
      referencia: json['referencia'] ?? '',
      comprobanteUrl: json['comprobante_url'] as String?,
      recargaMora: double.tryParse(json['recargo_mora'].toString()) ?? 0,
      estado: json['estado'] ?? 'pendiente',
      createdAt: json['created_at'] ?? '',
      ficha: json['ficha'] as Map<String, dynamic>?,
      factura: json['factura'] as Map<String, dynamic>?,
    );
  }
}

// ── Servicio ───────────────────────────────────────────────────────────────────

class PagosService {
  /// GET /pagos/?estado=...&contrato=...&page=N
  static Future<List<PagoItem>> listar({
    String? estado,
    int? contratoId,
    int page = 1,
  }) async {
    final params = <String, String>{'page': page.toString()};
    if (estado != null) params['estado'] = estado;
    if (contratoId != null) params['contrato'] = contratoId.toString();

    final query = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    final data = await ApiClient.get('/pagos/?$query');
    final results = data['results'] as List;
    return results.map((e) => PagoItem.fromJson(e)).toList();
  }

  /// GET /pagos/{id}/
  static Future<PagoDetalle> detalle(int id) async {
    final data = await ApiClient.get('/pagos/$id/');
    return PagoDetalle.fromJson(data);
  }

  /// POST /pagos/
  static Future<PagoDetalle> crear(Map<String, dynamic> body) async {
    final data = await ApiClient.post('/pagos/', body);
    return PagoDetalle.fromJson(data);
  }

  /// PATCH /pagos/{id}/
  static Future<PagoDetalle> actualizar(int id, Map<String, dynamic> body) async {
    final data = await ApiClient.patch('/pagos/$id/', body);
    return PagoDetalle.fromJson(data);
  }

  /// DELETE /pagos/{id}/
  static Future<void> eliminar(int id) async {
    await ApiClient.delete('/pagos/$id/');
  }
}
