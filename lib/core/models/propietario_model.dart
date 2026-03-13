/// Modelo que refleja al Propietario del backend Django.
class PropietarioModel {
  final int id;
  final String nombre;
  final String apellidos;
  final String email;
  final String telefono;
  final String rol;   // 'admin' | 'propietario'
  final String estado;
  final String? foto;

  const PropietarioModel({
    required this.id,
    required this.nombre,
    required this.apellidos,
    required this.email,
    required this.telefono,
    required this.rol,
    required this.estado,
    this.foto,
  });

  factory PropietarioModel.fromJson(Map<String, dynamic> json) {
    return PropietarioModel(
      id:        json['id'] as int,
      nombre:    json['nombre']    ?? '',
      apellidos: json['apellidos'] ?? '',
      email:     json['email']     ?? '',
      telefono:  json['telefono']  ?? '',
      rol:       json['rol']       ?? 'propietario',
      estado:    json['estado']    ?? 'activo',
      foto:      json['foto'] as String?,
    );
  }

  String get nombreCompleto => '$nombre $apellidos'.trim();
  bool get esAdmin => rol == 'admin';
}
