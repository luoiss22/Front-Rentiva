import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../core/services/api_client.dart';
import '../../../core/widgets/app_header.dart';

// ─── PANTALLA ─────────────────────────────────────────────────────────────────
class NuevaPropiedadScreen extends StatefulWidget {
  const NuevaPropiedadScreen({super.key});

  @override
  State<NuevaPropiedadScreen> createState() => _NuevaPropiedadScreenState();
}

class _NuevaPropiedadScreenState extends State<NuevaPropiedadScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  // Imagen
  File? _imageFile;
  Uint8List? _webImage;

  // Controladores — corresponden a campos Django
  final _nombreCtrl        = TextEditingController();
  final _direccionCtrl     = TextEditingController();
  final _ciudadCtrl        = TextEditingController();
  final _estadoGeoCtrl     = TextEditingController();
  final _cpCtrl            = TextEditingController();
  final _costoRentaCtrl    = TextEditingController();
  final _superficieCtrl    = TextEditingController();
  final _descripcionCtrl   = TextEditingController();

  // Dropdowns
  String _tipo   = 'departamento';
  String _estado = 'disponible';

  final List<Map<String, String>> _tiposOpciones = [
    {'value': 'casa',         'label': 'Casa'},
    {'value': 'departamento', 'label': 'Departamento'},
    {'value': 'local',        'label': 'Local'},
    {'value': 'oficina',      'label': 'Oficina'},
    {'value': 'terreno',      'label': 'Terreno'},
    {'value': 'otro',         'label': 'Otro'},
  ];

  final List<Map<String, String>> _estadosOpciones = [
    {'value': 'disponible',    'label': 'Disponible'},
    {'value': 'rentada',       'label': 'Rentada'},
    {'value': 'mantenimiento', 'label': 'Mantenimiento'},
    {'value': 'inactiva',      'label': 'Inactiva'},
  ];

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _direccionCtrl.dispose();
    _ciudadCtrl.dispose();
    _estadoGeoCtrl.dispose();
    _cpCtrl.dispose();
    _costoRentaCtrl.dispose();
    _superficieCtrl.dispose();
    _descripcionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery, imageQuality: 80);
    if (image == null) return;
    if (kIsWeb) {
      final bytes = await image.readAsBytes();
      setState(() => _webImage = bytes);
    } else {
      setState(() => _imageFile = File(image.path));
    }
  }

  bool _isLoading = false;

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final body = <String, String>{
        'nombre':            _nombreCtrl.text.trim(),
        'direccion':         _direccionCtrl.text.trim(),
        'ciudad':            _ciudadCtrl.text.trim(),
        'estado_geografico': _estadoGeoCtrl.text.trim(),
        'codigo_postal':     _cpCtrl.text.trim(),
        'tipo':              _tipo,
        'costo_renta':       _costoRentaCtrl.text.trim(),
        'descripcion':       _descripcionCtrl.text.trim(),
        'estado':            _estado,
        if (_superficieCtrl.text.isNotEmpty)
          'superficie_m2': _superficieCtrl.text.trim(),
      };

      if (_imageFile != null || _webImage != null) {
        await ApiClient.multipart(
          'POST',
          '/propiedades/',
          fields: body,
          file: _imageFile,
          fileField: 'imagen',
        );
      } else {
        await ApiClient.post('/propiedades/', body);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Propiedad guardada exitosamente'),
          backgroundColor: Color(0xFF1695A3),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo conectar al servidor'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const AppHeader(title: 'Nueva Propiedad', showBack: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Foto de la propiedad ────────────────────────────────────
              _buildImagePicker(),
              const SizedBox(height: 24),

              // ── Sección: Información General ────────────────────────────
              _sectionTitle('Información General'),
              const SizedBox(height: 12),

              // Nombre
              _buildField(
                label: 'Nombre de la Propiedad',
                controller: _nombreCtrl,
                hint: 'Ej. Depto Centro Reforma',
                icon: Icons.home_outlined,
                maxLength: 200,
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),

              // Tipo y Estado en fila
              Row(
                children: [
                  Expanded(
                    child: _buildDropdown(
                      label: 'Tipo',
                      value: _tipo,
                      opciones: _tiposOpciones,
                      icon: Icons.category_outlined,
                      onChanged: (v) => setState(() => _tipo = v!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDropdown(
                      label: 'Estado',
                      value: _estado,
                      opciones: _estadosOpciones,
                      icon: Icons.toggle_on_outlined,
                      onChanged: (v) => setState(() => _estado = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Sección: Ubicación ──────────────────────────────────────
              _sectionTitle('Ubicación'),
              const SizedBox(height: 12),

              // Dirección
              _buildField(
                label: 'Dirección',
                controller: _direccionCtrl,
                hint: 'Calle, número, colonia',
                icon: Icons.location_on_outlined,
                maxLines: 2,
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),

              // Ciudad y Estado geográfico
              Row(
                children: [
                  Expanded(
                    child: _buildField(
                      label: 'Ciudad',
                      controller: _ciudadCtrl,
                      hint: 'Ciudad de México',
                      icon: Icons.location_city_outlined,
                      maxLength: 120,
                      validator: (v) => v!.isEmpty ? 'Requerido' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildField(
                      label: 'Estado',
                      controller: _estadoGeoCtrl,
                      hint: 'CDMX',
                      icon: Icons.map_outlined,
                      maxLength: 120,
                      validator: (v) => v!.isEmpty ? 'Requerido' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Código postal
              _buildField(
                label: 'Código Postal',
                controller: _cpCtrl,
                hint: '06600',
                icon: Icons.markunread_mailbox_outlined,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(5),
                ],
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Requerido';
                  if (v.length != 5) return 'Debe tener 5 dígitos';
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // ── Sección: Datos Económicos ───────────────────────────────
              _sectionTitle('Datos Económicos'),
              const SizedBox(height: 12),

              Row(
                children: [
                  // Costo de renta
                  Expanded(
                    child: _buildField(
                      label: 'Costo de Renta',
                      controller: _costoRentaCtrl,
                      hint: '12500.00',
                      icon: Icons.attach_money,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Requerido';
                        if (double.tryParse(v) == null) return 'Inválido';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Superficie m2 (opcional)
                  Expanded(
                    child: _buildField(
                      label: 'Superficie m² (opcional)',
                      controller: _superficieCtrl,
                      hint: '85.00',
                      icon: Icons.straighten,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Sección: Descripción ────────────────────────────────────
              _sectionTitle('Descripción'),
              const SizedBox(height: 12),

              _buildField(
                label: 'Descripción detallada',
                controller: _descripcionCtrl,
                hint: 'Describe las características principales de la propiedad...',
                icon: Icons.notes_outlined,
                maxLines: 4,
              ),
              const SizedBox(height: 32),

              // ── Botón guardar ───────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _onSubmit,
                  icon: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save_outlined, size: 20),
                  label: const Text(
                    'Guardar Propiedad',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
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

  // ── IMAGEN PICKER ────────────────────────────────────────────────────────────
  Widget _buildImagePicker() {
    final hasImage = _webImage != null || _imageFile != null;
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: double.infinity,
        height: 180,
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF1695A3),
            width: 1.5,
            style: BorderStyle.solid,
          ),
        ),
        child: hasImage
            ? ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: kIsWeb
                    ? Image.memory(_webImage!, fit: BoxFit.cover,
                        width: double.infinity)
                    : Image.file(_imageFile!, fit: BoxFit.cover,
                        width: double.infinity),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.camera_alt_outlined,
                      size: 44, color: Color(0xFF1695A3)),
                  SizedBox(height: 8),
                  Text(
                    'Toca para subir foto',
                    style: TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                        fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'JPG, PNG hasta 5MB',
                    style: TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                ],
              ),
      ),
    );
  }

  // ── SECTION TITLE ────────────────────────────────────────────────────────────
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
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF225378),
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  // ── TEXT FIELD ───────────────────────────────────────────────────────────────
  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    int maxLines = 1,
    int? maxLength,
    bool readOnly = false,
    VoidCallback? onTap,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(0xFF225378),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          maxLines: maxLines,
          maxLength: maxLength,
          readOnly: readOnly,
          onTap: onTap,
          inputFormatters: inputFormatters,
          style: const TextStyle(fontSize: 13, color: Color(0xFF225378)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
            prefixIcon: Icon(icon, color: const Color(0xFF1695A3), size: 18),
            counterText: '',
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
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  // ── DROPDOWN ─────────────────────────────────────────────────────────────────
  Widget _buildDropdown({
    required String label,
    required String value,
    required List<Map<String, String>> opciones,
    required IconData icon,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(0xFF225378),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down,
                  color: Color(0xFF1695A3), size: 20),
              style: const TextStyle(
                  fontSize: 13, color: Color(0xFF225378)),
              onChanged: onChanged,
              items: opciones
                  .map((o) => DropdownMenuItem(
                        value: o['value'],
                        child: Row(
                          children: [
                            Icon(icon,
                                color: const Color(0xFF1695A3), size: 16),
                            const SizedBox(width: 8),
                            Text(o['label']!),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }
}