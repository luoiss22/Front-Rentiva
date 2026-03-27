// ─── MODELOS según Django ─────────────────────────────────────────────────────
class UsuarioAdmin {
  final int id;
  final String nombre;
  final String apellidos;
  final String estado;    // activo | inactivo | suspendido
  final String propiedad; // nombre de propiedad asignada (display)
  final String telefono;
  final String email;
  final String folioIne;
  final DateTime? fechaNacimiento;
  final String? fotoUrl;
  final DateTime createdAt;

  const UsuarioAdmin({
    required this.id,
    required this.nombre,
    required this.apellidos,
    required this.estado,
    required this.propiedad,
    required this.telefono,
    required this.email,
    required this.folioIne,
    this.fechaNacimiento,
    this.fotoUrl,
    required this.createdAt,
  });

  String get nombreCompleto => '$nombre $apellidos';
  String get inicial => nombre[0].toUpperCase();
  bool get activo => estado == 'activo';
  String get rol => 'propietario'; // Siempre propietario

  factory UsuarioAdmin.fromJson(Map<String, dynamic> json) {
    return UsuarioAdmin(
      id: json['id'] as int,
      nombre: json['nombre'] ?? '',
      apellidos: json['apellidos'] ?? '',
      estado: json['estado'] ?? 'activo',
      propiedad: '-',
      telefono: json['telefono'] ?? '',
      email: json['email'] ?? '',
      folioIne: json['folio_ine'] ?? '',
      fechaNacimiento: json['fecha_nacimiento'] != null
          ? DateTime.tryParse(json['fecha_nacimiento'])
          : null,
      fotoUrl: json['foto'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}

class Especialista {
  final int id;
  final String nombre;
  final String especialidad;  // tipo
  final String telefono;
  final String email;
  final String ciudad;
  final String estadoGeografico;
  final double calificacion;
  final int aniosExperiencia;
  final bool disponible;
  final DateTime createdAt;

  const Especialista({
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
    required this.createdAt,
  });

  String get inicial => nombre[0].toUpperCase();

  factory Especialista.fromJson(Map<String, dynamic> json) {
    return Especialista(
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
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  Especialista copyWith({
    String? nombre,
    String? especialidad,
    String? telefono,
    String? email,
    String? ciudad,
    String? estadoGeografico,
    double? calificacion,
    int? aniosExperiencia,
    bool? disponible,
  }) {
    return Especialista(
      id: id,
      nombre: nombre ?? this.nombre,
      especialidad: especialidad ?? this.especialidad,
      telefono: telefono ?? this.telefono,
      email: email ?? this.email,
      ciudad: ciudad ?? this.ciudad,
      estadoGeografico: estadoGeografico ?? this.estadoGeografico,
      calificacion: calificacion ?? this.calificacion,
      aniosExperiencia: aniosExperiencia ?? this.aniosExperiencia,
      disponible: disponible ?? this.disponible,
      createdAt: createdAt,
    );
  }
}

// ─── MODELO Admin (tabla administradores) ────────────────────────────────────
class Admin {
  final int id;
  final String nombre;
  final String apellidos;
  final DateTime? fechaNacimiento;
  final String telefono;
  final String email;
  final String folioIne;
  final String? fotoUrl;
  final String estado; // activo | inactivo | suspendido
  final DateTime createdAt;
  final DateTime updatedAt;

  const Admin({
    required this.id,
    required this.nombre,
    required this.apellidos,
    this.fechaNacimiento,
    required this.telefono,
    required this.email,
    required this.folioIne,
    this.fotoUrl,
    required this.estado,
    required this.createdAt,
    required this.updatedAt,
  });

  String get nombreCompleto => '$nombre $apellidos';
  String get inicial => nombre[0].toUpperCase();
  bool get activo => estado == 'activo';
  String get rol => 'admin'; // Siempre admin

  factory Admin.fromJson(Map<String, dynamic> json) {
    return Admin(
      id: json['id'] as int,
      nombre: json['nombre'] ?? '',
      apellidos: json['apellidos'] ?? '',
      fechaNacimiento: json['fecha_nacimiento'] != null
          ? DateTime.tryParse(json['fecha_nacimiento'])
          : null,
      telefono: json['telefono'] ?? '',
      email: json['email'] ?? '',
      folioIne: json['folio_ine'] ?? '',
      fotoUrl: json['foto'] as String?,
      estado: json['estado'] ?? 'activo',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  Admin copyWith({
    String? nombre,
    String? apellidos,
    DateTime? fechaNacimiento,
    String? telefono,
    String? email,
    String? folioIne,
    String? fotoUrl,
    String? estado,
  }) =>
      Admin(
        id: id,
        nombre: nombre ?? this.nombre,
        apellidos: apellidos ?? this.apellidos,
        fechaNacimiento: fechaNacimiento ?? this.fechaNacimiento,
        telefono: telefono ?? this.telefono,
        email: email ?? this.email,
        folioIne: folioIne ?? this.folioIne,
        fotoUrl: fotoUrl ?? this.fotoUrl,
        estado: estado ?? this.estado,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );
}
