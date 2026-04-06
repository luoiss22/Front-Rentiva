import '../../core/services/api_client.dart';

// ── Modelos ────────────────────────────────────────────────────────────────────

/// Versión ligera para el listado (ArrendatarioListSerializer).
class ArrendatarioItem {
  final int id;
  final String nombre;
  final String apellidos;
  final String email;
  final String telefono;
  final String estado;
  final String propiedadActual;

  const ArrendatarioItem({
    required this.id,
    required this.nombre,
    required this.apellidos,
    required this.email,
    required this.telefono,
    required this.estado,
    required this.propiedadActual,
  });

  factory ArrendatarioItem.fromJson(Map<String, dynamic> json) {
    return ArrendatarioItem(
      id:        json['id'] as int,
      nombre:    json['nombre']    ?? '',
      apellidos: json['apellidos'] ?? '',
      email:     json['email']     ?? '',
      telefono:  json['telefono']  ?? '',
      estado:    json['estado']    ?? 'activo',
      propiedadActual: json['propiedad_actual'] ?? 'Sin propiedad',
    );
  }

  String get nombreCompleto => '$nombre $apellidos'.trim();
  String get inicial => nombre.isNotEmpty ? nombre[0].toUpperCase() : '?';
}

/// Versión completa para detalle / edición (ArrendatarioSerializer).
class ArrendatarioDetalle {
  final int id;
  final String nombre;
  final String apellidos;
  final String telefono;
  final String email;
  final String? fechaNacimiento;
  final String folioIne;
  final String? fotoUrl;
  final bool mascotas;
  final bool hijos;
  final String estado;
  final String createdAt;

  const ArrendatarioDetalle({
    required this.id,
    required this.nombre,
    required this.apellidos,
    required this.telefono,
    required this.email,
    this.fechaNacimiento,
    required this.folioIne,
    this.fotoUrl,
    required this.mascotas,
    required this.hijos,
    required this.estado,
    required this.createdAt,
  });

  factory ArrendatarioDetalle.fromJson(Map<String, dynamic> json) {
    return ArrendatarioDetalle(
      id:               json['id'] as int,
      nombre:           json['nombre']           ?? '',
      apellidos:        json['apellidos']         ?? '',
      telefono:         json['telefono']          ?? '',
      email:            json['email']             ?? '',
      fechaNacimiento:  json['fecha_nacimiento']  as String?,
      folioIne:         json['folio_ine']         ?? '',
      fotoUrl:          ApiClient.resolveMediaUrl(json['foto'] as String?),
      mascotas:         json['mascotas']          ?? false,
      hijos:            json['hijos']             ?? false,
      estado:           json['estado']            ?? 'activo',
      createdAt:        json['created_at']        ?? '',
    );
  }

  String get nombreCompleto => '$nombre $apellidos'.trim();
  String get inicial => nombre.isNotEmpty ? nombre[0].toUpperCase() : '?';

  /// Año de registro para mostrar "Inquilino desde XXXX"
  String get desdeAnio {
    try { return createdAt.substring(0, 4); } catch (_) { return ''; }
  }
}


// ── Servicio ───────────────────────────────────────────────────────────────────

class ArrendatariosService {
  /// GET /arrendatarios/?search=...&estado=...&page=N
  static Future<List<ArrendatarioItem>> listar({
    String? busqueda,
    String? estado,
    int page = 1,
  }) async {
    final params = <String, String>{'page': page.toString()};
    if (busqueda != null && busqueda.isNotEmpty) params['search'] = busqueda;
    if (estado != null) params['estado'] = estado;

    final query = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    final data = await ApiClient.get('/arrendatarios/?$query');
    final results = data['results'] as List;
    return results.map((e) => ArrendatarioItem.fromJson(e)).toList();
  }

  /// GET /arrendatarios/{id}/
  static Future<ArrendatarioDetalle> detalle(int id) async {
    final data = await ApiClient.get('/arrendatarios/$id/');
    return ArrendatarioDetalle.fromJson(data);
  }

  /// POST /arrendatarios/
  static Future<ArrendatarioDetalle> crear(Map<String, dynamic> body) async {
    final data = await ApiClient.post('/arrendatarios/', body);
    return ArrendatarioDetalle.fromJson(data);
  }

  /// PATCH /arrendatarios/{id}/
  static Future<ArrendatarioDetalle> actualizar(
    int id,
    Map<String, dynamic> body,
  ) async {
    final data = await ApiClient.patch('/arrendatarios/$id/', body);
    return ArrendatarioDetalle.fromJson(data);
  }

  /// DELETE /arrendatarios/{id}/
  static Future<void> eliminar(int id) async {
    await ApiClient.delete('/arrendatarios/$id/');
  }
}
