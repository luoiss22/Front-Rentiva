import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/bottom_navbar.dart';
import '../../../data/services/documentos_service.dart';

class DocumentosScreen extends StatefulWidget {
  const DocumentosScreen({super.key});

  @override
  State<DocumentosScreen> createState() => _DocumentosScreenState();
}

class _DocumentosScreenState extends State<DocumentosScreen> {
  final int _navIndex = 0;
  bool _cargando = true;
  List<DocumentoItem> _documentos = [];
  String? _filtroTipo;
  String _error = '';

  static const _tipos = <String, String>{
    'contrato_pdf':        'Contrato PDF',
    'ine':                 'INE',
    'comprobante_domicilio': 'Comp. Domicilio',
    'foto':                'Fotografía',
    'escritura':           'Escritura',
    'otro':                'Otro',
  };

  static const _tiposEntidad = <String, String>{
    'propietario':  'Propietario',
    'propiedad':    'Propiedad',
    'contrato':     'Contrato',
    'arrendatario': 'Arrendatario',
    'reporte':      'Reporte',
  };

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() { _cargando = true; _error = ''; });
    try {
      final lista = await DocumentosService.listar(tipoEntidad: _filtroTipo);
      if (!mounted) return;
      setState(() { _documentos = lista; _cargando = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _cargando = false; });
    }
  }

  IconData _iconTipo(String tipo) {
    switch (tipo) {
      case 'contrato_pdf':          return Icons.picture_as_pdf;
      case 'ine':                   return Icons.badge_outlined;
      case 'comprobante_domicilio': return Icons.location_on_outlined;
      case 'foto':                  return Icons.image_outlined;
      case 'escritura':             return Icons.article_outlined;
      default:                      return Icons.insert_drive_file_outlined;
    }
  }

  Future<void> _eliminarDocumento(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Eliminar documento',
            style: TextStyle(color: Color(0xFF225378), fontWeight: FontWeight.bold)),
        content: const Text('Esta acción no se puede deshacer.',
            style: TextStyle(color: Colors.grey, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Eliminar', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await DocumentosService.eliminar(id);
      _cargar();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'),
            backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
      );
    }
  }

  void _mostrarSubirDocumento() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _SubirDocumentoSheet(
        tipos: _tipos,
        tiposEntidad: _tiposEntidad,
        onSubido: () { Navigator.pop(context); _cargar(); },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const AppHeader(title: 'Documentos'),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF225378),
        onPressed: _mostrarSubirDocumento,
        icon: const Icon(Icons.upload_file_outlined, color: Colors.white),
        label: const Text('Subir', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _chipFiltro(null, 'Todos'),
                  ..._tipos.entries.map((e) => _chipFiltro(e.key, e.value)),
                ],
              ),
            ),
          ),
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF1695A3)))
                : _error.isNotEmpty
                    ? Center(child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline, size: 48, color: Colors.red),
                          const SizedBox(height: 12),
                          Text(_error, textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.grey, fontSize: 13)),
                          const SizedBox(height: 12),
                          ElevatedButton(onPressed: _cargar, child: const Text('Reintentar')),
                        ],
                      ))
                    : _documentos.isEmpty
                        ? Center(child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.folder_open_outlined, size: 52, color: Colors.grey),
                              const SizedBox(height: 12),
                              const Text('No hay documentos',
                                  style: TextStyle(color: Colors.grey, fontSize: 14)),
                              const SizedBox(height: 8),
                              TextButton.icon(
                                onPressed: _mostrarSubirDocumento,
                                icon: const Icon(Icons.upload_file_outlined,
                                    color: Color(0xFF1695A3)),
                                label: const Text('Subir el primero',
                                    style: TextStyle(color: Color(0xFF1695A3))),
                              ),
                            ],
                          ))
                        : RefreshIndicator(
                            onRefresh: _cargar,
                            color: const Color(0xFF1695A3),
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                              itemCount: _documentos.length,
                              itemBuilder: (_, i) => _docCard(_documentos[i]),
                            ),
                          ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: _navIndex, onTap: (i) {}),
    );
  }

  Widget _chipFiltro(String? valor, String label) {
    final selected = _filtroTipo == valor;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        selectedColor: const Color(0xFF1695A3).withOpacity(0.15),
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          color: selected ? const Color(0xFF1695A3) : Colors.grey.shade600,
        ),
        onSelected: (_) { setState(() => _filtroTipo = valor); _cargar(); },
      ),
    );
  }

  Widget _docCard(DocumentoItem doc) {
    final tipoLabel = _tipos[doc.tipoDocumento] ?? doc.tipoDocumento;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFACF0F2).withOpacity(0.4),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(_iconTipo(doc.tipoDocumento), color: const Color(0xFF1695A3), size: 22),
        ),
        title: Text(doc.nombreArchivo,
            style: const TextStyle(
                color: Color(0xFF225378), fontWeight: FontWeight.bold, fontSize: 13),
            overflow: TextOverflow.ellipsis),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(tipoLabel,
                style: const TextStyle(color: Color(0xFF1695A3), fontSize: 11)),
            Text('${doc.tipoEntidad} #${doc.entidadId}',
                style: const TextStyle(color: Colors.grey, fontSize: 10)),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
          onPressed: () => _eliminarDocumento(doc.id),
        ),
      ),
    );
  }
}

// ─── BOTTOM SHEET SUBIR DOCUMENTO ────────────────────────────────────────────
class _SubirDocumentoSheet extends StatefulWidget {
  final Map<String, String> tipos;
  final Map<String, String> tiposEntidad;
  final VoidCallback onSubido;

