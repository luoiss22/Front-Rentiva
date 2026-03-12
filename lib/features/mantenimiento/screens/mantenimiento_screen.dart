import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/bottom_navbar.dart';

// ─── HELPERS DE CONTACTO ──────────────────────────────────────────────────────
Future<void> _llamar(BuildContext context, String telefono) async {
  final numero = telefono.replaceAll(RegExp(r'\s+'), '');
  final uri = Uri.parse('tel:$numero');
  try {
    await launchUrl(uri);
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Llama al $numero'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1695A3),
      ));
    }
  }
}

Future<void> _abrirWhatsApp(BuildContext context, String telefono) async {
  var numero = telefono.replaceAll(RegExp(r'\s+'), '');
  if (!numero.startsWith('+')) numero = '+52$numero';
  final uri = Uri.parse(
      'https://wa.me/$numero?text=${Uri.encodeComponent("Hola, te contactamos respecto a tu servicio de mantenimiento.")}');
  try {
    await launchUrl(
      uri,
      mode: kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication,
    );
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('No se pudo abrir WhatsApp'),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }
}

// ─── ENUMS según Django ───────────────────────────────────────────────────────
enum ReportePrioridad { baja, media, alta, urgente }
enum ReporteEstado   { abierto, en_proceso, resuelto, cancelado }

extension ReportePrioridadExt on ReportePrioridad {
  String get label {
    switch (this) {
      case ReportePrioridad.baja:    return 'Baja';
      case ReportePrioridad.media:   return 'Media';
      case ReportePrioridad.alta:    return 'Alta';
      case ReportePrioridad.urgente: return 'Urgente';
    }
  }

  Color get color {
    switch (this) {
      case ReportePrioridad.baja:    return Colors.green;
      case ReportePrioridad.media:   return const Color(0xFFEAB308);
      case ReportePrioridad.alta:    return Colors.red;
      case ReportePrioridad.urgente: return const Color(0xFF7C3AED);
    }
  }

  IconData get icon {
    switch (this) {
      case ReportePrioridad.baja:    return Icons.check_circle_outline;
      case ReportePrioridad.media:   return Icons.schedule_outlined;
      case ReportePrioridad.alta:    return Icons.warning_amber_outlined;
      case ReportePrioridad.urgente: return Icons.bolt_outlined;
    }
  }
}

extension ReporteEstadoExt on ReporteEstado {
  String get label {
    switch (this) {
      case ReporteEstado.abierto:     return 'Abierto';
      case ReporteEstado.en_proceso:  return 'En Proceso';
      case ReporteEstado.resuelto:    return 'Resuelto';
      case ReporteEstado.cancelado:   return 'Cancelado';
    }
  }

  Color get bgColor {
    switch (this) {
      case ReporteEstado.abierto:     return const Color(0xFFFFE4E6);
      case ReporteEstado.en_proceso:  return const Color(0xFFFEF9C3);
      case ReporteEstado.resuelto:    return const Color(0xFFDCFCE7);
      case ReporteEstado.cancelado:   return const Color(0xFFF1F5F9);
    }
  }

  Color get textColor {
    switch (this) {
      case ReporteEstado.abierto:     return const Color(0xFFBE123C);
      case ReporteEstado.en_proceso:  return const Color(0xFFA16207);
      case ReporteEstado.resuelto:    return const Color(0xFF15803D);
      case ReporteEstado.cancelado:   return Colors.grey;
    }
  }
}

// ─── MODELOS según Django ─────────────────────────────────────────────────────
class Especialista {
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
  });
}

class ResenaEspecialista {
  final int id;
  final int calificacion; // 1-5
  final String comentario;
  final DateTime createdAt;

  const ResenaEspecialista({
    required this.id,
    required this.calificacion,
    required this.comentario,
    required this.createdAt,
  });
}

