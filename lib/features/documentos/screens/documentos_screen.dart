import 'package:flutter/material.dart';
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
    'contrato_pdf': 'Contrato PDF',
    'ine': 'INE',
    'comprobante_domicilio': 'Comp. Domicilio',
    'foto': 'Fotografía',
    'escritura': 'Escritura',
    'otro': 'Otro',
  };

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() { _cargando = true; _error = ''; });
    try {
      final lista = await DocumentosService.listar(
        tipoEntidad: _filtroTipo,
      );
      if (!mounted) return;
      setState(() { _documentos = lista; _cargando = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _cargando = false; });
    }
  }

  IconData _iconTipo(String tipo) {
    switch (tipo) {
      case 'contrato_pdf': return Icons.picture_as_pdf;
      case 'ine':          return Icons.badge_outlined;
      case 'comprobante_domicilio': return Icons.location_on_outlined;
      case 'foto':         return Icons.image_outlined;
      case 'escritura':    return Icons.article_outlined;
      default:             return Icons.insert_drive_file_outlined;
    }
  }

  Future<void> _eliminarDocumento(int id) async {
    try {
      await DocumentosService.eliminar(id);
      _cargar();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const AppHeader(title: 'Documentos'),
      body: Column(
        children: [
          // Filtros
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _chipFiltro(null, 'Todos'),
                  ..._tipos.entries.map(
                    (e) => _chipFiltro(e.key, e.value),
                  ),
                ],
              ),
            ),
          ),

          // Contenido
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator(
                    color: Color(0xFF1695A3)))
                : _error.isNotEmpty
                    ? Center(child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline,
                              size: 48, color: Colors.red),
                          const SizedBox(height: 12),
                          Text(_error, textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 13)),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _cargar,
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ))
                    : _documentos.isEmpty
                        ? const Center(child: Text(
                            'No hay documentos',
                            style: TextStyle(
                                color: Colors.grey, fontSize: 14)))
                        : RefreshIndicator(
                            onRefresh: _cargar,
                            color: const Color(0xFF1695A3),
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(
                                  16, 8, 16, 100),
                              itemCount: _documentos.length,
                              itemBuilder: (_, i) =>
                                  _docCard(_documentos[i]),
                            ),
                          ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _navIndex,
        onTap: (i) {},
      ),
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
          color: selected
              ? const Color(0xFF1695A3)
              : Colors.grey.shade600,
        ),
        onSelected: (_) {
          setState(() => _filtroTipo = valor);
          _cargar();
        },
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
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFACF0F2).withOpacity(0.4),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(_iconTipo(doc.tipoDocumento),
              color: const Color(0xFF1695A3), size: 22),
        ),
        title: Text(
          doc.nombreArchivo,
          style: const TextStyle(
            color: Color(0xFF225378),
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(tipoLabel,
                style: const TextStyle(
                    color: Color(0xFF1695A3), fontSize: 11)),
            Text('${doc.tipoEntidad} #${doc.entidadId}',
                style: const TextStyle(
                    color: Colors.grey, fontSize: 10)),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline,
              color: Colors.red, size: 20),
          onPressed: () => _eliminarDocumento(doc.id),
        ),
      ),
    );
  }
}