  const _SubirDocumentoSheet({
    required this.tipos,
    required this.tiposEntidad,
    required this.onSubido,
  });

  @override
  State<_SubirDocumentoSheet> createState() => _SubirDocumentoSheetState();
}

class _SubirDocumentoSheetState extends State<_SubirDocumentoSheet> {
  final _formKey = GlobalKey<FormState>();
  String _tipoEntidad   = 'propietario';
  String _tipoDocumento = 'otro';
  final _entidadIdCtrl    = TextEditingController();
  final _nombreCtrl       = TextEditingController();
  final _descripcionCtrl  = TextEditingController();
  File?  _archivoSeleccionado;
  String _nombreArchivo = '';
  bool   _subiendo = false;

  @override
  void dispose() {
    _entidadIdCtrl.dispose();
    _nombreCtrl.dispose();
    _descripcionCtrl.dispose();
    super.dispose();
  }

  Future<void> _seleccionarArchivo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx', 'xls', 'xlsx'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _archivoSeleccionado = File(result.files.single.path!);
        _nombreArchivo = result.files.single.name;
        // Pre-llenar nombre si está vacío
        if (_nombreCtrl.text.isEmpty) {
          _nombreCtrl.text = result.files.single.name
              .replaceAll(RegExp(r'\.[^.]+$'), ''); // sin extensión
        }
      });
    }
  }

  Future<void> _subir() async {
    if (!_formKey.currentState!.validate()) return;
    if (_archivoSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Selecciona un archivo primero'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    if (_entidadIdCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Ingresa el ID de la entidad'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    setState(() => _subiendo = true);
    try {
      await DocumentosService.subir(
        tipoEntidad:    _tipoEntidad,
        entidadId:      int.parse(_entidadIdCtrl.text),
        tipoDocumento:  _tipoDocumento,
        nombreArchivo:  _nombreCtrl.text.trim(),
        archivo:        _archivoSeleccionado!,
        descripcion:    _descripcionCtrl.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Documento subido correctamente'),
          backgroundColor: Color(0xFF1695A3),
          behavior: SnackBarBehavior.floating,
        ));
        widget.onSubido();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
        setState(() => _subiendo = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 32),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Subir Documento',
                  style: TextStyle(
                      color: Color(0xFF225378),
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
              const SizedBox(height: 16),

              // Selector de archivo
              GestureDetector(
                onTap: _seleccionarArchivo,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
                  decoration: BoxDecoration(
                    color: _archivoSeleccionado != null
                        ? const Color(0xFF1695A3).withOpacity(0.05)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _archivoSeleccionado != null
                          ? const Color(0xFF1695A3)
                          : Colors.grey.shade300,
                      width: _archivoSeleccionado != null ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _archivoSeleccionado != null
                            ? Icons.check_circle_outline
                            : Icons.upload_file_outlined,
                        color: _archivoSeleccionado != null
                            ? const Color(0xFF1695A3)
                            : Colors.grey,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _archivoSeleccionado != null
                              ? _nombreArchivo
                              : 'Toca para seleccionar archivo',
                          style: TextStyle(
                            color: _archivoSeleccionado != null
                                ? const Color(0xFF225378)
                                : Colors.grey,
                            fontWeight: _archivoSeleccionado != null
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text('PDF, JPG, PNG, DOC...',
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 10)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Nombre del documento
              TextFormField(
                controller: _nombreCtrl,
                decoration: _inputDeco('Nombre del documento', Icons.label_outline),
                validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                style: const TextStyle(fontSize: 13, color: Color(0xFF225378)),
              ),
              const SizedBox(height: 12),

              // Tipo de documento
              DropdownButtonFormField<String>(
                initialValue: _tipoDocumento,
                decoration: _inputDeco('Tipo de documento', Icons.category_outlined),
                items: widget.tipos.entries
                    .map((e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value, style: const TextStyle(fontSize: 13)),
                        ))
                    .toList(),
                onChanged: (v) { if (v != null) setState(() => _tipoDocumento = v); },
              ),
              const SizedBox(height: 12),

              // Tipo de entidad + ID
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<String>(
                      initialValue: _tipoEntidad,
                      decoration: _inputDeco('Pertenece a', Icons.link_outlined),
                      items: widget.tiposEntidad.entries
                          .map((e) => DropdownMenuItem(
                                value: e.key,
                                child: Text(e.value, style: const TextStyle(fontSize: 12)),
                              ))
                          .toList(),
                      onChanged: (v) { if (v != null) setState(() => _tipoEntidad = v); },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _entidadIdCtrl,
                      keyboardType: TextInputType.number,
                      decoration: _inputDeco('ID', Icons.tag),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Req.';
                        if (int.tryParse(v) == null) return 'Número';
                        return null;
                      },
                      style: const TextStyle(fontSize: 13, color: Color(0xFF225378)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Descripción (opcional)
              TextFormField(
                controller: _descripcionCtrl,
                maxLines: 2,
                decoration: _inputDeco('Descripción (opcional)', Icons.notes_outlined),
                style: const TextStyle(fontSize: 13, color: Color(0xFF225378)),
              ),
              const SizedBox(height: 20),

              // Botón subir
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _subiendo ? null : _subir,
                  icon: _subiendo
                      ? const SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.cloud_upload_outlined, size: 20),
                  label: Text(_subiendo ? 'Subiendo...' : 'Subir Documento',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF225378),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
