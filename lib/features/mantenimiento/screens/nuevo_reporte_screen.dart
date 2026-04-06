import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/services/api_client.dart';
import '../../../core/widgets/app_header.dart';
import '../../../data/services/mantenimiento_service.dart';
import '../../../data/services/propiedades_service.dart';

// (especialistas mock eliminados — ahora se cargan desde el API)

// ─── PANTALLA ─────────────────────────────────────────────────────────────────
class NuevoReporteScreen extends StatefulWidget {
  const NuevoReporteScreen({super.key});

  @override
  State<NuevoReporteScreen> createState() => _NuevoReporteScreenState();
}

class _NuevoReporteScreenState extends State<NuevoReporteScreen> {
  final _formKey = GlobalKey<FormState>();

  // ── Campos del modelo ReporteMantenimiento ────────────────────────────────
  final _descripcionCtrl   = TextEditingController();
  final _costoEstimadoCtrl = TextEditingController();
  String  _tipoEspecialista = '';
  String  _prioridad        = 'media';
  final String  _estado           = 'abierto';
  int?    _propiedadId;
  int?    _especialistaId;
  bool    _submitting = false;

  // Datos cargados del API
  List<Map<String, dynamic>> _propiedades = [];
  List<EspecialistaItem> _especialistasCargados = [];
  bool _loadingPropiedades = true;
  bool _loadingEspecialistas = false;

  static const List<String> _tiposRapidos = [
    'Fontanero', 'Electricista', 'Cerrajero',
    'Pintor', 'Carpintero', 'Albañil', 'HVAC', 'Otro',
  ];

  static const List<Map<String, dynamic>> _prioridades = [
    {'value': 'baja',    'label': 'Baja',    'color': Color(0xFF16A34A), 'icon': Icons.check_circle_outline},
    {'value': 'media',   'label': 'Media',   'color': Color(0xFFCA8A04), 'icon': Icons.schedule_outlined},
    {'value': 'alta',    'label': 'Alta',    'color': Color(0xFFDC2626), 'icon': Icons.warning_amber_outlined},
    {'value': 'urgente', 'label': 'Urgente', 'color': Color(0xFF7C3AED), 'icon': Icons.bolt_outlined},
  ];

  List<EspecialistaItem> get _especialistasSugeridos =>
      _tipoEspecialista.isEmpty ? [] : _especialistasCargados;

  bool get _puedeEnviar =>
      _descripcionCtrl.text.isNotEmpty &&
      _tipoEspecialista.isNotEmpty &&
      _propiedadId != null &&
      !_submitting;

  @override
  void initState() {
    super.initState();
    _cargarPropiedades();
  }

  Future<void> _cargarPropiedades() async {
    try {
      final items = await PropiedadesService.listar();
      setState(() {
        _propiedades = items.map((p) => {'id': p.id, 'nombre': p.nombre}).toList();
        _loadingPropiedades = false;
      });
    } catch (_) {
      setState(() => _loadingPropiedades = false);
    }
  }

  Future<void> _cargarEspecialistas(String tipo) async {
    setState(() => _loadingEspecialistas = true);
    try {
      final items = await EspecialistasService.listar(especialidad: tipo);
      setState(() {
        _especialistasCargados = items;
        _loadingEspecialistas = false;
      });
    } catch (_) {
      setState(() { _especialistasCargados = []; _loadingEspecialistas = false; });
    }
  }

  @override
  void dispose() {
    _descripcionCtrl.dispose();
    _costoEstimadoCtrl.dispose();
    super.dispose();
  }

