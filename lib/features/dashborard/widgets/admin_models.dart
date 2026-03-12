// ─── MODELOS según Django ─────────────────────────────────────────────────────
class UsuarioAdmin {
  final int id;
  final String nombre;
  final String apellidos;
  final String rol;       // admin | propietario
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
    required this.rol,
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

// ─── MODELO Admin (Django model) ─────────────────────────────────────────────
class Admin {
  final int id;
  final String nombre;
  final String apellidos;
  final DateTime? fechaNacimiento;
  final String telefono;
  final String email;
  final String folioIne;
  final String? fotoUrl;
  final String rol;    // admin | propietario
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
    required this.rol,
    required this.estado,
    required this.createdAt,
    required this.updatedAt,
  });

  String get nombreCompleto => '$nombre $apellidos';
  String get inicial => nombre[0].toUpperCase();
  bool get activo => estado == 'activo';

  Admin copyWith({
    String? nombre,
    String? apellidos,
    DateTime? fechaNacimiento,
    String? telefono,
    String? email,
    String? folioIne,
    String? fotoUrl,
    String? rol,
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
        rol: rol ?? this.rol,
        estado: estado ?? this.estado,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );
}