class ReporteMantenimiento {
  final int id;
  final String descripcion;
  final String tipoEspecialista;
  final ReportePrioridad prioridad;
  final ReporteEstado estado;
  final double? costoEstimado;
  final double? costoFinal;
  final DateTime? fechaResolucion;
  final DateTime createdAt;
  final DateTime updatedAt;
  // FK
  final String propiedadNombre;
  final Especialista? especialista;
  final List<ResenaEspecialista> resenas;

  const ReporteMantenimiento({
    required this.id,
    required this.descripcion,
    required this.tipoEspecialista,
    required this.prioridad,
    required this.estado,
    this.costoEstimado,
    this.costoFinal,
    this.fechaResolucion,
    required this.createdAt,
    required this.updatedAt,
    required this.propiedadNombre,
    this.especialista,
    this.resenas = const [],
  });

  String get fechaRelativa {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inDays == 0) return 'Hoy';
    if (diff.inDays == 1) return 'Ayer';
    if (diff.inDays < 7) return 'Hace ${diff.inDays} días';
    return '${createdAt.day.toString().padLeft(2, '0')}/'
        '${createdAt.month.toString().padLeft(2, '0')}/'
        '${createdAt.year}';
  }
}

// ─── DATOS EJEMPLO ────────────────────────────────────────────────────────────
final List<ReporteMantenimiento> _reportesEjemplo = [
  ReporteMantenimiento(
    id: 1,
    descripcion: 'Fuga de agua en baño principal, mancha en techo del departamento de abajo.',
    tipoEspecialista: 'Fontanero',
    prioridad: ReportePrioridad.alta,
    estado: ReporteEstado.abierto,
    costoEstimado: 1500,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    propiedadNombre: 'Depto 302 - Reforma',
  ),
  ReporteMantenimiento(
    id: 2,
    descripcion: 'Cambio de chapa y llave maestra en puerta principal.',
    tipoEspecialista: 'Cerrajero',
    prioridad: ReportePrioridad.media,
    estado: ReporteEstado.en_proceso,
    costoEstimado: 800,
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
    updatedAt: DateTime.now().subtract(const Duration(hours: 3)),
    propiedadNombre: 'Casa Jardines',
    especialista: const Especialista(
      id: 1, nombre: 'Roberto Sánchez',
      especialidad: 'Cerrajería',
      telefono: '55 9876 5432',
      email: 'roberto@cerrajeros.mx',
      ciudad: 'CDMX', estadoGeografico: 'CDMX',
      calificacion: 4.8, aniosExperiencia: 12, disponible: true,
    ),
    resenas: [
      ResenaEspecialista(
        id: 1, calificacion: 5,
        comentario: 'Muy puntual y profesional.',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ],
  ),
  ReporteMantenimiento(
    id: 3,
    descripcion: 'Revisión del tablero eléctrico, cortos en área de cocina.',
    tipoEspecialista: 'Electricista',
    prioridad: ReportePrioridad.baja,
    estado: ReporteEstado.resuelto,
    costoEstimado: 2200, costoFinal: 1950,
    fechaResolucion: DateTime.now().subtract(const Duration(days: 3)),
    createdAt: DateTime.now().subtract(const Duration(days: 6)),
    updatedAt: DateTime.now().subtract(const Duration(days: 3)),
    propiedadNombre: 'Local 5',
    especialista: const Especialista(
      id: 2, nombre: 'Ing. Luis Morales',
      especialidad: 'Electricidad',
      telefono: '55 1122 3344',
      email: 'luis.morales@elec.mx',
      ciudad: 'CDMX', estadoGeografico: 'CDMX',
      calificacion: 4.5, aniosExperiencia: 8, disponible: false,
    ),
  ),
  ReporteMantenimiento(
    id: 4,
    descripcion: 'Pintura de fachada exterior deteriorada por lluvia.',
    tipoEspecialista: 'Pintor',
    prioridad: ReportePrioridad.urgente,
    estado: ReporteEstado.abierto,
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
    propiedadNombre: 'Casa Jardines',
  ),
];

// ─── PANTALLA ─────────────────────────────────────────────────────────────────
class MantenimientoScreen extends StatefulWidget {
  const MantenimientoScreen({super.key});

  @override
  State<MantenimientoScreen> createState() => _MantenimientoScreenState();
}

class _MantenimientoScreenState extends State<MantenimientoScreen> {
  final int _navIndex = 4;
  String _filtro = 'todos';

  static const List<Map<String, String>> _filtros = [
    {'value': 'todos',      'label': 'Todos'},
    {'value': 'abierto',    'label': 'Pendientes'},
    {'value': 'en_proceso', 'label': 'En Proceso'},
    {'value': 'resuelto',   'label': 'Resueltos'},
  ];

  void _onNavTap(int index) {
    const routes = [
      '/inicio-usuario', '/propiedades', '/inquilinos', '/pagos', '',
    ];
    if (index != _navIndex) Navigator.pushNamed(context, routes[index]);
  }

  List<ReporteMantenimiento> get _filtrados {
    if (_filtro == 'todos') return _reportesEjemplo;
    return _reportesEjemplo.where((r) => r.estado.name == _filtro).toList();
  }

  int _count(ReporteEstado e) =>
      _reportesEjemplo.where((r) => r.estado == e).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const AppHeader(title: 'Mantenimiento'),
      bottomNavigationBar:
          BottomNavBar(currentIndex: _navIndex, onTap: _onNavTap),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            Navigator.pushNamed(context, '/mantenimiento/nuevo'),
        backgroundColor: const Color(0xFFEB7F00),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nuevo Reporte',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        elevation: 4,
      ),
      body: Column(
        children: [
          // ── Stats ─────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                _StatCard(
                  count: _count(ReporteEstado.abierto),
                  label: 'Pendientes',
                  color: const Color(0xFFEB7F00),
                ),
                const SizedBox(width: 10),
                _StatCard(
                  count: _count(ReporteEstado.en_proceso),
                  label: 'En Proceso',
                  color: const Color(0xFF1695A3),
                ),
                const SizedBox(width: 10),
                _StatCard(
                  count: _count(ReporteEstado.resuelto),
                  label: 'Resueltos',
                  color: Colors.green,
                ),
                const SizedBox(width: 10),
                _StatCard(
                  count: _count(ReporteEstado.cancelado),
                  label: 'Cancelados',
                  color: Colors.grey,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Filtros ───────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.04), blurRadius: 6),
                ],
              ),
              child: Row(
                children: _filtros.map((f) {
                  final isActive = _filtro == f['value'];
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _filtro = f['value']!),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isActive
                              ? const Color(0xFF225378)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          f['label']!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color:
                                isActive ? Colors.white : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Lista ─────────────────────────────────────────────────────────
          Expanded(
            child: _filtrados.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.build_outlined,
                            size: 52, color: Colors.grey),
                        SizedBox(height: 12),
                        Text('No hay reportes',
                            style: TextStyle(
                                color: Colors.grey, fontSize: 14)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding:
                        const EdgeInsets.fromLTRB(16, 4, 16, 100),
                    itemCount: _filtrados.length,
                    itemBuilder: (context, i) => _ReporteCard(
                      reporte: _filtrados[i],
                      onTap: () => _mostrarDetalle(context, _filtrados[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _mostrarDetalle(
      BuildContext context, ReporteMantenimiento reporte) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _DetalleReporteSheet(reporte: reporte),
    );
  }
}

// ─── TARJETA REPORTE ──────────────────────────────────────────────────────────
class _ReporteCard extends StatelessWidget {
  final ReporteMantenimiento reporte;
  final VoidCallback onTap;

  const _ReporteCard({required this.reporte, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            // Barra lateral de prioridad
            Container(
              width: 5,
              height: 100,
              decoration: BoxDecoration(
                color: reporte.prioridad.color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),

            // Contenido
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Chip tipo especialista
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFACF0F2).withOpacity(0.4),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(reporte.tipoEspecialista,
                              style: const TextStyle(
                                  color: Color(0xFF1695A3),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold)),
                        ),
                        // Badge estado
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: reporte.estado.bgColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(reporte.estado.label,
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: reporte.estado.textColor)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    Text(reporte.descripcion,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Color(0xFF225378),
                            fontWeight: FontWeight.bold,
                            fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(reporte.propiedadNombre,
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 11)),

                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Prioridad
                        Row(
                          children: [
                            Icon(reporte.prioridad.icon,
                                color: reporte.prioridad.color, size: 13),
                            const SizedBox(width: 4),
                            Text('Prioridad ${reporte.prioridad.label}',
                                style: TextStyle(
                                    color: reporte.prioridad.color,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),

                        // Fecha + indicadores
                        Row(
                          children: [
                            if (reporte.especialista != null)
                              Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: Icon(Icons.handyman_outlined,
                                    color: const Color(0xFF1695A3),
                                    size: 13),
                              ),
                            if (reporte.costoFinal != null)
                              Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: Icon(Icons.attach_money,
                                    color: Colors.green, size: 13),
                              ),
                            Text(reporte.fechaRelativa,
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 11)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── BOTTOM SHEET DETALLE ─────────────────────────────────────────────────────
class _DetalleReporteSheet extends StatefulWidget {
  final ReporteMantenimiento reporte;
  const _DetalleReporteSheet({required this.reporte});

  @override
  State<_DetalleReporteSheet> createState() => _DetalleReporteSheetState();
}

class _DetalleReporteSheetState extends State<_DetalleReporteSheet> {
  int _resenaCalif = 0;

  @override
  Widget build(BuildContext context) {
    final r = widget.reporte;
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (_, ctrl) => SingleChildScrollView(
        controller: ctrl,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),

              // Encabezado
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 6,
                    height: 50,
                    decoration: BoxDecoration(
                      color: r.prioridad.color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFACF0F2)
                                    .withOpacity(0.4),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(r.tipoEspecialista,
                                  style: const TextStyle(
                                      color: Color(0xFF1695A3),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: r.estado.bgColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(r.estado.label,
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: r.estado.textColor)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(r.descripcion,
                            style: const TextStyle(
                                color: Color(0xFF225378),
                                fontWeight: FontWeight.bold,
                                fontSize: 15)),
                        const SizedBox(height: 2),
                        Text(r.propiedadNombre,
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(color: Colors.grey.shade100),
              const SizedBox(height: 12),

              // Detalles
              _sheetSection('Detalles del Reporte'),
              const SizedBox(height: 10),
              _detailRow('Prioridad', r.prioridad.label,
                  valueColor: r.prioridad.color),
              _detailRow('Creado', r.fechaRelativa),
              if (r.costoEstimado != null)
                _detailRow('Costo estimado',
                    '\$${r.costoEstimado!.toStringAsFixed(2)}'),
              if (r.costoFinal != null)
                _detailRow('Costo final',
                    '\$${r.costoFinal!.toStringAsFixed(2)}',
                    valueColor: Colors.green),
              if (r.fechaResolucion != null)
                _detailRow('Resuelto el',
                    '${r.fechaResolucion!.day.toString().padLeft(2, '0')}/'
                    '${r.fechaResolucion!.month.toString().padLeft(2, '0')}/'
                    '${r.fechaResolucion!.year}'),

              // Especialista asignado
              if (r.especialista != null) ...[
                const SizedBox(height: 16),
                _sheetSection('Especialista Asignado'),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48, height: 48,
                        decoration: const BoxDecoration(
                          color: Color(0xFFACF0F2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.handyman_outlined,
                            color: Color(0xFF1695A3), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r.especialista!.nombre,
                                style: const TextStyle(
                                    color: Color(0xFF225378),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14)),
                            Text(r.especialista!.especialidad,
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 12)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.star,
                                    color: Color(0xFFEB7F00), size: 13),
                                const SizedBox(width: 3),
                                Text(
                                    r.especialista!.calificacion
                                        .toStringAsFixed(1),
                                    style: const TextStyle(
                                        color: Color(0xFF225378),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12)),
                                const SizedBox(width: 8),
                                Text(
                                    '${r.especialista!.aniosExperiencia} años exp.',
                                    style: const TextStyle(
                                        color: Colors.grey, fontSize: 11)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Botones llamar + WhatsApp
                      Column(
                        children: [
                          _ContactBtn(
                            icon: Icons.phone_outlined,
                            color: const Color(0xFF1695A3),
                            tooltip: 'Llamar',
                            onTap: () => _llamar(context, r.especialista!.telefono),
                          ),
                          const SizedBox(height: 6),
                          _ContactBtn(
                            icon: Icons.chat_outlined,
                            color: const Color(0xFF25D366),
                            tooltip: 'WhatsApp',
                            onTap: () => _abrirWhatsApp(context, r.especialista!.telefono),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              // Reseñas del especialista
              if (r.resenas.isNotEmpty) ...[
                const SizedBox(height: 16),
                _sheetSection('Reseñas'),
                const SizedBox(height: 10),
                ...r.resenas.map((res) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: List.generate(5, (i) => Icon(
                              i < res.calificacion
                                  ? Icons.star
                                  : Icons.star_border,
                              color: const Color(0xFFEB7F00),
                              size: 14,
                            )),
                          ),
                          const SizedBox(height: 4),
                          Text(res.comentario,
                              style: const TextStyle(
                                  color: Color(0xFF225378),
                                  fontSize: 12)),
                        ],
                      ),
                    )),
              ],

              // Calificar especialista (si está resuelto y sin reseña)
              if (r.estado == ReporteEstado.resuelto &&
                  r.especialista != null &&
                  r.resenas.isEmpty) ...[
                const SizedBox(height: 16),
                _sheetSection('Calificar Especialista'),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) => GestureDetector(
                    onTap: () => setState(() => _resenaCalif = i + 1),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        i < _resenaCalif ? Icons.star : Icons.star_border,
                        color: const Color(0xFFEB7F00),
                        size: 32,
                      ),
                    ),
                  )),
                ),
                const SizedBox(height: 12),
                if (_resenaCalif > 0)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // TODO: POST /api/mantenimiento/{id}/resena/
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('Reseña enviada correctamente'),
                            backgroundColor: Color(0xFF1695A3),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEB7F00),
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text('Enviar Reseña',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],

              // Botón editar
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/mantenimiento/editar',
                        arguments: r.id);
                  },
                  icon: const Icon(Icons.edit_outlined,
                      color: Color(0xFF225378), size: 18),
                  label: const Text('Editar Reporte',
                      style: TextStyle(
                          color: Color(0xFF225378),
                          fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Color(0xFF225378)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _sheetSection(String title) {
    return Text(title,
        style: const TextStyle(
            color: Color(0xFF225378),
            fontWeight: FontWeight.bold,
            fontSize: 14));
  }

  static Widget _detailRow(String label, String value,
      {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
                  const TextStyle(color: Colors.grey, fontSize: 12)),
          Text(value,
              style: TextStyle(
                  color: valueColor ?? const Color(0xFF225378),
                  fontWeight: FontWeight.w600,
                  fontSize: 12)),
        ],
      ),
    );
  }
}

// ─── BOTÓN CONTACTO ──────────────────────────────────────────────────────────
class _ContactBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _ContactBtn({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.10),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
      ),
    );
  }
}

// ─── WIDGETS AUXILIARES ───────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final int count;
  final String label;
  final Color color;

  const _StatCard({
    required this.count,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.03), blurRadius: 6),
          ],
        ),
        child: Column(
          children: [
            Text(count.toString(),
                style: TextStyle(
                    color: color,
                    fontSize: 22,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 3),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }
}