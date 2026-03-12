import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../core/widgets/app_header.dart';

class NuevoMobiliarioScreen extends StatefulWidget {
  final int? propiedadId;
  final String? propiedadNombre;

  const NuevoMobiliarioScreen({
    super.key,
    this.propiedadId,
    this.propiedadNombre,
  });

  @override
  State<NuevoMobiliarioScreen> createState() => _NuevoMobiliarioScreenState();
}

class _NuevoMobiliarioScreenState extends State<NuevoMobiliarioScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  // Imagen (foto del mobiliario)
  File? _imageFile;
  Uint8List? _webImage;

  // ── Controladores — Modelo Mobiliario ──────────────────────────────────────
  final _nombreCtrl      = TextEditingController();
  final _tipoCtrl        = TextEditingController();
  final _descripcionCtrl = TextEditingController();

  // ── Controladores — Modelo PropiedadMobiliario ────────────────────────────
  final _cantidadCtrl      = TextEditingController(text: '1');
  final _valorEstimadoCtrl = TextEditingController();

  // Estado (enum Django: bueno|regular|malo|reparacion)
  String? _estadoSeleccionado;

  static const List<Map<String, dynamic>> _estados = [
    {'value': 'bueno',      'label': 'Bueno',         'color': Color(0xFF1695A3)},
    {'value': 'regular',    'label': 'Regular',        'color': Color(0xFFEB7F00)},
    {'value': 'malo',       'label': 'Malo',           'color': Colors.red},
    {'value': 'reparacion', 'label': 'En Reparación',  'color': Colors.orange},
  ];

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _tipoCtrl.dispose();
    _descripcionCtrl.dispose();
    _cantidadCtrl.dispose();
    _valorEstimadoCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image == null) return;
    if (kIsWeb) {
      final bytes = await image.readAsBytes();
      setState(() => _webImage = bytes);
    } else {
      setState(() => _imageFile = File(image.path));
    }
  }

  void _onSubmit() {
    if (_formKey.currentState!.validate()) {
      if (_estadoSeleccionado == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Selecciona el estado del artículo'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      // TODO: POST /api/mobiliario/  y  POST /api/propiedades/{id}/mobiliario/
      final mobiliarioData = {
        'nombre':      _nombreCtrl.text,
        'tipo':        _tipoCtrl.text,
        'descripcion': _descripcionCtrl.text,
        // foto: _imageFile / _webImage
      };
      final propiedadMobiliarioData = {
        'propiedad':       widget.propiedadId,
        'cantidad':        _cantidadCtrl.text,
        'valor_estimado':  _valorEstimadoCtrl.text,
        'estado':          _estadoSeleccionado,
      };
      debugPrint('Mobiliario: $mobiliarioData');
      debugPrint('PropiedadMobiliario: $propiedadMobiliarioData');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mobiliario agregado correctamente'),
          backgroundColor: Color(0xFF1695A3),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const AppHeader(title: 'Nuevo Mobiliario', showBack: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Banner propiedad ──────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFACF0F2)),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 6),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFACF0F2).withOpacity(0.4),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.home_outlined,
                          color: Color(0xFF1695A3), size: 18),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Agregando mobiliario a:',
                            style:
                                TextStyle(color: Colors.grey, fontSize: 11)),
                        Text(
                          widget.propiedadNombre ??
                              'Propiedad #${widget.propiedadId ?? '-'}',
                          style: const TextStyle(
                              color: Color(0xFF225378),
                              fontWeight: FontWeight.bold,
                              fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Sección: Datos del artículo (Mobiliario) ─────────────────
              _sectionTitle('Datos del Artículo'),
              const SizedBox(height: 12),

              // Foto del artículo
              _buildImagePicker(),
              const SizedBox(height: 12),

              // Nombre
              _buildField(
                label: 'Nombre del artículo',
                controller: _nombreCtrl,
                hint: 'Ej. Sofá cama, Refrigerador Samsung...',
                icon: Icons.inventory_2_outlined,
                maxLength: 200,
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),

              // Tipo
              _buildField(
                label: 'Tipo / Categoría',
                controller: _tipoCtrl,
                hint: 'Ej. Mueble, Electrodoméstico, Electrónico...',
                icon: Icons.category_outlined,
                maxLength: 100,
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),

              // Descripción
              _buildField(
                label: 'Descripción',
                controller: _descripcionCtrl,
                hint: 'Marca, modelo, número de serie, características...',
                icon: Icons.notes_outlined,
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // ── Sección: Asignación a propiedad (PropiedadMobiliario) ─────
              _sectionTitle('Asignación a la Propiedad'),
              const SizedBox(height: 12),

              Row(
                children: [
                  // Cantidad
                  Expanded(
                    child: _buildField(
                      label: 'Cantidad',
                      controller: _cantidadCtrl,
                      hint: '1',
                      icon: Icons.tag,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(3),
                      ],
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Requerido';
                        final n = int.tryParse(v);
                        if (n == null || n < 1) return 'Mín. 1';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Valor estimado (opcional)
                  Expanded(
                    child: _buildField(
                      label: 'Valor estimado (opcional)',
                      controller: _valorEstimadoCtrl,
                      hint: '0.00',
                      icon: Icons.attach_money,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Estado (radio buttons)
              _buildEstadoSelector(),
              const SizedBox(height: 32),

              // ── Botón guardar ─────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _onSubmit,
                  icon: const Icon(Icons.save_outlined, size: 20),
                  label: const Text(
                    'Guardar Mobiliario',
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

  // ── SELECTOR DE ESTADO ───────────────────────────────────────────────────────
  Widget _buildEstadoSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Estado del artículo',
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF225378)),
        ),
        const SizedBox(height: 8),
        Row(
          children: _estados.map((estado) {
            final isSelected = _estadoSeleccionado == estado['value'];
            final color = estado['color'] as Color;
            return Expanded(
              child: GestureDetector(
                onTap: () =>
                    setState(() => _estadoSeleccionado = estado['value']),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? color.withOpacity(0.12)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? color : Colors.grey.shade200,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: isSelected ? color : Colors.grey.shade300,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        estado['label'] as String,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected ? color : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── IMAGE PICKER ─────────────────────────────────────────────────────────────
  Widget _buildImagePicker() {
    final hasImage = _webImage != null || _imageFile != null;
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: double.infinity,
        height: 130,
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFF1695A3),
            width: 1.5,
            style: BorderStyle.solid,
          ),
        ),
        child: hasImage
            ? ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: kIsWeb
                    ? Image.memory(_webImage!, fit: BoxFit.cover,
                        width: double.infinity)
                    : Image.file(_imageFile!, fit: BoxFit.cover,
                        width: double.infinity),
              )
            : const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt_outlined,
                      size: 36, color: Color(0xFF1695A3)),
                  SizedBox(height: 6),
                  Text('Foto del artículo (opcional)',
                      style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                          fontWeight: FontWeight.w500)),
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
        Text(title,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF225378),
                letterSpacing: 0.3)),
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
    List<TextInputFormatter>? inputFormatters,
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
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          maxLines: maxLines,
          maxLength: maxLength,
          inputFormatters: inputFormatters,
          style: const TextStyle(fontSize: 13, color: Color(0xFF225378)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
            prefixIcon:
                Icon(icon, color: const Color(0xFF1695A3), size: 18),
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
}