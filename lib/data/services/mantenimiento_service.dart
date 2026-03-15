import '../../core/services/api_client.dart';

// ── Modelos ────────────────────────────────────────────────────────────────────

class EspecialistaItem {
  final int id;
  final String nombre;
  final String especialidad;
  final String ciudad;
  final double calificacion;
  final bool disponible;

  const EspecialistaItem({
    required this.id,
    required this.nombre,
    required this.especialidad,
    required this.ciudad,
    required this.calificacion,
    required this.disponible,
  });

  factory EspecialistaItem.fromJson(Map<String, dynamic> json) {
    return EspecialistaItem(
      id: json['id'] as int,
      nombre: json['nombre'] ?? '',
      especialidad: json['especialidad'] ?? '',
      ciudad: json['ciudad'] ?? '',
      calificacion: double.tryParse(json['calificacion'].toString()) ?? 0,
      disponible: json['disponible'] ?? true,
    );
  }
}

class EspecialistaDetalle {
  final int id;
  final String nombre;
  final String especialidad;
  final String telefono;
  final String email;
  final String ciudad;
  final String estadoGeografico;
  final double calificacion;
  final int aniosExperiencia;
  final bool disponible;

  const EspecialistaDetalle({
    required this.id,
    required this.nombre,
    required this.especialidad,
    required this.telefono,
    required this.email,
    required this.ciudad,
    required this.estadoGeografico,
    required this.calificacion,
    required this.aniosExperiencia,
    required this.disponible,
  });

  factory EspecialistaDetalle.fromJson(Map<String, dynamic> json) {
    return EspecialistaDetalle(
      id: json['id'] as int,
      nombre: json['nombre'] ?? '',
      especialidad: json['especialidad'] ?? '',
      telefono: json['telefono'] ?? '',
      email: json['email'] ?? '',
      ciudad: json['ciudad'] ?? '',
      estadoGeografico: json['estado_geografico'] ?? '',
      calificacion: double.tryParse(json['calificacion'].toString()) ?? 0,
      aniosExperiencia: json['anios_experiencia'] ?? 0,
      disponible: json['disponible'] ?? true,
    );
  }
}

class ReporteItem {
  final int id;
  final int? propiedadId;
  final int? especialistaId;
  final String prioridad;
  final String estado;
  final String createdAt;

  const ReporteItem({
    required this.id,
    this.propiedadId,
    this.especialistaId,
    required this.prioridad,
    required this.estado,
    required this.createdAt,
  });

  factory ReporteItem.fromJson(Map<String, dynamic> json) {
    return ReporteItem(
      id: json['id'] as int,
      propiedadId: json['propiedad'] as int?,
      especialistaId: json['especialista'] as int?,
      prioridad: json['prioridad'] ?? 'media',
      estado: json['estado'] ?? 'abierto',
      createdAt: json['created_at'] ?? '',
    );
  }
}

class ReporteDetalle {
  final int id;
  final int propiedadId;
  final int? especialistaId;
  final String? especialistaNombre;
  final String descripcion;
  final String tipoEspecialista;
  final String prioridad;
  final String estado;
  final double? costoEstimado;
  final double? costoFinal;
  final String? fechaResolucion;
  final String createdAt;
  final String updatedAt;
  final List<dynamic> resenas;

  const ReporteDetalle({
    required this.id,
    required this.propiedadId,
    this.especialistaId,
    this.especialistaNombre,
    required this.descripcion,
    required this.tipoEspecialista,
    required this.prioridad,
    required this.estado,
    this.costoEstimado,
    this.costoFinal,
    this.fechaResolucion,
    required this.createdAt,
    required this.updatedAt,
    this.resenas = const [],
  });

