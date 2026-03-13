import '../../core/services/api_client.dart';

// ── Modelos ────────────────────────────────────────────────────────────────────

class NotificacionItem {
  final int id;
  final int contratoId;
  final String tipo;
  final String titulo;
  final String fechaProgramada;
  final String medio;

  const NotificacionItem({
    required this.id,
    required this.contratoId,
    required this.tipo,
    required this.titulo,
    required this.fechaProgramada,
    required this.medio,
  });

  factory NotificacionItem.fromJson(Map<String, dynamic> json) {
    return NotificacionItem(
      id: json['id'] as int,
      contratoId: json['contrato'] as int,
      tipo: json['tipo'] ?? 'general',
      titulo: json['titulo'] ?? '',
      fechaProgramada: json['fecha_programada'] ?? '',
      medio: json['medio'] ?? 'email',
    );
  }
}

class NotificacionDetalle {
  final int id;
  final int contratoId;
  final String tipo;
  final String titulo;
  final String mensaje;
  final String fechaProgramada;
  final String medio;
  final String createdAt;
  final List<dynamic> logs;

  const NotificacionDetalle({
    required this.id,
    required this.contratoId,
    required this.tipo,
    required this.titulo,
    required this.mensaje,
    required this.fechaProgramada,
    required this.medio,
    required this.createdAt,
    this.logs = const [],
  });

  factory NotificacionDetalle.fromJson(Map<String, dynamic> json) {
    return NotificacionDetalle(
      id: json['id'] as int,
      contratoId: json['contrato'] as int,
      tipo: json['tipo'] ?? 'general',
      titulo: json['titulo'] ?? '',
      mensaje: json['mensaje'] ?? '',
      fechaProgramada: json['fecha_programada'] ?? '',
      medio: json['medio'] ?? 'email',
      createdAt: json['created_at'] ?? '',
      logs: json['logs'] as List<dynamic>? ?? [],
    );
  }
}

// ── Servicio ───────────────────────────────────────────────────────────────────

class NotificacionesService {
  /// GET /notificaciones/?tipo=...&page=N
  static Future<List<NotificacionItem>> listar({
    String? tipo,
    int page = 1,
  }) async {
    final params = <String, String>{'page': page.toString()};
    if (tipo != null) params['tipo'] = tipo;

    final query = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    final data = await ApiClient.get('/notificaciones/?$query');
    final results = data['results'] as List;
    return results.map((e) => NotificacionItem.fromJson(e)).toList();
  }

  /// GET /notificaciones/{id}/
  static Future<NotificacionDetalle> detalle(int id) async {
    final data = await ApiClient.get('/notificaciones/$id/');
    return NotificacionDetalle.fromJson(data);
  }

  /// DELETE /notificaciones/{id}/
  static Future<void> eliminar(int id) async {
    await ApiClient.delete('/notificaciones/$id/');
  }
}
