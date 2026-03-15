import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../core/widgets/app_header.dart';
import '../../../data/services/mobiliario_service.dart';

// ─── PANTALLA ─────────────────────────────────────────────────────────────────
class EditarMobiliarioScreen extends StatefulWidget {
  final int? propiedadMobiliarioId; // ID de PropiedadMobiliario
  final int? propiedadId;
  final String? propiedadNombre;

  const EditarMobiliarioScreen({
    super.key,
    this.propiedadMobiliarioId,
    this.propiedadId,
    this.propiedadNombre,
  });

  @override
  State<EditarMobiliarioScreen> createState() =>
      _EditarMobiliarioScreenState();
}

class _EditarMobiliarioScreenState extends State<EditarMobiliarioScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  // Imagen
  File? _imageFile;
  Uint8List? _webImage;

  // Controladores
  late TextEditingController _nombreCtrl;
  late TextEditingController _tipoCtrl;
  late TextEditingController _descripcionCtrl;
  late TextEditingController _cantidadCtrl;
  late TextEditingController _valorEstimadoCtrl;

  String? _estadoSeleccionado;
  bool _cargando = true;

  static const List<Map<String, dynamic>> _estados = [
    {'value': 'bueno',      'label': 'Bueno',         'color': Color(0xFF1695A3)},
    {'value': 'regular',    'label': 'Regular',        'color': Color(0xFFEB7F00)},
    {'value': 'malo',       'label': 'Malo',           'color': Colors.red},
    {'value': 'reparacion', 'label': 'En Reparación',  'color': Colors.orange},
  ];

  @override
  void initState() {
    super.initState();
    _nombreCtrl        = TextEditingController();
    _tipoCtrl          = TextEditingController();
    _descripcionCtrl   = TextEditingController();
    _cantidadCtrl      = TextEditingController();
    _valorEstimadoCtrl = TextEditingController();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      final pm = await PropiedadMobiliarioService.detalle(
        widget.propiedadMobiliarioId!,
      );
      final mob = await MobiliarioService.detalle(pm.mobiliario);
      if (!mounted) return;
      setState(() {
        _nombreCtrl.text       = mob.nombre;
        _tipoCtrl.text         = mob.tipo;
        _descripcionCtrl.text  = mob.descripcion ?? '';
        _cantidadCtrl.text     = pm.cantidad.toString();
        _valorEstimadoCtrl.text =
            pm.valorEstimado?.toString() ?? '';
        _estadoSeleccionado    = pm.estado;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _cargando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

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
      setState(() { _webImage = bytes; });
    } else {
      setState(() { _imageFile = File(image.path); });
    }
  }

  void _onSubmit() async {
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

      try {
        // Actualizar la relación propiedad-mobiliario
        await PropiedadMobiliarioService.actualizar(
          widget.propiedadMobiliarioId!,
          {
            'cantidad':       int.tryParse(_cantidadCtrl.text) ?? 1,
            'valor_estimado': _valorEstimadoCtrl.text.isEmpty
                ? null
                : _valorEstimadoCtrl.text,
            'estado':         _estadoSeleccionado,
          },
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mobiliario actualizado correctamente'),
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
  }

  void _onDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Eliminar artículo',
            style: TextStyle(
                color: Color(0xFF225378), fontWeight: FontWeight.bold)),
        content: Text(
          '¿Estás seguro de eliminar "${_nombreCtrl.text}"?\nEsta acción no se puede deshacer.',
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
                await PropiedadMobiliarioService.eliminar(
                  widget.propiedadMobiliarioId!,
                );
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Artículo eliminado'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                Navigator.pop(context, true);
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error al eliminar: $e'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const AppHeader(title: 'Editar Mobiliario', showBack: true),
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1695A3)))
          : SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Banner propiedad + botón eliminar ─────────────────────────
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Editando artículo de:',
                              style: TextStyle(
                                  color: Colors.grey, fontSize: 11)),
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
                    ),
                    // Botón eliminar
                    GestureDetector(
                      onTap: _onDelete,
                      child: Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.delete_outline,
                            color: Colors.red.shade400, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Sección: Datos del artículo (Mobiliario) ─────────────────
              _sectionTitle('Datos del Artículo'),
              const SizedBox(height: 12),

              // Foto
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
                hint: 'Marca, modelo, número de serie...',
                icon: Icons.notes_outlined,
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // ── Sección: Asignación (PropiedadMobiliario) ─────────────────
              _sectionTitle('Asignación a la Propiedad'),
              const SizedBox(height: 12),

              Row(
                children: [
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
                        if ((int.tryParse(v) ?? 0) < 1) return 'Mín. 1';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
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

              // Estado
              _buildEstadoSelector(),
              const SizedBox(height: 32),

              // ── Botón actualizar ──────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _onSubmit,
                  icon: const Icon(Icons.save_outlined, size: 20),
                  label: const Text(
                    'Actualizar Mobiliario',
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

  // ── SELECTOR DE ESTADO ────────────────────────────────────────────────────
  Widget _buildEstadoSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Estado del artículo',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF225378))),
        const SizedBox(height: 8),
        Row(
          children: _estados.map((estado) {
            final isSelected = _estadoSeleccionado == estado['value'];
            final color = estado['color'] as Color;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(
                    () => _estadoSeleccionado = estado['value'] as String),
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
                          color:
                              isSelected ? color : Colors.grey.shade300,
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

  // ── IMAGE PICKER ──────────────────────────────────────────────────────────
  Widget _buildImagePicker() {
    final hasNewImage = _webImage != null || _imageFile != null;

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
              style: BorderStyle.solid),
        ),
        child: hasNewImage
            ? ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: kIsWeb
                    ? Image.memory(_webImage!, fit: BoxFit.cover,
                        width: double.infinity)
                    : Image.file(_imageFile!, fit: BoxFit.cover,
                        width: double.infinity),
              )
            : _imagePlaceholder(),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.camera_alt_outlined,
            size: 36, color: Color(0xFF1695A3)),
        SizedBox(height: 6),
        Text('Toca para cambiar foto',
            style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.w500)),
      ],
    );
  }

  // ── SECTION TITLE ─────────────────────────────────────────────────────────
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

  // ── TEXT FIELD ────────────────────────────────────────────────────────────
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
            contentPadding: const EdgeInsets.symmetric(
                vertical: 14, horizontal: 12),
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