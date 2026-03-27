import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/services/api_client.dart';
import '../../../core/widgets/app_header.dart';
import '../../../data/services/mantenimiento_service.dart' as mant_svc;
import '../widgets/admin_models.dart';
import '../widgets/admin_data.dart';
import '../widgets/admin_helpers.dart';

class EditarEspecialistaScreen extends StatefulWidget {
  final Especialista especialista;

  const EditarEspecialistaScreen({
    super.key,
    required this.especialista,
  });

  @override
  State<EditarEspecialistaScreen> createState() =>
      _EditarEspecialistaScreenState();
}

class _EditarEspecialistaScreenState
    extends State<EditarEspecialistaScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nombreCtrl;
  late final TextEditingController _telefonoCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _ciudadCtrl;
  late final TextEditingController _estadoGeoCtrl;
  late final TextEditingController _aniosExpCtrl;
  late String _tipoSel;
  late bool _disponible;

  @override
  void initState() {
    super.initState();
    final e = widget.especialista;
    _nombreCtrl = TextEditingController(text: e.nombre);
    _telefonoCtrl = TextEditingController(text: e.telefono);
    _emailCtrl = TextEditingController(text: e.email);
    _ciudadCtrl = TextEditingController(text: e.ciudad);
    _estadoGeoCtrl = TextEditingController(text: e.estadoGeografico);
    _aniosExpCtrl =
        TextEditingController(text: e.aniosExperiencia.toString());
    _tipoSel = tiposEspecialista.contains(e.especialidad)
        ? e.especialidad
        : tiposEspecialista.first;
    _disponible = e.disponible;
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _telefonoCtrl.dispose();
    _emailCtrl.dispose();
    _ciudadCtrl.dispose();
    _estadoGeoCtrl.dispose();
    _aniosExpCtrl.dispose();
    super.dispose();
  }

  void _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final body = {
      'nombre': _nombreCtrl.text.trim(),
      'especialidad': _tipoSel,
      'telefono': _telefonoCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'ciudad': _ciudadCtrl.text.trim(),
      'estado_geografico': _estadoGeoCtrl.text.trim(),
      'anios_experiencia': int.tryParse(_aniosExpCtrl.text.trim()) ?? 0,
      'disponible': _disponible,
    };

    try {
      await mant_svc.EspecialistasService.actualizar(widget.especialista.id, body);
      final updated = widget.especialista.copyWith(
        nombre: _nombreCtrl.text.trim(),
        especialidad: _tipoSel,
        telefono: _telefonoCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        ciudad: _ciudadCtrl.text.trim(),
        estadoGeografico: _estadoGeoCtrl.text.trim(),
        aniosExperiencia: int.tryParse(_aniosExpCtrl.text.trim()) ?? 0,
        disponible: _disponible,
      );
      if (mounted) Navigator.pop(context, updated);
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
          content: Text('Error de conexión'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const AppHeader(
          title: 'Editar Especialista', showBack: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: const Color(0xFFACF0F2), width: 1.5),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4)),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                          color: Color(0xFFACF0F2),
                          shape: BoxShape.circle),
                      child: Center(
                        child: Text(
                          widget.especialista.inicial,
                          style: const TextStyle(
                              color: Color(0xFF225378),
                              fontWeight: FontWeight.bold,
                              fontSize: 18),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text('Editar Información',
                        style: TextStyle(
                            color: Color(0xFF225378),
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
                  ],
                ),
                const SizedBox(height: 22),

                // ── Nombre ──────────────────────────────────────────
                adminFieldLabel('Nombre / Empresa'),
                const SizedBox(height: 5),
                TextFormField(
                  controller: _nombreCtrl,
                  validator: (v) =>
                      v!.trim().isEmpty ? 'Requerido' : null,
                  style: const TextStyle(
                      fontSize: 13, color: Color(0xFF225378)),
                  decoration: adminFieldDecoration(
                      'Ej. Plomería Express',
                      Icons.person_outline),
                ),
                const SizedBox(height: 14),

                // ── Especialidad ────────────────────────────────────
                adminFieldLabel('Especialidad'),
                const SizedBox(height: 5),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: Colors.grey.shade200),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _tipoSel,
                      isExpanded: true,
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF225378)),
                      icon: const Icon(Icons.keyboard_arrow_down,
                          color: Color(0xFF1695A3)),
                      onChanged: (v) =>
                          setState(() => _tipoSel = v!),
                      items: tiposEspecialista
                          .map((t) => DropdownMenuItem(
                                value: t,
                                child: Text(t),
                              ))
                          .toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // ── Teléfono + Email ────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          adminFieldLabel('Teléfono'),
                          const SizedBox(height: 5),
                          TextFormField(
                            controller: _telefonoCtrl,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'[\d\s\-]')),
                              LengthLimitingTextInputFormatter(15),
                            ],
                            validator: (v) => v!.trim().isEmpty
                                ? 'Requerido'
                                : null,
                            style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF225378)),
                            decoration: adminFieldDecoration(
                                '55 0000 0000',
                                Icons.phone_outlined),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          adminFieldLabel('Email'),
                          const SizedBox(height: 5),
                          TextFormField(
                            controller: _emailCtrl,
                            keyboardType:
                                TextInputType.emailAddress,
                            validator: (v) {
                              if (v!.trim().isEmpty) {
                                return 'Requerido';
                              }
                              if (!v.contains('@')) {
                                return 'Email inválido';
                              }
                              return null;
                            },
                            style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF225378)),
                            decoration: adminFieldDecoration(
                                'correo@mail.mx',
                                Icons.mail_outline),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // ── Ciudad + Estado geográfico ──────────────────────
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          adminFieldLabel('Ciudad'),
                          const SizedBox(height: 5),
                          TextFormField(
                            controller: _ciudadCtrl,
                            validator: (v) => v!.trim().isEmpty
                                ? 'Requerido'
                                : null,
                            style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF225378)),
                            decoration: adminFieldDecoration(
                                'Ej. CDMX',
                                Icons.location_city_outlined),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          adminFieldLabel('Estado'),
                          const SizedBox(height: 5),
                          TextFormField(
                            controller: _estadoGeoCtrl,
                            validator: (v) => v!.trim().isEmpty
                                ? 'Requerido'
                                : null,
                            style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF225378)),
                            decoration: adminFieldDecoration(
                                'Ej. Jalisco',
                                Icons.map_outlined),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // ── Calificación (read-only) + Años experiencia ────
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          adminFieldLabel('Calificación (resenas)'),
                          const SizedBox(height: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.star,
                                    color: Color(0xFFEB7F00),
                                    size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  widget.especialista.calificacion
                                      .toStringAsFixed(1),
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF225378),
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          adminFieldLabel('Años de Experiencia'),
                          const SizedBox(height: 5),
                          TextFormField(
                            controller: _aniosExpCtrl,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(2),
                            ],
                            validator: (v) => v!.trim().isEmpty
                                ? 'Requerido'
                                : null,
                            style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF225378)),
                            decoration: adminFieldDecoration(
                                '0',
                                Icons
                                    .workspace_premium_outlined),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // ── Disponible ──────────────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline,
                          color: Color(0xFF1695A3), size: 18),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text('Disponible actualmente',
                            style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF225378),
                                fontWeight: FontWeight.w500)),
                      ),
                      Switch.adaptive(
                        value: _disponible,
                        onChanged: (v) =>
                            setState(() => _disponible = v),
                        activeColor: const Color(0xFF1695A3),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Botones ─────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: 15),
                          side: BorderSide(
                              color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(12)),
                        ),
                        child: const Text('Cancelar',
                            style: TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _guardar,
                        icon: const Icon(Icons.save_outlined,
                            size: 18),
                        label: const Text('Guardar',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(0xFF1695A3),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              vertical: 15),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
