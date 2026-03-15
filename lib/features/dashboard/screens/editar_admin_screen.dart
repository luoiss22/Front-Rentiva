import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../core/services/api_client.dart';
import '../../../core/widgets/app_header.dart';
import '../widgets/admin_models.dart';
import '../widgets/admin_helpers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PANTALLA: EDITAR ADMIN
// ─────────────────────────────────────────────────────────────────────────────
class EditarAdminScreen extends StatefulWidget {
  final Admin admin;
  const EditarAdminScreen({super.key, required this.admin});
  @override
  State<EditarAdminScreen> createState() => _EditarAdminScreenState();
}

class _EditarAdminScreenState extends State<EditarAdminScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  File? _imageFile;
  Uint8List? _webImage;
  bool _imagenCambiada = false;
  late TextEditingController _nombreCtrl,
      _apellidosCtrl,
      _telefonoCtrl,
      _emailCtrl,
      _folioIneCtrl;
  DateTime? _fechaNacimiento;
  String _rol = 'admin', _estado = 'activo';

  @override
  void initState() {
    super.initState();
    final a = widget.admin;
    _nombreCtrl = TextEditingController(text: a.nombre);
    _apellidosCtrl = TextEditingController(text: a.apellidos);
    _telefonoCtrl = TextEditingController(text: a.telefono);
    _emailCtrl = TextEditingController(text: a.email);
    _folioIneCtrl = TextEditingController(text: a.folioIne);
    _fechaNacimiento = a.fechaNacimiento;
    _rol = a.rol;
    _estado = a.estado;
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apellidosCtrl.dispose();
    _telefonoCtrl.dispose();
    _emailCtrl.dispose();
    _folioIneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? img =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (img == null) return;
    if (kIsWeb) {
      final b = await img.readAsBytes();
      setState(() {
        _webImage = b;
        _imagenCambiada = true;
      });
    } else {
      setState(() {
        _imageFile = File(img.path);
        _imagenCambiada = true;
      });
    }
  }

  Future<void> _pickFecha() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaNacimiento ?? DateTime(now.year - 30),
      firstDate: DateTime(1940),
      lastDate: DateTime(now.year - 18),
      builder: (ctx, child) => Theme(
          data: Theme.of(ctx).copyWith(
              colorScheme: const ColorScheme.light(
                  primary: Color(0xFF225378),
                  onPrimary: Colors.white,
                  surface: Colors.white,
                  onSurface: Color(0xFF225378))),
          child: child!),
    );
    if (picked != null) setState(() => _fechaNacimiento = picked);
  }

  void _onSubmit() async {
    if (_formKey.currentState!.validate()) {
      final body = <String, dynamic>{
        'nombre': _nombreCtrl.text.trim(),
        'apellidos': _apellidosCtrl.text.trim(),
        'telefono': _telefonoCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'folio_ine': _folioIneCtrl.text.trim().toUpperCase(),
        'estado': _estado,
      };
      if (_fechaNacimiento != null) {
        body['fecha_nacimiento'] = _fechaNacimiento!.toIso8601String().split('T').first;
      }

      try {
        await ApiClient.patch('/propietarios/${widget.admin.id}/', body);
        // Si cambio el rol, usar endpoint dedicado
        if (_rol != widget.admin.rol) {
          await ApiClient.patch('/admin/propietarios/${widget.admin.id}/rol/', {'rol': _rol});
        }
        final updated = widget.admin.copyWith(
          nombre: _nombreCtrl.text.trim(),
          apellidos: _apellidosCtrl.text.trim(),
          fechaNacimiento: _fechaNacimiento,
          telefono: _telefonoCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          folioIne: _folioIneCtrl.text.trim().toUpperCase(),
          rol: _rol,
          estado: _estado,
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
  }

  void _onDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                  color: Colors.red.shade50, shape: BoxShape.circle),
              child: Icon(Icons.delete_outline,
                  color: Colors.red.shade400, size: 26)),
          const SizedBox(height: 14),
          const Text('¿Eliminar administrador?',
              style: TextStyle(
                  color: Color(0xFF225378),
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
          const SizedBox(height: 8),
          Text(
              'Se eliminará a "${widget.admin.nombreCompleto}" del sistema permanentemente.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.grey, fontSize: 13, height: 1.4)),
          const SizedBox(height: 22),
          Row(children: [
            Expanded(
                child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                    child: const Text('Cancelar',
                        style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.w600)))),
            const SizedBox(width: 12),
            Expanded(
                child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      try {
                        await ApiClient.delete('/propietarios/${widget.admin.id}/');
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                              content: Text('Administrador eliminado'),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating));
                          Navigator.pushNamedAndRemoveUntil(
                              context, '/admin', (r) => false);
                        }
                      } on ApiException catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(e.message),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating));
                        }
                      } catch (_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                              content: Text('Error al eliminar'),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating));
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade400,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0),
                    child: const Text('Eliminar',
                        style: TextStyle(fontWeight: FontWeight.bold)))),
          ]),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const AppHeader(title: 'Editar Administrador', showBack: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
        child: Form(
            key: _formKey,
            child: Column(children: [
              // Botón eliminar
              Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                      onTap: _onDelete,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 9),
                        decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(10)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.delete_outline,
                              color: Colors.red.shade400, size: 16),
                          const SizedBox(width: 6),
                          Text('Eliminar Administrador',
                              style: TextStyle(
                                  color: Colors.red.shade400,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)),
                        ]),
                      ))),
              const SizedBox(height: 16),

              _buildAvatar(),
              const SizedBox(height: 28),
              adminSectionTitle(Icons.person_outline, 'Datos Personales'),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(
                    child: _buildField('Nombre', _nombreCtrl, 'Juan',
                        Icons.badge_outlined,
                        required: true, maxLen: 120)),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildField('Apellidos', _apellidosCtrl,
                        'Pérez López', Icons.badge_outlined,
                        required: true, maxLen: 120)),
              ]),
              const SizedBox(height: 12),
              _buildField('Teléfono', _telefonoCtrl, '55 1234 5678',
                  Icons.phone_outlined,
                  required: true,
                  keyboard: TextInputType.phone,
                  formatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d\s\-]')),
                    LengthLimitingTextInputFormatter(20)
                  ]),
              const SizedBox(height: 12),
              _buildField('Correo Electrónico', _emailCtrl,
                  'admin@rentiva.com', Icons.mail_outline,
                  required: true,
                  keyboard: TextInputType.emailAddress,
                  extraValidator: (v) =>
                      !v!.contains('@') ? 'Email inválido' : null),
              const SizedBox(height: 12),
              _buildDatePicker(),
              const SizedBox(height: 12),
              _buildField(
                  'Folio INE / Clave Electoral',
                  _folioIneCtrl,
                  'PELJ901012HDFRZN01',
                  Icons.credit_card_outlined,
                  required: true,
                  maxLen: 20,
                  textCap: TextCapitalization.characters,
                  formatters: [
                    UpperCaseFormatter(),
                    LengthLimitingTextInputFormatter(20),
                    FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]'))
                  ],
                  extraValidator: (v) =>
                      v!.length < 18 ? 'Mínimo 18 caracteres' : null),
              const SizedBox(height: 24),
              adminSectionTitle(Icons.shield_outlined, 'Rol'),
              const SizedBox(height: 14),
              _buildRolSelector(),
              const SizedBox(height: 24),
              adminSectionTitle(Icons.toggle_on_outlined, 'Estado'),
              const SizedBox(height: 14),
              _buildEstadoSelector(),
              const SizedBox(height: 32),
              SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _onSubmit,
                    icon: const Icon(Icons.save_outlined, size: 20),
                    label: const Text('Guardar Cambios',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF225378),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 3),
                  )),
            ])),
      ),
    );
  }

  Widget _buildAvatar() {
    final hasNew = _webImage != null || _imageFile != null;
    final hasExisting = !_imagenCambiada && widget.admin.fotoUrl != null;
    final inicial =
        _nombreCtrl.text.isNotEmpty ? _nombreCtrl.text[0].toUpperCase() : '?';
    Widget content;
    if (hasNew) {
      content = ClipOval(
          child: kIsWeb
              ? Image.memory(_webImage!, fit: BoxFit.cover)
              : Image.file(_imageFile!, fit: BoxFit.cover));
    } else if (hasExisting) {
      content = ClipOval(
          child: Image.network(widget.admin.fotoUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Center(
                  child: Text(inicial,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold)))));
    } else {
      content = Center(
          child: Text(inicial,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold)));
    }
    return Center(
        child: Stack(children: [
      GestureDetector(
          onTap: _pickImage,
          child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF225378), Color(0xFF1695A3)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                        color: const Color(0xFF225378).withOpacity(0.25),
                        blurRadius: 12)
                  ]),
              child: content)),
      Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
              onTap: _pickImage,
              child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                      color: Color(0xFFEB7F00), shape: BoxShape.circle),
                  child: const Icon(Icons.camera_alt,
                      color: Colors.white, size: 14)))),
    ]));
  }

  Widget _buildDatePicker() => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            adminFieldLabel('Fecha de Nacimiento'),
            const SizedBox(height: 6),
            GestureDetector(
                onTap: _pickFecha,
                child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 15),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200)),
                    child: Row(children: [
                      const Icon(Icons.calendar_today_outlined,
                          color: Color(0xFF1695A3), size: 18),
                      const SizedBox(width: 12),
                      Text(
                          _fechaNacimiento != null
                              ? adminFmtDate(_fechaNacimiento!)
                              : 'Seleccionar (opcional)',
                          style: TextStyle(
                              color: _fechaNacimiento != null
                                  ? const Color(0xFF225378)
                                  : Colors.grey,
                              fontSize: 13)),
                    ]))),
          ]);

  Widget _buildRolSelector() {
    final roles = [
      {
        'value': 'admin',
        'label': 'Admin',
        'icon': Icons.shield_outlined,
        'color': const Color(0xFF225378)
      },
      {
        'value': 'propietario',
        'label': 'Propietario',
        'icon': Icons.home_outlined,
        'color': const Color(0xFF1695A3)
      },
    ];
    return Row(
        children: roles.map((r) {
      final sel = _rol == r['value'];
      final color = r['color'] as Color;
      return Expanded(
          child: GestureDetector(
              onTap: () => setState(() => _rol = r['value'] as String),
              child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                      color: sel ? color.withOpacity(0.1) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: sel ? color : Colors.grey.shade200,
                          width: sel ? 2 : 1)),
                  child: Column(children: [
                    Icon(r['icon'] as IconData,
                        color: sel ? color : Colors.grey, size: 22),
                    const SizedBox(height: 4),
                    Text(r['label'] as String,
                        style: TextStyle(
                            color: sel ? color : Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                  ]))));
    }).toList());
  }

  Widget _buildEstadoSelector() {
    final estados = [
      {
        'value': 'activo',
        'label': 'Activo',
        'color': const Color(0xFF1695A3)
      },
      {'value': 'inactivo', 'label': 'Inactivo', 'color': Colors.grey},
      {'value': 'suspendido', 'label': 'Suspendido', 'color': Colors.orange},
    ];
    return Row(
        children: estados.map((e) {
      final sel = _estado == e['value'];
      final color = e['color'] as Color;
      return Expanded(
          child: GestureDetector(
        onTap: () => setState(() => _estado = e['value'] as String),
        child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
                color: sel ? color.withOpacity(0.1) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: sel ? color : Colors.grey.shade200,
                    width: sel ? 2 : 1)),
            child: Text(e['label'] as String,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: sel ? color : Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 12))),
      ));
    }).toList());
  }

  Widget _buildField(String label, TextEditingController ctrl, String hint,
          IconData icon,
          {bool required = false,
          int? maxLen,
          TextInputType keyboard = TextInputType.text,
          TextCapitalization textCap = TextCapitalization.none,
          List<TextInputFormatter>? formatters,
          String? Function(String?)? extraValidator}) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        adminFieldLabel(label),
        const SizedBox(height: 6),
        TextFormField(
            controller: ctrl,
            keyboardType: keyboard,
            textCapitalization: textCap,
            maxLength: maxLen,
            inputFormatters: formatters,
            onChanged: (_) => setState(() {}),
            validator: (v) {
              if (required && (v == null || v.trim().isEmpty)) {
                return 'Requerido';
              }
              return extraValidator?.call(v);
            },
            style: const TextStyle(fontSize: 13, color: Color(0xFF225378)),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
              prefixIcon:
                  Icon(icon, color: const Color(0xFF1695A3), size: 18),
              counterText: '',
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: Color(0xFF1695A3), width: 2)),
              errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.red)),
              focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Colors.red, width: 2)),
            )),
      ]);
}
