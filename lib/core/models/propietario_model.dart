/// Modelo que refleja al Propietario del backend Django.
class PropietarioModel {
  final int id;
  final String nombre;
  final String apellidos;
  final String email;
  final String telefono;
  final String estado;
  final String? foto;
  final String? fechaNacimiento;
  final String? folioIne;

  const PropietarioModel({
    required this.id,
    required this.nombre,
    required this.apellidos,
    required this.email,
    required this.telefono,
    required this.estado,
    this.foto,
    this.fechaNacimiento,
    this.folioIne,
  });

  factory PropietarioModel.fromJson(Map<String, dynamic> json) {
    return PropietarioModel(
      id:               json['id'] as int,
      nombre:           json['nombre']           ?? '',
      apellidos:        json['apellidos']         ?? '',
      email:            json['email']             ?? '',
      telefono:         json['telefono']          ?? '',
      estado:           json['estado']            ?? 'activo',
      foto:             json['foto'] as String?,
      fechaNacimiento:  json['fecha_nacimiento']  as String?,
      folioIne:         json['folio_ine']         as String?,
    );
  }

  String get nombreCompleto => '$nombre $apellidos'.trim();
}
