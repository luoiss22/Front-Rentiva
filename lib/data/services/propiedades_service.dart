import '../../core/services/api_client.dart';

/// Modelo ligero para el listado (PropiedadListSerializer del backend).
class PropiedadItem {
  final int id;
  final String nombre;
  final String ciudad;
  final String estadoGeografico;
  final String tipo;
  final double costoRenta;
  final String estado;
  final String? propietarioNombre;
  final String? fotoPrincipal;

  const PropiedadItem({
    required this.id,
    required this.nombre,
    required this.ciudad,
    required this.estadoGeografico,
    required this.tipo,
    required this.costoRenta,
    required this.estado,
    this.propietarioNombre,
    this.fotoPrincipal,
  });

  factory PropiedadItem.fromJson(Map<String, dynamic> json) {
    return PropiedadItem(
      id:                 json['id'] as int,
      nombre:             json['nombre']           ?? '',
      ciudad:             json['ciudad']           ?? '',
      estadoGeografico:   json['estado_geografico'] ?? '',
      tipo:               json['tipo']             ?? '',
      costoRenta:         double.tryParse(json['costo_renta'].toString()) ?? 0,
      estado:             json['estado']           ?? '',
      propietarioNombre:  json['propietario_nombre'] as String?,
      fotoPrincipal:      json['foto_principal']   as String?,
    );
  }
}


class PropiedadesService {
  /// GET /propiedades/?search=...&estado=...&tipo=...&page=N
  static Future<List<PropiedadItem>> listar({
    String? busqueda,
    String? estado,
    String? tipo,
    int page = 1,
  }) async {
    final params = <String, String>{'page': page.toString()};
    if (busqueda != null && busqueda.isNotEmpty) params['search'] = busqueda;
    if (estado != null) params['estado'] = estado;
    if (tipo != null)   params['tipo']   = tipo;

    final query = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    final data = await ApiClient.get('/propiedades/?$query');
    final results = data['results'] as List;
    return results.map((e) => PropiedadItem.fromJson(e)).toList();
  }

  /// GET /propiedades/{id}/
  static Future<Map<String, dynamic>> detalle(int id) async {
    return await ApiClient.get('/propiedades/$id/');
  }

  /// POST /propiedades/
  static Future<Map<String, dynamic>> crear(Map<String, dynamic> body) async {
    return await ApiClient.post('/propiedades/', body);
  }

  /// PATCH /propiedades/{id}/
  static Future<Map<String, dynamic>> actualizar(
    int id,
    Map<String, dynamic> body,
  ) async {
    return await ApiClient.patch('/propiedades/$id/', body);
  }

  /// DELETE /propiedades/{id}/
  static Future<void> eliminar(int id) async {
    await ApiClient.delete('/propiedades/$id/');
  }
}
