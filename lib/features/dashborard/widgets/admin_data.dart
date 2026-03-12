import 'admin_models.dart';

// ─── DATOS INICIALES ──────────────────────────────────────────────────────────
final List<UsuarioAdmin> usuariosIniciales = [
  UsuarioAdmin(
    id: 1, nombre: 'Juan', apellidos: 'Pérez López',
    rol: 'propietario', estado: 'activo', propiedad: 'Depto 302',
    telefono: '55 1234 5678', email: 'juan.perez@rentiva.com',
    folioIne: 'PELJ901012HDFRZN01',
    fechaNacimiento: DateTime(1990, 10, 12),
    createdAt: DateTime(2023, 1, 15),
  ),
  UsuarioAdmin(
    id: 2, nombre: 'María', apellidos: 'González Ruiz',
    rol: 'propietario', estado: 'activo', propiedad: 'Casa Jardines',
    telefono: '55 8765 4321', email: 'maria.gz@rentiva.com',
    folioIne: 'GORM850320MDFNZR02',
    fechaNacimiento: DateTime(1985, 3, 20),
    createdAt: DateTime(2023, 3, 10),
  ),
  UsuarioAdmin(
    id: 3, nombre: 'Carlos', apellidos: 'Ruiz Mendoza',
    rol: 'admin', estado: 'inactivo', propiedad: '-',
    telefono: '55 1122 3344', email: 'carlos.rm@rentiva.com',
    folioIne: 'RUMC780915HDFZND03',
    createdAt: DateTime(2022, 6, 1),
  ),
];

final List<Especialista> especialistasIniciales = [
  Especialista(
    id: 1, nombre: 'Mario Ríos', especialidad: 'Fontanero',
    telefono: '55 1234 5678', email: 'mario@fontaneros.mx',
    ciudad: 'CDMX', estadoGeografico: 'CDMX',
    calificacion: 4.8, aniosExperiencia: 10, disponible: true,
    createdAt: DateTime(2023, 5, 1),
  ),
  Especialista(
    id: 2, nombre: 'Tesla Electric', especialidad: 'Electricista',
    telefono: '55 9988 7766', email: 'tesla@electric.mx',
    ciudad: 'CDMX', estadoGeografico: 'CDMX',
    calificacion: 4.9, aniosExperiencia: 15, disponible: false,
    createdAt: DateTime(2022, 11, 20),
  ),
];

const List<String> tiposEspecialista = [
  'Fontanero',
  'Electricista',
  'Cerrajero',
  'Mantenimiento General',
  'Jardinero',
];

final List<Admin> adminsIniciales = [
  Admin(
    id: 1, nombre: 'Carlos', apellidos: 'Ruiz Mendoza',
    fechaNacimiento: DateTime(1985, 4, 20),
    telefono: '55 1122 3344', email: 'carlos.rm@rentiva.com',
    folioIne: 'RUMC850420HDFZND03', rol: 'admin', estado: 'activo',
    createdAt: DateTime(2022, 6, 1), updatedAt: DateTime(2024, 1, 10),
  ),
  Admin(
    id: 2, nombre: 'Sofía', apellidos: 'Torres Vega',
    fechaNacimiento: DateTime(1990, 8, 15),
    telefono: '55 9988 1122', email: 'sofia.tv@rentiva.com',
    folioIne: 'TOVS900815MDFRGF04', rol: 'admin', estado: 'activo',
    createdAt: DateTime(2023, 3, 5), updatedAt: DateTime(2024, 2, 20),
  ),
  Admin(
    id: 3, nombre: 'Marco', apellidos: 'Díaz López',
    fechaNacimiento: DateTime(1978, 12, 3),
    telefono: '55 3344 5566', email: 'marco.dl@rentiva.com',
    folioIne: 'DILM781203HDFZPC05', rol: 'admin', estado: 'suspendido',
    createdAt: DateTime(2021, 9, 14), updatedAt: DateTime(2023, 11, 1),
  ),
];
