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
// PANTALLA: NUEVO ADMIN
// ─────────────────────────────────────────────────────────────────────────────
class NuevoAdminScreen extends StatefulWidget {
  const NuevoAdminScreen({super.key});
  @override
  State<NuevoAdminScreen> createState() => _NuevoAdminScreenState();
}

class _NuevoAdminScreenState extends State<NuevoAdminScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  File? _imageFile;
  Uint8List? _webImage;
  final _nombreCtrl = TextEditingController();
  final _apellidosCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _folioIneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  DateTime? _fechaNacimiento;
  String _rol = 'admin';
  String _estado = 'activo';

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apellidosCtrl.dispose();
    _telefonoCtrl.dispose();
    _emailCtrl.dispose();
    _folioIneCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? img =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (img == null) return;
    if (kIsWeb) {
      final b = await img.readAsBytes();
      setState(() => _webImage = b);
    } else {
      setState(() => _imageFile = File(img.path));
    }
  }

  Future<void> _pickFecha() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 30),
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
      final registroBody = {
        'nombre': _nombreCtrl.text.trim(),
        'apellidos': _apellidosCtrl.text.trim(),
        'telefono': _telefonoCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'password': _passwordCtrl.text,
      };
      if (_fechaNacimiento != null) {
        registroBody['fecha_nacimiento'] = _fechaNacimiento!.toIso8601String().split('T').first;
      }

      try {
        // 1. Crear propietario via registro
        final response = await ApiClient.post('/auth/registro/', registroBody, auth: false);
        final propData = response['propietario'] as Map<String, dynamic>;
        final newId = propData['id'] as int;

        // 2. Asignar rol admin + estado + folio_ine via PATCH (requiere auth de admin)
        await ApiClient.patch('/admin/propietarios/$newId/rol/', {'rol': _rol});
        if (_estado != 'activo' || _folioIneCtrl.text.trim().isNotEmpty) {
          final patchBody = <String, dynamic>{};
          if (_estado != 'activo') patchBody['estado'] = _estado;
          if (_folioIneCtrl.text.trim().isNotEmpty) {
            patchBody['folio_ine'] = _folioIneCtrl.text.trim().toUpperCase();
          }
          if (patchBody.isNotEmpty) {
            await ApiClient.patch('/propietarios/$newId/', patchBody);
          }
        }

        // 3. Rearmar el Admin con datos actualizados
        final nuevo = Admin(
          id: newId,
          nombre: _nombreCtrl.text.trim(),
          apellidos: _apellidosCtrl.text.trim(),
          fechaNacimiento: _fechaNacimiento,
          telefono: _telefonoCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          folioIne: _folioIneCtrl.text.trim().toUpperCase(),
          rol: _rol,
          estado: _estado,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        if (mounted) Navigator.pop(context, nuevo);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const AppHeader(title: 'Nuevo Administrador', showBack: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
        child: Form(
            key: _formKey,
            child: Column(children: [
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
              adminSectionTitle(Icons.lock_outline, 'Credenciales de Acceso'),
              const SizedBox(height: 14),
              _buildPasswordField(),
              const SizedBox(height: 24),
              adminSectionTitle(Icons.shield_outlined, 'Rol'),
              const SizedBox(height: 14),
              _buildSelector(
                  _rol,
                  ['admin', 'propietario'],
                  ['Admin', 'Propietario'],
                  [Icons.shield_outlined, Icons.home_outlined],
                  [const Color(0xFF225378), const Color(0xFF1695A3)],
                  (v) => setState(() => _rol = v)),
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
                    label: const Text('Registrar Administrador',
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
    final hasImg = _webImage != null || _imageFile != null;
    final inicial =
        _nombreCtrl.text.isNotEmpty ? _nombreCtrl.text[0].toUpperCase() : '?';
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
            child: hasImg
                ? ClipOval(
                    child: kIsWeb
                        ? Image.memory(_webImage!, fit: BoxFit.cover)
                        : Image.file(_imageFile!, fit: BoxFit.cover))
                : Center(
                    child: Text(inicial,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold))),
          )),
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

  Widget _buildPasswordField() => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            adminFieldLabel('Contraseña temporal'),
            const SizedBox(height: 6),
            TextFormField(
                controller: _passwordCtrl,
                obscureText: _obscure,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Requerido';
                  if (v.length < 8) return 'Mínimo 8 caracteres';
                  return null;
                },
                style:
                    const TextStyle(fontSize: 13, color: Color(0xFF225378)),
                decoration: InputDecoration(
                  hintText: 'Mínimo 8 caracteres',
                  hintStyle:
                      const TextStyle(color: Colors.grey, fontSize: 13),
                  prefixIcon: const Icon(Icons.lock_outline,
                      color: Color(0xFF1695A3), size: 18),
                  suffixIcon: IconButton(
                      icon: Icon(
                          _obscure
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: const Color(0xFF1695A3),
                          size: 18),
                      onPressed: () => setState(() => _obscure = !_obscure)),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 14, horizontal: 12),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: Color(0xFF225378), width: 2)),
                  errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.red)),
                  focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: Colors.red, width: 2)),
                )),
          ]);

  Widget _buildSelector(
          String current,
          List<String> values,
          List<String> labels,
          List<IconData> icons,
          List<Color> colors,
          ValueChanged<String> onSel) =>
      Row(
          children: List.generate(values.length, (i) {
        final sel = current == values[i];
        return Expanded(
            child: GestureDetector(
          onTap: () => onSel(values[i]),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: EdgeInsets.only(right: i < values.length - 1 ? 10 : 0),
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
                color: sel ? colors[i].withOpacity(0.1) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: sel ? colors[i] : Colors.grey.shade200,
                    width: sel ? 2 : 1)),
            child: Column(children: [
              Icon(icons[i], color: sel ? colors[i] : Colors.grey, size: 22),
              const SizedBox(height: 4),
              Text(labels[i],
                  style: TextStyle(
                      color: sel ? colors[i] : Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 12)),
            ]),
          ),
        ));
      }));

  Widget _buildEstadoSelector() {
    final estados = [
      {'value': 'activo', 'label': 'Activo', 'color': const Color(0xFF1695A3)},
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
                  fontSize: 12)),
        ),
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
