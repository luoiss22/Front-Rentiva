import '../../core/services/api_client.dart';

// ── Modelos ────────────────────────────────────────────────────────────────────

/// Catálogo de mobiliario (modelo Mobiliario del backend).
class MobiliarioItem {
  final int id;
  final String nombre;
  final String tipo;
  final String? descripcion;

  const MobiliarioItem({
    required this.id,
    required this.nombre,
    required this.tipo,
    this.descripcion,
  });

  factory MobiliarioItem.fromJson(Map<String, dynamic> json) {
    return MobiliarioItem(
      id:          json['id'] as int,
      nombre:      json['nombre'] ?? '',
      tipo:        json['tipo'] ?? '',
      descripcion: json['descripcion'] as String?,
    );
  }
}

/// Relación mobiliario-propiedad (modelo PropiedadMobiliario del backend).
class PropiedadMobiliarioItem {
  final int id;
  final int propiedad;
  final int mobiliario;
  final String? mobiliarioNombre;
  final int cantidad;
  final double? valorEstimado;
  final String estado;

  const PropiedadMobiliarioItem({
    required this.id,
    required this.propiedad,
    required this.mobiliario,
    this.mobiliarioNombre,
    required this.cantidad,
    this.valorEstimado,
    required this.estado,
  });

  factory PropiedadMobiliarioItem.fromJson(Map<String, dynamic> json) {
    return PropiedadMobiliarioItem(
      id:                json['id'] as int,
      propiedad:         json['propiedad'] as int,
      mobiliario:        json['mobiliario'] as int,
      mobiliarioNombre:  json['mobiliario_nombre'] as String?,
      cantidad:          json['cantidad'] ?? 1,
      valorEstimado:     json['valor_estimado'] != null
          ? double.tryParse(json['valor_estimado'].toString())
          : null,
      estado:            json['estado'] ?? 'bueno',
    );
  }
}

// ── Servicio Catálogo Mobiliario ────────────────────────────────────────────

class MobiliarioService {
  /// GET /mobiliario/?search=...&page=N
  static Future<List<MobiliarioItem>> listar({
    String? busqueda,
    int page = 1,
  }) async {
    final params = <String, String>{'page': page.toString()};
    if (busqueda != null && busqueda.isNotEmpty) params['search'] = busqueda;

    final query = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    final data = await ApiClient.get('/mobiliario/?$query');
    final results = data is Map && data.containsKey('results')
        ? data['results'] as List
        : data as List;
    return results.map((e) => MobiliarioItem.fromJson(e)).toList();
  }

  /// GET /mobiliario/{id}/
  static Future<MobiliarioItem> detalle(int id) async {
    final data = await ApiClient.get('/mobiliario/$id/');
    return MobiliarioItem.fromJson(data);
  }

  /// POST /mobiliario/
  static Future<MobiliarioItem> crear(Map<String, dynamic> body) async {
    final data = await ApiClient.post('/mobiliario/', body);
    return MobiliarioItem.fromJson(data);
  }
}

// ── Servicio PropiedadMobiliario ───────────────────────────────────────────

class PropiedadMobiliarioService {
  /// GET /propiedad-mobiliario/?propiedad=...&page=N
  static Future<List<PropiedadMobiliarioItem>> listar({
    int? propiedadId,
    int page = 1,
  }) async {
    final params = <String, String>{'page': page.toString()};
    if (propiedadId != null) params['propiedad'] = propiedadId.toString();

    final query = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    final data = await ApiClient.get('/propiedad-mobiliario/?$query');
    final results = data is Map && data.containsKey('results')
        ? data['results'] as List
        : data as List;
    return results.map((e) => PropiedadMobiliarioItem.fromJson(e)).toList();
  }

  /// GET /propiedad-mobiliario/{id}/
  static Future<PropiedadMobiliarioItem> detalle(int id) async {
    final data = await ApiClient.get('/propiedad-mobiliario/$id/');
    return PropiedadMobiliarioItem.fromJson(data);
  }

  /// POST /propiedad-mobiliario/
  static Future<PropiedadMobiliarioItem> crear(Map<String, dynamic> body) async {
    final data = await ApiClient.post('/propiedad-mobiliario/', body);
    return PropiedadMobiliarioItem.fromJson(data);
  }

  /// PATCH /propiedad-mobiliario/{id}/
  static Future<PropiedadMobiliarioItem> actualizar(
    int id,
    Map<String, dynamic> body,
  ) async {
    final data = await ApiClient.patch('/propiedad-mobiliario/$id/', body);
    return PropiedadMobiliarioItem.fromJson(data);
  }

  /// DELETE /propiedad-mobiliario/{id}/
  static Future<void> eliminar(int id) async {
    await ApiClient.delete('/propiedad-mobiliario/$id/');
  }
}
