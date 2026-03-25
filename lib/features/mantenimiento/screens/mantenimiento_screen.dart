import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';
import '../../../core/services/api_client.dart';
import '../../../data/services/mantenimiento_service.dart';
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

// ─── MODELOS ──────────────────────────────────────────────────────────────────

// Modelo liviano para la lista — se construye desde ReporteItem sin requests extra
class ReporteResumen {
  final int id;
  final String descripcion;
  final String tipoEspecialista;
  final ReportePrioridad prioridad;
  final ReporteEstado estado;
  final double? costoEstimado;
  final double? costoFinal;
  final DateTime createdAt;
  final String propiedadNombre;
  final int? especialistaId;
  final String? especialistaNombre;

  const ReporteResumen({
    required this.id,
    required this.descripcion,
    required this.tipoEspecialista,
    required this.prioridad,
    required this.estado,
    this.costoEstimado,
    this.costoFinal,
    required this.createdAt,
    required this.propiedadNombre,
    this.especialistaId,
    this.especialistaNombre,
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

// Modelo completo para el detalle — se carga solo al abrir el bottom sheet
class EspecialistaCompleto {
  final int id;
  final String nombre;
  final String especialidad;
  final String telefono;
  final String email;
  final String ciudad;
  final double calificacion;
  final int aniosExperiencia;
  final bool disponible;

  const EspecialistaCompleto({
    required this.id,
    required this.nombre,
    required this.especialidad,
    required this.telefono,
    required this.email,
    required this.ciudad,
    required this.calificacion,
    required this.aniosExperiencia,
    required this.disponible,
  });

  factory EspecialistaCompleto.fromDetalle(EspecialistaDetalle d) {
    return EspecialistaCompleto(
      id: d.id,
      nombre: d.nombre,
      especialidad: d.especialidad,
      telefono: d.telefono,
      email: d.email,
      ciudad: d.ciudad,
      calificacion: d.calificacion,
      aniosExperiencia: d.aniosExperiencia,
      disponible: d.disponible,
    );
  }
}

class ResenaResumen {
  final int id;
  final int calificacion;
  final String comentario;
  final DateTime createdAt;

  const ResenaResumen({
    required this.id,
    required this.calificacion,
    required this.comentario,
    required this.createdAt,
  });
}

// ─── PANTALLA ─────────────────────────────────────────────────────────────────
class MantenimientoScreen extends StatefulWidget {
  const MantenimientoScreen({super.key});

  @override
  State<MantenimientoScreen> createState() => _MantenimientoScreenState();
}

class _MantenimientoScreenState extends State<MantenimientoScreen> {
  final int _navIndex = 4;
  String _filtro = 'todos';

  List<ReporteResumen> _reportes = [];
  bool _loading = true;
  bool _cargandoMas = false;
  bool _hayMas = false;
  int _paginaActual = 1;
  String? _error;
  Map<int, String> _propMap = {};

  final ScrollController _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    _cargarReportes();
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Cuando queden 200px para el final, carga la siguiente página
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200 &&
        !_cargandoMas && _hayMas) {
      _cargarMas();
    }
  }

  List<ReporteResumen> _itemsDesdeApi(List<ReporteItem> items) {
    return items.map((item) => ReporteResumen(
      id: item.id,
      descripcion: item.descripcion,
      tipoEspecialista: item.tipoEspecialista,
      prioridad: ReportePrioridad.values.firstWhere(
        (p) => p.name == item.prioridad,
        orElse: () => ReportePrioridad.media,
      ),
      estado: ReporteEstado.values.firstWhere(
        (e) => e.name == item.estado,
        orElse: () => ReporteEstado.abierto,
      ),
      costoEstimado: item.costoEstimado,
      costoFinal: item.costoFinal,
      createdAt: DateTime.tryParse(item.createdAt) ?? DateTime.now(),
      propiedadNombre: _propMap[item.propiedadId] ?? 'Propiedad #${item.propiedadId}',
      especialistaId: item.especialistaId,
      especialistaNombre: item.especialistaNombre,
    )).toList();
  }

  // Carga inicial — limpia la lista y carga desde página 1
  Future<void> _cargarReportes() async {
    setState(() { _loading = true; _error = null; _paginaActual = 1; });
    try {
      final futures = await Future.wait([
        ApiClient.get('/propiedades/'),
        ReportesMantenimientoService.listar(page: 1),
      ]);

      final propData = futures[0] as Map<String, dynamic>;
      final paginado = futures[1] as PaginatedReportes;

      final propResults = propData['results'] as List;
      final propMap = <int, String>{};
      for (final p in propResults) {
        propMap[p['id'] as int] = p['nombre'] ?? 'Propiedad #${p['id']}';
      }

      setState(() {
        _propMap = propMap;
        _reportes = _itemsDesdeApi(paginado.items);
        _hayMas = paginado.hayMas;
        _loading = false;
      });
    } on ApiException catch (e) {
      setState(() { _error = e.message; _loading = false; });
    } catch (_) {
      setState(() { _error = 'Error de conexión'; _loading = false; });
    }
  }

  // Carga página siguiente y agrega al final de la lista
  Future<void> _cargarMas() async {
    if (_cargandoMas) return;
    setState(() => _cargandoMas = true);
    try {
      final siguientePagina = _paginaActual + 1;
      final paginado = await ReportesMantenimientoService.listar(page: siguientePagina);
      setState(() {
        _reportes.addAll(_itemsDesdeApi(paginado.items));
        _hayMas = paginado.hayMas;
        _paginaActual = siguientePagina;
        _cargandoMas = false;
      });
    } catch (_) {
      setState(() => _cargandoMas = false);
    }
  }

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

  List<ReporteResumen> get _filtrados {
    if (_filtro == 'todos') return _reportes;
    return _reportes.where((r) => r.estado.name == _filtro).toList();
  }

  int _count(ReporteEstado e) =>
      _reportes.where((r) => r.estado == e).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const AppHeader(title: 'Mantenimiento'),
      bottomNavigationBar:
          BottomNavBar(currentIndex: _navIndex, onTap: _onNavTap),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/mantenimiento/nuevo')
              .then((_) => _cargarReportes());
        },
        backgroundColor: const Color(0xFFEB7F00),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nuevo Reporte',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        elevation: 4,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1695A3)))
          : _error != null
              ? Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 12),
                    ElevatedButton(onPressed: _cargarReportes, child: const Text('Reintentar')),
                  ],
                ))
              : Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                _StatCard(count: _count(ReporteEstado.abierto),    label: 'Pendientes', color: const Color(0xFFEB7F00)),
                const SizedBox(width: 10),
                _StatCard(count: _count(ReporteEstado.en_proceso), label: 'En Proceso',  color: const Color(0xFF1695A3)),
                const SizedBox(width: 10),
                _StatCard(count: _count(ReporteEstado.resuelto),   label: 'Resueltos',   color: Colors.green),
                const SizedBox(width: 10),
                _StatCard(count: _count(ReporteEstado.cancelado),  label: 'Cancelados',  color: Colors.grey),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
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
                          color: isActive ? const Color(0xFF225378) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          f['label']!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isActive ? Colors.white : Colors.grey,
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
          Expanded(
            child: _filtrados.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.build_outlined, size: 52, color: Colors.grey),
                        SizedBox(height: 12),
                        Text('No hay reportes', style: TextStyle(color: Colors.grey, fontSize: 14)),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                    // +1 para el loader al final cuando hay más páginas
                    itemCount: _filtrados.length + (_hayMas ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (i == _filtrados.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(child: CircularProgressIndicator(
                            color: Color(0xFF1695A3), strokeWidth: 2,
                          )),
                        );
                      }
                      return _ReporteCard(
                        reporte: _filtrados[i],
                        onTap: () => _mostrarDetalle(context, _filtrados[i]),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _mostrarDetalle(BuildContext context, ReporteResumen reporte) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _DetalleReporteSheet(reporte: reporte),
    ).then((_) => _cargarReportes());
  }
}

