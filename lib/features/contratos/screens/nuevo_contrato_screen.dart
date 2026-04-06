import 'package:flutter/material.dart';
import '../../../core/widgets/app_header.dart';
import '../../../data/services/contratos_service.dart';
import '../../../data/services/propiedades_service.dart';
import '../../../data/services/arrendatarios_service.dart';

class NuevoContratoScreen extends StatefulWidget {
  const NuevoContratoScreen({super.key});

  @override
  State<NuevoContratoScreen> createState() => _NuevoContratoScreenState();
}

class _NuevoContratoScreenState extends State<NuevoContratoScreen> {
  final _formKey = GlobalKey<FormState>();

  // Listas para dropdowns
  List<PropiedadItem> _propiedades = [];
  List<ArrendatarioItem> _arrendatarios = [];
  bool _cargandoDatos = true;

  // Valores seleccionados
  int? _propiedadId;
  int? _arrendatarioId;
  String _periodoPago = 'mensual';

  final _rentaCtrl      = TextEditingController();
  final _diaPagoCtrl    = TextEditingController();
  final _fechaInicioCtrl = TextEditingController();
  final _fechaFinCtrl    = TextEditingController();
  final _depositoCtrl   = TextEditingController();
  final _notasCtrl      = TextEditingController();

  static const _periodos = ['mensual', 'quincenal', 'semanal', 'anual'];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      final props = await PropiedadesService.listar();
      final arren = await ArrendatariosService.listar();
      if (!mounted) return;
      setState(() {
        _propiedades = props;
        _arrendatarios = arren;
        _cargandoDatos = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _cargandoDatos = false);
    }
  }

  @override
  void dispose() {
    _rentaCtrl.dispose();
    _diaPagoCtrl.dispose();
    _fechaInicioCtrl.dispose();
    _fechaFinCtrl.dispose();
    _depositoCtrl.dispose();
    _notasCtrl.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha(TextEditingController ctrl) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      locale: const Locale('es', 'ES'),
    );
    if (picked != null) {
      ctrl.text =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_propiedadId == null || _arrendatarioId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona propiedad y arrendatario'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      await ContratosService.crear({
        'propiedad':     _propiedadId,
        'arrendatario':  _arrendatarioId,
        'fecha_inicio':  _fechaInicioCtrl.text,
        'fecha_fin':     _fechaFinCtrl.text,
        'renta_acordada': _rentaCtrl.text,
        'dia_pago':      int.parse(_diaPagoCtrl.text),
        'periodo_pago':  _periodoPago,
        if (_depositoCtrl.text.isNotEmpty)
          'deposito': _depositoCtrl.text,
        if (_notasCtrl.text.isNotEmpty)
          'notas': _notasCtrl.text,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contrato creado correctamente'),
          backgroundColor: Color(0xFF1695A3),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const AppHeader(title: 'Nuevo Contrato', showBack: true),
      body: _cargandoDatos
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1695A3)))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('Propiedad y Arrendatario'),
                    const SizedBox(height: 12),

                    // Dropdown propiedad
                    DropdownButtonFormField<int>(
                      initialValue: _propiedadId,
                      decoration: _inputDeco('Propiedad',
                          Icons.home_outlined),
                      items: _propiedades
                          .map((p) => DropdownMenuItem(
                                value: p.id,
                                child: Text(p.nombre,
                                    style: const TextStyle(fontSize: 13)),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _propiedadId = v),
                      validator: (v) =>
                          v == null ? 'Selecciona una propiedad' : null,
                    ),
                    const SizedBox(height: 12),

                    // Dropdown arrendatario
                    DropdownButtonFormField<int>(
                      initialValue: _arrendatarioId,
                      decoration: _inputDeco('Arrendatario',
                          Icons.person_outline),
                      items: _arrendatarios
                          .map((a) => DropdownMenuItem(
                                value: a.id,
                                child: Text(a.nombreCompleto,
                                    style: const TextStyle(fontSize: 13)),
                              ))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _arrendatarioId = v),
                      validator: (v) =>
                          v == null ? 'Selecciona un arrendatario' : null,
                    ),
                    const SizedBox(height: 24),

                    _sectionTitle('Fechas y Pago'),
                    const SizedBox(height: 12),

                    // Fecha inicio
                    TextFormField(
                      controller: _fechaInicioCtrl,
                      readOnly: true,
                      decoration: _inputDeco('Fecha inicio',
                          Icons.calendar_today),
                      onTap: () => _seleccionarFecha(_fechaInicioCtrl),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 12),

                    // Fecha fin
                    TextFormField(
                      controller: _fechaFinCtrl,
                      readOnly: true,
                      decoration: _inputDeco('Fecha fin',
                          Icons.calendar_today),
                      onTap: () => _seleccionarFecha(_fechaFinCtrl),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Requerido';
                        if (_fechaInicioCtrl.text.isNotEmpty) {
                          final inicio = DateTime.tryParse(_fechaInicioCtrl.text);
                          final fin    = DateTime.tryParse(v);
                          if (inicio != null && fin != null && !fin.isAfter(inicio)) {
                            return 'Debe ser posterior a la fecha de inicio';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // Renta, día y periodo
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _rentaCtrl,
                            keyboardType: const TextInputType
                                .numberWithOptions(decimal: true),
                            decoration: _inputDeco('Renta mensual',
                                Icons.attach_money),
                            validator: (v) =>
                                v == null || v.isEmpty
                                    ? 'Requerido'
                                    : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _diaPagoCtrl,
                            keyboardType: TextInputType.number,
                            decoration: _inputDeco('Día pago',
                                Icons.calendar_today),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Req.';
                              final val = int.tryParse(v);
                              if (val == null || val < 1 || val > 31) return '1-31';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            initialValue: _periodoPago,
                            decoration: _inputDeco('Periodo',
                                Icons.repeat),
                            items: _periodos
                                .map((p) => DropdownMenuItem(
                                      value: p,
                                      child: Text(
                                          p[0].toUpperCase() +
                                              p.substring(1),
                                          style: const TextStyle(
                                              fontSize: 13)),
                                    ))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) {
                                setState(() => _periodoPago = v);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Deposito (opcional)
                    TextFormField(
                      controller: _depositoCtrl,
                      keyboardType: const TextInputType
                          .numberWithOptions(decimal: true),
                      decoration: _inputDeco(
                          'Depósito (opcional)', Icons.savings_outlined),
                    ),
                    const SizedBox(height: 12),

                    // Notas
                    TextFormField(
                      controller: _notasCtrl,
                      maxLines: 3,
                      decoration: _inputDeco(
                          'Notas (opcional)', Icons.notes_outlined),
                    ),
                    const SizedBox(height: 32),

                    // Botón guardar
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _guardar,
                        icon: const Icon(Icons.save_outlined, size: 20),
                        label: const Text('Crear Contrato',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF225378),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              vertical: 18),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(14)),
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

  // ── Helpers de UI ──────────────────────────────────────

  Widget _sectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: const Color(0xFF1695A3),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF225378),
                letterSpacing: 0.3)),
      ],
    );
  }

  InputDecoration _inputDeco(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 12, color: Colors.grey),
      prefixIcon: Icon(icon, color: const Color(0xFF1695A3), size: 18),
      contentPadding:
          const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            const BorderSide(color: Color(0xFF1695A3), width: 2),
      ),
    );
  }
}
