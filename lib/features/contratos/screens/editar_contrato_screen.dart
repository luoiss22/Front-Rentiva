// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import '../../../core/services/api_client.dart';
import '../../../core/widgets/app_header.dart';
import '../../../data/services/contratos_service.dart';

class EditarContratoScreen extends StatefulWidget {
  final int? contratoId;
  const EditarContratoScreen({super.key, this.contratoId});

  @override
  State<EditarContratoScreen> createState() => _EditarContratoScreenState();
}

class _EditarContratoScreenState extends State<EditarContratoScreen> {
  final _formKey = GlobalKey<FormState>();

  bool _cargando = true;
  bool _guardando = false;
  String? _error;

  String _periodoPago = 'mensual';
  final _rentaCtrl       = TextEditingController();
  final _diaPagoCtrl     = TextEditingController();
  final _fechaInicioCtrl = TextEditingController();
  final _fechaFinCtrl    = TextEditingController();
  final _depositoCtrl    = TextEditingController();
  final _notasCtrl       = TextEditingController();

  static const _periodos = ['diario', 'mensual', 'anual'];

  @override
  void initState() {
    super.initState();
    _cargar();
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

  Future<void> _cargar() async {
    if (widget.contratoId == null) {
      setState(() { _cargando = false; _error = 'ID no válido'; });
      return;
    }
    try {
      final data = await ContratosService.detalle(widget.contratoId!);
      if (!mounted) return;
      _rentaCtrl.text       = data['renta_acordada']?.toString() ?? '';
      _diaPagoCtrl.text     = data['dia_pago']?.toString() ?? '';
      _fechaInicioCtrl.text = data['fecha_inicio'] ?? '';
      _fechaFinCtrl.text    = data['fecha_fin'] ?? '';
      _depositoCtrl.text    = data['deposito']?.toString() ?? '';
      _notasCtrl.text       = data['observaciones'] ?? '';
      _periodoPago          = data['periodo_pago'] ?? 'mensual';
      setState(() => _cargando = false);
    } catch (e) {
      if (!mounted) return;
      setState(() { _cargando = false; _error = e.toString(); });
    }
  }

  Future<void> _seleccionarFecha(TextEditingController ctrl) async {
    final initial = DateTime.tryParse(ctrl.text) ?? DateTime.now();
    final picked  = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      locale: const Locale('es', 'ES'),
    );
    if (picked != null) {
      ctrl.text =
          '${picked.year}-${picked.month.toString().padLeft(2,'0')}-${picked.day.toString().padLeft(2,'0')}';
    }
  }


  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_guardando) return;
    setState(() => _guardando = true);
    try {
      await ContratosService.actualizar(widget.contratoId!, {
        'fecha_inicio':   _fechaInicioCtrl.text,
        'fecha_fin':      _fechaFinCtrl.text,
        'renta_acordada': _rentaCtrl.text,
        'dia_pago':       int.parse(_diaPagoCtrl.text),
        'periodo_pago':   _periodoPago,
        if (_depositoCtrl.text.isNotEmpty) 'deposito': _depositoCtrl.text,
        if (_notasCtrl.text.isNotEmpty)    'observaciones': _notasCtrl.text,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contrato actualizado'),
          backgroundColor: Color(0xFF1695A3),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message),
            backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sin conexión con el servidor'),
            backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFF1695A3))),
      );
    }
    if (_error != null) {
      return Scaffold(
        appBar: const AppHeader(title: 'Editar Contrato', showBack: true),
        body: Center(child: Text(_error!, style: const TextStyle(color: Colors.red))),
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const AppHeader(title: 'Editar Contrato', showBack: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('Fechas'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _fechaInicioCtrl,
                readOnly: true,
                decoration: _inputDeco('Fecha inicio', Icons.calendar_today),
                onTap: () => _seleccionarFecha(_fechaInicioCtrl),
                validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _fechaFinCtrl,
                readOnly: true,
                decoration: _inputDeco('Fecha fin', Icons.calendar_today),
                onTap: () => _seleccionarFecha(_fechaFinCtrl),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Requerido';
                  final inicio = DateTime.tryParse(_fechaInicioCtrl.text);
                  final fin    = DateTime.tryParse(v);
                  if (inicio != null && fin != null && !fin.isAfter(inicio)) {
                    return 'Debe ser posterior a la fecha de inicio';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              _sectionTitle('Pago'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _rentaCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: _inputDeco('Renta', Icons.attach_money),
                      validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _diaPagoCtrl,
                      keyboardType: TextInputType.number,
                      decoration: _inputDeco('Día pago', Icons.calendar_today),
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
                      value: _periodoPago,
                      decoration: _inputDeco('Periodo', Icons.repeat),
                      items: _periodos.map((p) => DropdownMenuItem(
                        value: p,
                        child: Text(p[0].toUpperCase() + p.substring(1),
                            style: const TextStyle(fontSize: 13)),
                      )).toList(),
                      onChanged: (v) { if (v != null) setState(() => _periodoPago = v); },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _depositoCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: _inputDeco('Depósito (opcional)', Icons.savings_outlined),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notasCtrl,
                maxLines: 3,
                decoration: _inputDeco('Notas (opcional)', Icons.notes_outlined),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _guardando ? null : _guardar,
                  icon: _guardando
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save_outlined, size: 20),
                  label: Text(_guardando ? 'Guardando...' : 'Guardar Cambios',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF225378),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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


  Widget _sectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4, height: 18,
          decoration: BoxDecoration(
            color: const Color(0xFF1695A3),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.bold,
                color: Color(0xFF225378), letterSpacing: 0.3)),
      ],
    );
  }

  InputDecoration _inputDeco(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 12, color: Colors.grey),
      prefixIcon: Icon(icon, color: const Color(0xFF1695A3), size: 18),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
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
        borderSide: const BorderSide(color: Color(0xFF1695A3), width: 2),
      ),
    );
  }
}