  void _onSubmit() async {
    if (_formKey.currentState!.validate()) {
      if (_propiedadId == null) {
        _snack('Selecciona la propiedad afectada', Colors.red);
        return;
      }
      if (_tipoEspecialista.isEmpty) {
        _snack('Selecciona el tipo de especialista', Colors.red);
        return;
      }

      setState(() => _submitting = true);

      final data = {
        'propiedad':         _propiedadId,
        'descripcion':       _descripcionCtrl.text,
        'tipo_especialista': _tipoEspecialista,
        'prioridad':         _prioridad,
        'estado':            _estado,
        'costo_estimado':    _costoEstimadoCtrl.text.isEmpty
            ? null : _costoEstimadoCtrl.text,
        'especialista':      _especialistaId,
      };

      try {
        await ReportesMantenimientoService.crear(data);
        if (mounted) {
          _snack('Reporte creado correctamente', const Color(0xFF1695A3));
          Navigator.pop(context);
        }
      } on ApiException catch (e) {
        if (mounted) _snack(e.message, Colors.red);
      } catch (_) {
        if (mounted) _snack('Error de conexión', Colors.red);
      } finally {
        if (mounted) setState(() => _submitting = false);
      }
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const AppHeader(title: 'Nuevo Reporte', showBack: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
        child: Form(
          key: _formKey,
          onChanged: () => setState(() {}),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── 1. ¿Qué está fallando? ────────────────────────────────
              _card(
                icon: Icons.warning_amber_outlined,
                iconColor: const Color(0xFFEB7F00),
                title: '¿Qué está fallando?',
                child: TextFormField(
                  controller: _descripcionCtrl,
                  maxLines: 4,
                  maxLength: 500,
                  validator: (v) => v!.trim().isEmpty ? 'Describe el problema' : null,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF225378)),
                  decoration: InputDecoration(
                    hintText: 'Ej. Fuga en lavabo del baño principal, mancha en techo...',
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                    counterText: '',
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
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── 2. Propiedad afectada ─────────────────────────────────
              _card(
                icon: Icons.home_outlined,
                iconColor: const Color(0xFF1695A3),
                title: 'Propiedad Afectada',
                child: _buildPropiedadDropdown(),
              ),
              const SizedBox(height: 16),

              // ── 3. Tipo de especialista ───────────────────────────────
              _card(
                icon: Icons.build_outlined,
                iconColor: const Color(0xFF225378),
                title: 'Tipo de Especialista',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _tiposRapidos.map((tipo) {
                    final sel = _tipoEspecialista == tipo;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _tipoEspecialista = tipo;
                          _especialistaId = null;
                        });
                        _cargarEspecialistas(tipo);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 140),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 9),
                        decoration: BoxDecoration(
                          color: sel
                              ? const Color(0xFF225378)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: sel
                                ? const Color(0xFF225378)
                                : Colors.grey.shade200,
                          ),
                          boxShadow: sel
                              ? [BoxShadow(
                                  color: const Color(0xFF225378).withOpacity(0.25),
                                  blurRadius: 8, offset: const Offset(0, 3))]
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_tipoIcon(tipo),
                                size: 14,
                                color: sel ? Colors.white : Colors.grey),
                            const SizedBox(width: 6),
                            Text(tipo,
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: sel
                                        ? Colors.white
                                        : Colors.grey.shade600)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // ── 4. Prioridad ──────────────────────────────────────────
              _card(
                icon: Icons.flag_outlined,
                iconColor: const Color(0xFFEB7F00),
                title: 'Prioridad',
                child: Row(
                  children: _prioridades.map((p) {
                    final sel = _prioridad == p['value'];
                    final color = p['color'] as Color;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _prioridad = p['value'] as String),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 140),
                          margin: const EdgeInsets.only(right: 7),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          decoration: BoxDecoration(
                            color: sel
                                ? color.withOpacity(0.1)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: sel ? color : Colors.grey.shade200,
                              width: sel ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(p['icon'] as IconData,
                                  color: sel ? color : Colors.grey.shade300,
                                  size: 16),
                              const SizedBox(height: 4),
                              Text(p['label'] as String,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: sel
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: sel ? color : Colors.grey)),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // ── 5. Costo estimado (opcional) ──────────────────────────
              _card(
                icon: Icons.attach_money,
                iconColor: Colors.green,
                title: 'Costo Estimado (opcional)',
                child: TextFormField(
                  controller: _costoEstimadoCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'\d+\.?\d{0,2}')),
                  ],
                  style: const TextStyle(fontSize: 13, color: Color(0xFF225378)),
                  decoration: InputDecoration(
                    hintText: '0.00',
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                    prefixIcon: const Icon(Icons.attach_money,
                        color: Color(0xFF1695A3), size: 18),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 12),
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
                      borderSide: const BorderSide(
                          color: Color(0xFF1695A3), width: 2),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── 6. Especialistas sugeridos (aparece al seleccionar tipo) ─
              if (_tipoEspecialista.isNotEmpty) ...[
                _buildEspecialistasSugeridos(),
                const SizedBox(height: 16),
              ],

              // ── Botón crear reporte ───────────────────────────────────
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _puedeEnviar ? 1.0 : 0.5,
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _puedeEnviar ? _onSubmit : null,
                    icon: const Icon(Icons.build_outlined, size: 20),
                    label: const Text('Crear Reporte',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1695A3),
                      disabledBackgroundColor: Colors.grey.shade300,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 3,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── ESPECIALISTAS SUGERIDOS ───────────────────────────────────────────────
  Widget _buildEspecialistasSugeridos() {
    final lista = _especialistasSugeridos;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _sectionTitle(
                Icons.handyman_outlined, 'Especialistas Sugeridos'),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Text(_loadingEspecialistas ? 'Cargando...' : '${lista.length} encontrados',
                  style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_loadingEspecialistas)
          const Center(child: Padding(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(color: Color(0xFF1695A3), strokeWidth: 2),
          ))
        else if (lista.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: Text('No se encontraron especialistas',
                style: TextStyle(color: Colors.grey, fontSize: 12))),
          )
        else
          ...lista.map((esp) => _EspecialistaCard(
                especialista: esp,
                isSelected: _especialistaId == esp.id,
                onSelect: () => setState(() => _especialistaId =
                    _especialistaId == esp.id ? null : esp.id),
              )),
      ],
    );
  }

  // ── PROPIEDAD DROPDOWN ────────────────────────────────────────────────────
  Widget _buildPropiedadDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _propiedadId,
          isExpanded: true,
          hint: Row(
            children: [
              const Icon(Icons.home_outlined,
                  color: Color(0xFF1695A3), size: 18),
              const SizedBox(width: 8),
              Text('Seleccionar propiedad...',
                  style: TextStyle(
                      color: Colors.grey.shade500, fontSize: 13)),
            ],
          ),
          icon: const Icon(Icons.keyboard_arrow_down,
              color: Color(0xFF1695A3)),
          style: const TextStyle(
              fontSize: 13, color: Color(0xFF225378)),
          onChanged: (v) => setState(() => _propiedadId = v),
          items: _propiedades
              .map((p) => DropdownMenuItem<int>(
                    value: p['id'] as int,
                    child: Row(
                      children: [
                        const Icon(Icons.home_outlined,
                            color: Color(0xFF1695A3), size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(p['nombre'] as String,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }

  // ── HELPERS ───────────────────────────────────────────────────────────────
  Widget _card({
    required IconData icon,
    required Color iconColor,
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(icon, title, iconColor: iconColor),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _sectionTitle(IconData icon, String title,
      {Color iconColor = const Color(0xFF225378)}) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 16),
        const SizedBox(width: 7),
        Text(title,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF225378))),
      ],
    );
  }

  IconData _tipoIcon(String tipo) {
    switch (tipo) {
      case 'Fontanero':    return Icons.water_drop_outlined;
      case 'Electricista': return Icons.bolt_outlined;
      case 'Cerrajero':    return Icons.lock_outlined;
      case 'Pintor':       return Icons.format_paint_outlined;
      case 'Carpintero':   return Icons.carpenter;
      case 'Albañil':      return Icons.construction_outlined;
      case 'HVAC':         return Icons.ac_unit_outlined;
      default:             return Icons.handyman_outlined;
    }
  }
}

// ─── CARD ESPECIALISTA ────────────────────────────────────────────────────────
class _EspecialistaCard extends StatelessWidget {
  final EspecialistaItem especialista;
  final bool isSelected;
  final VoidCallback onSelect;

  const _EspecialistaCard({
    required this.especialista,
    required this.isSelected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelect,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF1695A3).withOpacity(0.05)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF1695A3)
                : Colors.grey.shade100,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: const Color(0xFF1695A3).withOpacity(0.12),
                      blurRadius: 10),
                ]
              : [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 6),
                ],
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF1695A3).withOpacity(0.15)
                    : const Color(0xFFACF0F2).withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  especialista.nombre[0].toUpperCase(),
                  style: TextStyle(
                      color: isSelected
                          ? const Color(0xFF1695A3)
                          : const Color(0xFF225378),
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(especialista.nombre,
                      style: const TextStyle(
                          color: Color(0xFF225378),
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                  Text(especialista.especialidad,
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 11)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star,
                          color: Color(0xFFEB7F00), size: 12),
                      const SizedBox(width: 3),
                      Text(
                          especialista.calificacion.toStringAsFixed(1),
                          style: const TextStyle(
                              color: Color(0xFF225378),
                              fontWeight: FontWeight.bold,
                              fontSize: 11)),
                      if (!especialista.disponible) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('No disponible',
                              style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Acciones
            Column(
              children: [
                // Check seleccionado
                if (isSelected) ...[
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: const BoxDecoration(
                      color: Color(0xFF1695A3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check,
                        color: Colors.white, size: 16),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}