  factory ReporteDetalle.fromJson(Map<String, dynamic> json) {
    return ReporteDetalle(
      id: json['id'] as int,
      propiedadId: json['propiedad'] as int,
      especialistaId: json['especialista'] as int?,
      especialistaNombre: json['especialista_nombre'] as String?,
      descripcion: json['descripcion'] ?? '',
      tipoEspecialista: json['tipo_especialista'] ?? '',
      prioridad: json['prioridad'] ?? 'media',
      estado: json['estado'] ?? 'abierto',
      costoEstimado: json['costo_estimado'] != null
          ? double.tryParse(json['costo_estimado'].toString())
          : null,
      costoFinal: json['costo_final'] != null
          ? double.tryParse(json['costo_final'].toString())
          : null,
      fechaResolucion: json['fecha_resolucion'] as String?,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      resenas: json['resenas'] as List<dynamic>? ?? [],
    );
  }
}

// ── Servicios ──────────────────────────────────────────────────────────────────

class EspecialistasService {
  /// GET /especialistas/?especialidad=...&disponible=...&page=N
  static Future<List<EspecialistaItem>> listar({
    String? especialidad,
    bool? disponible,
    String? busqueda,
    int page = 1,
  }) async {
    final params = <String, String>{'page': page.toString()};
    if (especialidad != null) params['especialidad'] = especialidad;
    if (disponible != null) params['disponible'] = disponible.toString();
    if (busqueda != null && busqueda.isNotEmpty) params['search'] = busqueda;

    final query = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    final data = await ApiClient.get('/especialistas/?$query');
    final results = data['results'] as List;
    return results.map((e) => EspecialistaItem.fromJson(e)).toList();
  }

  /// GET /especialistas/{id}/
  static Future<EspecialistaDetalle> detalle(int id) async {
    final data = await ApiClient.get('/especialistas/$id/');
    return EspecialistaDetalle.fromJson(data);
  }

  /// POST /especialistas/
  static Future<EspecialistaDetalle> crear(Map<String, dynamic> body) async {
    final data = await ApiClient.post('/especialistas/', body);
    return EspecialistaDetalle.fromJson(data);
  }

  /// PATCH /especialistas/{id}/
  static Future<EspecialistaDetalle> actualizar(int id, Map<String, dynamic> body) async {
    final data = await ApiClient.patch('/especialistas/$id/', body);
    return EspecialistaDetalle.fromJson(data);
  }

  /// DELETE /especialistas/{id}/
  static Future<void> eliminar(int id) async {
    await ApiClient.delete('/especialistas/$id/');
  }
}

class ReportesMantenimientoService {
  /// GET /reportes-mantenimiento/?estado=...&prioridad=...&page=N
  static Future<List<ReporteItem>> listar({
    String? estado,
    String? prioridad,
    int page = 1,
  }) async {
    final params = <String, String>{'page': page.toString()};
    if (estado != null) params['estado'] = estado;
    if (prioridad != null) params['prioridad'] = prioridad;

    final query = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    final data = await ApiClient.get('/reportes-mantenimiento/?$query');
    final results = data['results'] as List;
    return results.map((e) => ReporteItem.fromJson(e)).toList();
  }

  /// GET /reportes-mantenimiento/{id}/
  static Future<ReporteDetalle> detalle(int id) async {
    final data = await ApiClient.get('/reportes-mantenimiento/$id/');
    return ReporteDetalle.fromJson(data);
  }

  /// POST /reportes-mantenimiento/
  static Future<ReporteDetalle> crear(Map<String, dynamic> body) async {
    final data = await ApiClient.post('/reportes-mantenimiento/', body);
    return ReporteDetalle.fromJson(data);
  }

  /// PATCH /reportes-mantenimiento/{id}/
  static Future<ReporteDetalle> actualizar(int id, Map<String, dynamic> body) async {
    final data = await ApiClient.patch('/reportes-mantenimiento/$id/', body);
    return ReporteDetalle.fromJson(data);
  }

  /// DELETE /reportes-mantenimiento/{id}/
  static Future<void> eliminar(int id) async {
    await ApiClient.delete('/reportes-mantenimiento/$id/');
  }
}

class ResenasService {
  /// POST /resenas-especialistas/
  static Future<Map<String, dynamic>> crear(Map<String, dynamic> body) async {
    return await ApiClient.post('/resenas-especialistas/', body);
  }
}