// ─── TARJETA REPORTE ──────────────────────────────────────────────────────────
class _ReporteCard extends StatelessWidget {
  final ReporteResumen reporte;
  final VoidCallback onTap;

  const _ReporteCard({required this.reporte, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final enProceso = reporte.estado == ReporteEstado.en_proceso;
    final tieneEspecialista = reporte.especialistaId != null &&
        reporte.especialistaNombre != null &&
        reporte.especialistaNombre!.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          // Borde resaltado cuando está en proceso
          border: Border.all(
            color: enProceso
                ? const Color(0xFF1695A3).withOpacity(0.4)
                : Colors.grey.shade100,
            width: enProceso ? 1.5 : 1,
          ),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Barra lateral de prioridad
                Container(
                  width: 5,
                  height: tieneEspecialista ? 116 : 100,
                  decoration: BoxDecoration(
                    color: reporte.prioridad.color,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Fila superior: tipo + estado
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFACF0F2).withOpacity(0.4),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(reporte.tipoEspecialista,
                                  style: const TextStyle(color: Color(0xFF1695A3), fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: reporte.estado.bgColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(reporte.estado.label,
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: reporte.estado.textColor)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Descripción
                        Text(reporte.descripcion,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Color(0xFF225378), fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 4),
                        Text(reporte.propiedadNombre,
                            style: const TextStyle(color: Colors.grey, fontSize: 11)),
                        const SizedBox(height: 8),
                        // Fila inferior: prioridad + fecha
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(reporte.prioridad.icon, color: reporte.prioridad.color, size: 13),
                                const SizedBox(width: 4),
                                Text('Prioridad ${reporte.prioridad.label}',
                                    style: TextStyle(color: reporte.prioridad.color, fontSize: 11, fontWeight: FontWeight.w600)),
                              ],
                            ),
                            Row(
                              children: [
                                if (reporte.costoFinal != null)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: Icon(Icons.attach_money, color: Colors.green, size: 13),
                                  ),
                                Text(reporte.fechaRelativa,
                                    style: const TextStyle(color: Colors.grey, fontSize: 11)),
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

            // Banner del especialista — visible solo cuando hay uno asignado
            if (tieneEspecialista) ...[
              Container(
                margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: enProceso
                      ? const Color(0xFF1695A3).withOpacity(0.07)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: enProceso
                        ? const Color(0xFF1695A3).withOpacity(0.2)
                        : Colors.grey.shade100,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 26, height: 26,
                      decoration: BoxDecoration(
                        color: enProceso
                            ? const Color(0xFF1695A3).withOpacity(0.15)
                            : const Color(0xFFACF0F2).withOpacity(0.4),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.handyman_outlined,
                        size: 14,
                        color: enProceso ? const Color(0xFF1695A3) : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            enProceso ? 'Trabajando en esto' : 'Especialista asignado',
                            style: TextStyle(
                              fontSize: 9,
                              color: enProceso ? const Color(0xFF1695A3) : Colors.grey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            reporte.especialistaNombre!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF225378),
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (enProceso)
                      Container(
                        width: 7, height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFF1695A3),
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── STAT CARD ────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final int count;
  final String label;
  final Color color;

  const _StatCard({required this.count, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
        ),
        child: Column(
          children: [
            Text('$count', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 2),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 9)),
          ],
        ),
      ),
    );
  }
}

// ─── BOTTOM SHEET DETALLE ─────────────────────────────────────────────────────
// Carga el detalle completo (con especialista y reseñas) solo cuando se abre
class _DetalleReporteSheet extends StatefulWidget {
  final ReporteResumen reporte;
  const _DetalleReporteSheet({required this.reporte});

  @override
  State<_DetalleReporteSheet> createState() => _DetalleReporteSheetState();
}

class _DetalleReporteSheetState extends State<_DetalleReporteSheet> {
  ReporteDetalle? _detalle;
  EspecialistaCompleto? _especialista;
  List<ResenaResumen> _resenas = [];
  bool _cargando = true;
  String? _errorCarga;

  // campos de reseña
  int _resenaCalif = 0;
  final _resenaComentarioCtrl = TextEditingController();
  bool _enviandoResena = false;

  @override
  void initState() {
    super.initState();
    _cargarDetalle();
  }

  @override
  void dispose() {
    _resenaComentarioCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarDetalle() async {
    try {
      final det = await ReportesMantenimientoService.detalle(widget.reporte.id);

      EspecialistaCompleto? esp;
      if (det.especialistaId != null) {
        final espDet = await EspecialistasService.detalle(det.especialistaId!);
        esp = EspecialistaCompleto.fromDetalle(espDet);
      }

      final resenas = (det.resenas).map<ResenaResumen>((r) => ResenaResumen(
        id: r['id'] ?? 0,
        calificacion: r['calificacion'] ?? 0,
        comentario: r['comentario'] ?? '',
        createdAt: DateTime.tryParse(r['created_at'] ?? '') ?? DateTime.now(),
      )).toList();

      setState(() {
        _detalle = det;
        _especialista = esp;
        _resenas = resenas;
        _cargando = false;
      });
    } catch (_) {
      setState(() { _errorCarga = 'No se pudo cargar el detalle'; _cargando = false; });
    }
  }

  Future<void> _enviarResena() async {
    if (_resenaCalif == 0 || _especialista == null || _detalle == null) return;
    setState(() => _enviandoResena = true);
    try {
      await ResenasService.crear({
        'especialista': _especialista!.id,
        'reporte': _detalle!.id,
        'calificacion': _resenaCalif,
        'comentario': _resenaComentarioCtrl.text.trim(),
      });
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Reseña enviada correctamente'),
          backgroundColor: Color(0xFF1695A3),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Error al enviar reseña'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _enviandoResena = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.reporte;
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (_, ctrl) {
        if (_cargando) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(40),
            child: CircularProgressIndicator(color: Color(0xFF1695A3)),
          ));
        }
        if (_errorCarga != null) {
          return Center(child: Text(_errorCarga!, style: const TextStyle(color: Colors.red)));
        }
        return SingleChildScrollView(
          controller: ctrl,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                // Encabezado
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 6, height: 50,
                      decoration: BoxDecoration(color: r.prioridad.color, borderRadius: BorderRadius.circular(3)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _chip(r.tipoEspecialista, const Color(0xFFACF0F2), const Color(0xFF1695A3)),
                              const SizedBox(width: 8),
                              _estadoBadge(r.estado),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(r.descripcion,
                              style: const TextStyle(color: Color(0xFF225378), fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(height: 2),
                          Text(r.propiedadNombre, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(color: Colors.grey.shade100),
                const SizedBox(height: 12),
                _sectionTitle('Detalles del Reporte'),
                const SizedBox(height: 10),
                _detailRow('Prioridad', r.prioridad.label, valueColor: r.prioridad.color),
                _detailRow('Creado', r.fechaRelativa),
                if (r.costoEstimado != null)
                  _detailRow('Costo estimado', '\$${r.costoEstimado!.toStringAsFixed(2)}'),
                if (r.costoFinal != null)
                  _detailRow('Costo final', '\$${r.costoFinal!.toStringAsFixed(2)}', valueColor: Colors.green),
                if (_detalle?.fechaResolucion != null) ...[
                  Builder(builder: (_) {
                    final fecha = DateTime.tryParse(_detalle!.fechaResolucion!);
                    if (fecha == null) return const SizedBox.shrink();
                    return _detailRow('Resuelto el',
                      '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}');
                  }),
                ],
                // Especialista
                if (_especialista != null) ...[
                  const SizedBox(height: 16),
                  _sectionTitle('Especialista Asignado'),
                  const SizedBox(height: 10),
                  _EspecialistaCard(
                    especialista: _especialista!,
                    onLlamar: () => _llamar(context, _especialista!.telefono),
                    onWhatsApp: () => _abrirWhatsApp(context, _especialista!.telefono),
                  ),
                ],
                // Reseñas existentes
                if (_resenas.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _sectionTitle('Reseñas'),
                  const SizedBox(height: 10),
                  ..._resenas.map((res) => _ResenaCard(resena: res)),
                ],
                // Formulario para calificar (solo si resuelto, tiene especialista y sin reseña propia)
                if (r.estado == ReporteEstado.resuelto &&
                    _especialista != null &&
                    _resenas.isEmpty) ...[
                  const SizedBox(height: 16),
                  _sectionTitle('Calificar Especialista'),
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
                  TextFormField(
                    controller: _resenaComentarioCtrl,
                    maxLines: 3,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF225378)),
                    decoration: InputDecoration(
                      hintText: 'Escribe un comentario (opcional)...',
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.all(12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF1695A3), width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_resenaCalif > 0)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _enviandoResena ? null : _enviarResena,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEB7F00),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: _enviandoResena
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Enviar Reseña', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/mantenimiento/editar', arguments: r.id)
                          .then((_) => Navigator.pop(context, true));
                    },
                    icon: const Icon(Icons.edit_outlined, color: Color(0xFF225378), size: 18),
                    label: const Text('Editar Reporte',
                        style: TextStyle(color: Color(0xFF225378), fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Color(0xFF225378)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _sectionTitle(String title) {
    return Text(title,
        style: const TextStyle(color: Color(0xFF225378), fontWeight: FontWeight.bold, fontSize: 14));
  }

  static Widget _detailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          Text(value, style: TextStyle(
            color: valueColor ?? const Color(0xFF225378),
            fontWeight: FontWeight.w600,
            fontSize: 12,
          )),
        ],
      ),
    );
  }

  static Widget _chip(String text, Color bg, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg.withOpacity(0.4), borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  static Widget _estadoBadge(ReporteEstado estado) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: estado.bgColor, borderRadius: BorderRadius.circular(10)),
      child: Text(estado.label,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: estado.textColor)),
    );
  }
}

// ─── ESPECIALISTA CARD ────────────────────────────────────────────────────────
class _EspecialistaCard extends StatelessWidget {
  final EspecialistaCompleto especialista;
  final VoidCallback onLlamar;
  final VoidCallback onWhatsApp;

