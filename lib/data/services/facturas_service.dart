import '../../core/services/api_client.dart';

// ── Modelo ─────────────────────────────────────────────────────────────────────

class FacturaItem {
  final int id;
  final int pago;
  final String folioFiscal;
  final int datosFiscalesEmisor;
  final int datosFiscalesReceptor;
  final double subtotal;
  final double iva;
  final double total;
  final String? xmlPath;
  final String? pdfPath;
  final String fechaEmision;

  const FacturaItem({
    required this.id,
    required this.pago,
    required this.folioFiscal,
    required this.datosFiscalesEmisor,
    required this.datosFiscalesReceptor,
    required this.subtotal,
    required this.iva,
    required this.total,
    this.xmlPath,
    this.pdfPath,
    required this.fechaEmision,
  });

  factory FacturaItem.fromJson(Map<String, dynamic> json) {
    return FacturaItem(
      id:                     json['id'] as int,
      pago:                   json['pago'] as int,
      folioFiscal:            json['folio_fiscal'] ?? '',
      datosFiscalesEmisor:    json['datos_fiscales_emisor'] as int,
      datosFiscalesReceptor:  json['datos_fiscales_receptor'] as int,
      subtotal:  double.tryParse(json['subtotal'].toString()) ?? 0,
      iva:       double.tryParse(json['iva'].toString()) ?? 0,
      total:     double.tryParse(json['total'].toString()) ?? 0,
      xmlPath:   json['xml_path'] as String?,
      pdfPath:   json['pdf_path'] as String?,
      fechaEmision: json['fecha_emision'] ?? '',
    );
  }
}

// ── Servicio ───────────────────────────────────────────────────────────────────

class FacturasService {
  /// GET /facturas/?pago=...
  static Future<List<FacturaItem>> listar({int? pagoId}) async {
    final q = pagoId != null ? '?pago=$pagoId' : '';
    final data = await ApiClient.get('/facturas/$q');
    final results = data is Map && data.containsKey('results')
        ? data['results'] as List
        : data as List;
    return results.map((e) => FacturaItem.fromJson(e)).toList();
  }

  /// GET /facturas/{id}/
  static Future<FacturaItem> detalle(int id) async {
    final data = await ApiClient.get('/facturas/$id/');
    return FacturaItem.fromJson(data);
  }

  /// POST /facturas/
  static Future<FacturaItem> crear(Map<String, dynamic> body) async {
    final data = await ApiClient.post('/facturas/', body);
    return FacturaItem.fromJson(data);
  }

  /// PATCH /facturas/{id}/
  static Future<FacturaItem> actualizar(
    int id, Map<String, dynamic> body,
  ) async {
    final data = await ApiClient.patch('/facturas/$id/', body);
    return FacturaItem.fromJson(data);
  }

  /// DELETE /facturas/{id}/
  static Future<void> eliminar(int id) async {
    await ApiClient.delete('/facturas/$id/');
  }
}
