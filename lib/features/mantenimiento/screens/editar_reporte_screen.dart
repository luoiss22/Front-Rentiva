import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/services/api_client.dart';
import '../../../core/widgets/app_header.dart';
import '../../../data/services/mantenimiento_service.dart';
import '../../../data/services/propiedades_service.dart';

// (mock data eliminado — ahora se carga desde el API)

// ─── PANTALLA ─────────────────────────────────────────────────────────────────
class EditarReporteScreen extends StatefulWidget {
  final int? reporteId;
  const EditarReporteScreen({super.key, this.reporteId});

  @override
  State<EditarReporteScreen> createState() => _EditarReporteScreenState();
}

class _EditarReporteScreenState extends State<EditarReporteScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _loadingData = true;
  String? _loadError;

  late TextEditingController _descripcionCtrl;
  late TextEditingController _costoEstimadoCtrl;
  late TextEditingController _costoFinalCtrl;

  String _tipoEspecialista = '';
  String _prioridad        = 'media';
  String _estado           = 'abierto';
  int?   _propiedadId;
  int?   _reporteId;

  List<Map<String, dynamic>> _propiedades = [];

  // TODO: GET /api/propiedades/
  // (ahora se cargan del API)

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

  static const List<Map<String, dynamic>> _estadosFlujo = [
    {
      'value': 'abierto',
      'label': 'Abierto',
      'sublabel': 'Pendiente de atender',
      'color': Color(0xFFBE123C),
      'bgColor': Color(0xFFFFE4E6),
      'icon': Icons.radio_button_unchecked,
    },
    {
      'value': 'en_proceso',
      'label': 'En Proceso',
      'sublabel': 'Siendo atendido',
      'color': Color(0xFFA16207),
      'bgColor': Color(0xFFFEF9C3),
      'icon': Icons.settings_outlined,
    },
    {
      'value': 'resuelto',
      'label': 'Resuelto',
      'sublabel': 'Problema solucionado',
      'color': Color(0xFF15803D),
      'bgColor': Color(0xFFDCFCE7),
      'icon': Icons.check_circle_outline,
    },
    {
      'value': 'cancelado',
      'label': 'Cancelado',
      'sublabel': 'Reporte cancelado',
      'color': Colors.grey,
      'bgColor': Color(0xFFF1F5F9),
      'icon': Icons.cancel_outlined,
    },
  ];

  @override
  void initState() {
    super.initState();
    _descripcionCtrl   = TextEditingController();
    _costoEstimadoCtrl = TextEditingController();
    _costoFinalCtrl    = TextEditingController();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      // Cargar propiedades
      try {
        final props = await PropiedadesService.listar();
        _propiedades = props.map((p) => {'id': p.id, 'nombre': p.nombre}).toList();
      } catch (_) {}

      // Cargar reporte
      final id = widget.reporteId;
      if (id == null) {
        setState(() { _loadError = 'ID de reporte no proporcionado'; _loadingData = false; });
        return;
      }
      _reporteId = id;
      final det = await ReportesMantenimientoService.detalle(id);
      setState(() {
        _descripcionCtrl.text   = det.descripcion;
        _costoEstimadoCtrl.text = det.costoEstimado?.toStringAsFixed(2) ?? '';
        _costoFinalCtrl.text    = det.costoFinal?.toStringAsFixed(2) ?? '';
        _tipoEspecialista       = det.tipoEspecialista;
        _prioridad              = det.prioridad;
        _estado                 = det.estado;
        _propiedadId            = det.propiedadId;
        _loadingData            = false;
      });
    } on ApiException catch (e) {
      setState(() { _loadError = e.message; _loadingData = false; });
    } catch (e) {
      setState(() { _loadError = 'Error de conexión'; _loadingData = false; });
    }
  }

  @override
  void dispose() {
    _descripcionCtrl.dispose();
    _costoEstimadoCtrl.dispose();
    _costoFinalCtrl.dispose();
    super.dispose();
  }

  // ── SUBMIT ────────────────────────────────────────────────────────────────
  void _onSubmit() async {
    if (_formKey.currentState!.validate()) {
      final data = {
        'propiedad':         _propiedadId,
        'descripcion':       _descripcionCtrl.text,
        'tipo_especialista': _tipoEspecialista,
        'prioridad':         _prioridad,
        'estado':            _estado,
        'costo_estimado': _costoEstimadoCtrl.text.isEmpty
            ? null : _costoEstimadoCtrl.text,
        'costo_final': _costoFinalCtrl.text.isEmpty
            ? null : _costoFinalCtrl.text,
      };

      try {
        await ReportesMantenimientoService.actualizar(_reporteId!, data);
        if (mounted) {
          _snack('Reporte actualizado correctamente', const Color(0xFF1695A3));
          Navigator.pop(context);
        }
      } on ApiException catch (e) {
        if (mounted) _snack(e.message, Colors.red);
      } catch (_) {
        if (mounted) _snack('Error de conexión', Colors.red);
      }
    }
  }

  // ── DELETE ────────────────────────────────────────────────────────────────
  void _onDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Eliminar Reporte',
            style: TextStyle(
                color: Color(0xFF225378), fontWeight: FontWeight.bold)),
        content: Text(
          '¿Estás seguro de eliminar el reporte #$_reporteId?\n'
          'Esta acción no se puede deshacer.',
          style: const TextStyle(color: Colors.grey, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar',
                style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ReportesMantenimientoService.eliminar(_reporteId!);
                if (context.mounted) {
                  _snack('Reporte eliminado', Colors.red);
                  Navigator.pushNamedAndRemoveUntil(
                      context, '/mantenimiento', (r) => false);
                }
              } on ApiException catch (e) {
                if (context.mounted) _snack(e.message, Colors.red);
              } catch (_) {
                if (context.mounted) _snack('Error al eliminar', Colors.red);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text('Eliminar',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
    ));
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const AppHeader(title: 'Editar Reporte', showBack: true),
      body: _loadingData
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1695A3)))
          : _loadError != null
              ? Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_loadError!, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 12),
                    ElevatedButton(onPressed: _cargarDatos, child: const Text('Reintentar')),
                  ],
                ))
              : SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Botón eliminar ───────────────────────────────────────
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: _onDelete,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.delete_outline,
                            color: Colors.red.shade400, size: 16),
                        const SizedBox(width: 6),
                        Text('Eliminar Reporte',
                            style: TextStyle(
                                color: Colors.red.shade400,
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── 1. ESTADO — stepper interactivo ─────────────────────
              _card(
                icon: Icons.swap_horiz_outlined,
                iconColor: const Color(0xFF1695A3),
                title: 'Estado del Reporte',
                child: _buildEstadoFlujo(),
              ),
              const SizedBox(height: 16),

              // ── 2. Propiedad ─────────────────────────────────────────
              _card(
                icon: Icons.home_outlined,
                iconColor: const Color(0xFF1695A3),
                title: 'Propiedad Afectada',
                child: _buildPropiedadDropdown(),
              ),
              const SizedBox(height: 16),

              // ── 3. Descripción ───────────────────────────────────────
              _card(
                icon: Icons.warning_amber_outlined,
                iconColor: const Color(0xFFEB7F00),
                title: 'Descripción del Problema',
                child: TextFormField(
                  controller: _descripcionCtrl,
                  maxLines: 4,
                  maxLength: 500,
                  validator: (v) =>
                      v!.trim().isEmpty ? 'Describe el problema' : null,
                  style: const TextStyle(
                      fontSize: 13, color: Color(0xFF225378)),
                  decoration: _inputDeco(
                      'Describe detalladamente el problema...'),
                ),
              ),
              const SizedBox(height: 16),

              // ── 4. Tipo especialista ─────────────────────────────────
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
                      onTap: () =>
                          setState(() => _tipoEspecialista = tipo),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 140),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 13, vertical: 8),
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
                                  color: const Color(0xFF225378)
                                      .withOpacity(0.25),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3))]
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_tipoIcon(tipo),
                                size: 13,
                                color: sel
                                    ? Colors.white
                                    : Colors.grey),
                            const SizedBox(width: 5),
                            Text(tipo,
                                style: TextStyle(
                                    fontSize: 11,
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

              // ── 5. Prioridad ─────────────────────────────────────────
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
                        onTap: () => setState(
                            () => _prioridad = p['value'] as String),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 140),
                          margin: const EdgeInsets.only(right: 7),
                          padding:
                              const EdgeInsets.symmetric(vertical: 11),
                          decoration: BoxDecoration(
                            color: sel
                                ? color.withOpacity(0.10)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color:
                                  sel ? color : Colors.grey.shade200,
                              width: sel ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(p['icon'] as IconData,
                                  color: sel
                                      ? color
                                      : Colors.grey.shade300,
                                  size: 16),
                              const SizedBox(height: 4),
                              Text(p['label'] as String,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: sel
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color:
                                          sel ? color : Colors.grey)),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // ── 6. Costos ────────────────────────────────────────────
              _card(
                icon: Icons.attach_money,
                iconColor: Colors.green,
                title: 'Costos',
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _costField(
                        label: 'Estimado',
                        ctrl: _costoEstimadoCtrl,
                        hint: '0.00',
                        enabled: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _costField(
                        label: 'Final (real)',
                        ctrl: _costoFinalCtrl,
                        hint: '0.00',
                        enabled: _estado == 'resuelto',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ── Botón guardar ────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _onSubmit,
                  icon: const Icon(Icons.save_outlined, size: 20),
                  label: const Text('Guardar Cambios',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF225378),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── STEPPER DE ESTADO ─────────────────────────────────────────────────────
  Widget _buildEstadoFlujo() {
    return Column(
      children: [
        // Círculos + líneas conectoras
        Row(
          children: List.generate(_estadosFlujo.length, (i) {
            final e        = _estadosFlujo[i];
            final eValue   = e['value'] as String;
            final isActive = _estado == eValue;
            final isPast   = _indexOf(_estado) > i;
            final color    = e['color'] as Color;
            final isLast   = i == _estadosFlujo.length - 1;

            return Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _estado = eValue),
                      child: Column(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? color
                                  : isPast
                                      ? color.withOpacity(0.15)
                                      : Colors.grey.shade100,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isActive || isPast
                                    ? color
                                    : Colors.grey.shade200,
                                width: isActive ? 2.5 : 1.5,
                              ),
                              boxShadow: isActive
                                  ? [BoxShadow(
                                      color: color.withOpacity(0.35),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4))]
                                  : null,
                            ),
                            child: Icon(
                              e['icon'] as IconData,
                              size: 17,
                              color: isActive
                                  ? Colors.white
                                  : isPast
                                      ? color
                                      : Colors.grey.shade300,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            e['label'] as String,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: isActive
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isActive
                                  ? color
                                  : Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Línea conectora
                  if (!isLast)
                    Expanded(
                      child: Container(
                        height: 2,
                        margin: const EdgeInsets.only(bottom: 22),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isPast
                                ? [
                                    color,
                                    (_estadosFlujo[i + 1]['color'] as Color)
                                  ]
                                : [
                                    Colors.grey.shade200,
                                    Colors.grey.shade200
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
        ),

        const SizedBox(height: 14),

        // Banner descripción estado activo
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Container(
            key: ValueKey(_estado),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: _currentE['bgColor'] as Color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(_currentE['icon'] as IconData,
                    color: _currentE['color'] as Color, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentE['label'] as String,
                        style: TextStyle(
                            color: _currentE['color'] as Color,
                            fontWeight: FontWeight.bold,
                            fontSize: 13),
                      ),
                      Text(
                        _currentE['sublabel'] as String,
                        style: TextStyle(
                            color: (_currentE['color'] as Color)
                                .withOpacity(0.7),
                            fontSize: 11),
                      ),
                    ],
                  ),
                ),
                // Hint costo final
                if (_estado == 'resuelto')
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Registra costo final ↓',
                        style: TextStyle(
                            color: Color(0xFF15803D),
                            fontSize: 9,
                            fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Map<String, dynamic> get _currentE => _estadosFlujo
      .firstWhere((e) => e['value'] == _estado,
          orElse: () => _estadosFlujo[0]);

  int _indexOf(String val) =>
      _estadosFlujo.indexWhere((e) => e['value'] == val);

  // ── CAMPO COSTO ───────────────────────────────────────────────────────────
  Widget _costField({
    required String label,
    required TextEditingController ctrl,
    required String hint,
    required bool enabled,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF225378))),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          enabled: enabled,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(
                RegExp(r'\d+\.?\d{0,2}')),
          ],
          style: TextStyle(
              fontSize: 13,
              color: enabled
                  ? const Color(0xFF225378)
                  : Colors.grey.shade400),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                TextStyle(color: Colors.grey.shade400, fontSize: 13),
            prefixIcon: Icon(Icons.attach_money,
                color: enabled
                    ? const Color(0xFF1695A3)
                    : Colors.grey.shade300,
                size: 18),
            filled: true,
            fillColor: enabled
                ? const Color(0xFFF8FAFC)
                : Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(
                vertical: 12, horizontal: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade100),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                  color: Color(0xFF1695A3), width: 2),
            ),
          ),
        ),
        if (!enabled)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text('Disponible al marcar Resuelto',
                style: TextStyle(
                    color: Colors.grey.shade400, fontSize: 9)),
          ),
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
          Row(
            children: [
              Icon(icon, color: iconColor, size: 16),
              const SizedBox(width: 7),
              Text(title,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF225378))),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  InputDecoration _inputDeco(String hint) => InputDecoration(
        hintText: hint,
        hintStyle:
            TextStyle(color: Colors.grey.shade400, fontSize: 13),
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
          borderSide:
              const BorderSide(color: Color(0xFF1695A3), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red),
        ),
      );

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