  const _EspecialistaCard({
    required this.especialista,
    required this.onLlamar,
    required this.onWhatsApp,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
            decoration: const BoxDecoration(color: Color(0xFFACF0F2), shape: BoxShape.circle),
            child: const Icon(Icons.handyman_outlined, color: Color(0xFF1695A3), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(especialista.nombre,
                    style: const TextStyle(color: Color(0xFF225378), fontWeight: FontWeight.bold, fontSize: 14)),
                Text(especialista.especialidad, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star, color: Color(0xFFEB7F00), size: 13),
                    const SizedBox(width: 3),
                    Text(especialista.calificacion.toStringAsFixed(1),
                        style: const TextStyle(color: Color(0xFF225378), fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(width: 8),
                    Text('${especialista.aniosExperiencia} años exp.',
                        style: const TextStyle(color: Colors.grey, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              _ContactBtn(icon: Icons.phone_outlined, color: const Color(0xFF1695A3), tooltip: 'Llamar', onTap: onLlamar),
              const SizedBox(height: 6),
              _ContactBtn(icon: Icons.chat_outlined, color: const Color(0xFF25D366), tooltip: 'WhatsApp', onTap: onWhatsApp),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── RESEÑA CARD ──────────────────────────────────────────────────────────────
class _ResenaCard extends StatelessWidget {
  final ResenaResumen resena;
  const _ResenaCard({required this.resena});

  @override
  Widget build(BuildContext context) {
    return Container(
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
              i < resena.calificacion ? Icons.star : Icons.star_border,
              color: const Color(0xFFEB7F00),
              size: 14,
            )),
          ),
          if (resena.comentario.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(resena.comentario, style: const TextStyle(color: Color(0xFF225378), fontSize: 12)),
          ],
        ],
      ),
    );
  }
}

// ─── BOTÓN DE CONTACTO ────────────────────────────────────────────────────────
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
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }
}
