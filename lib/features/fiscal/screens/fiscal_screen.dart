import 'package:flutter/material.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/bottom_navbar.dart';
import '../../../data/services/fiscal_service.dart';

class FiscalScreen extends StatefulWidget {
  const FiscalScreen({super.key});

  @override
  State<FiscalScreen> createState() => _FiscalScreenState();
}

class _FiscalScreenState extends State<FiscalScreen> {
  final int _navIndex = 0;
  bool _cargando = true;
  List<DatosFiscalesItem> _datos = [];
  String _error = '';

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() { _cargando = true; _error = ''; });
    try {
      final lista = await DatosFiscalesService.listar();
      if (!mounted) return;
      setState(() { _datos = lista; _cargando = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _cargando = false; });
    }
  }

  Future<void> _eliminar(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Eliminar datos fiscales',
            style: TextStyle(
                color: Color(0xFF225378),
                fontWeight: FontWeight.bold)),
        content: const Text(
            'Esta acción no se puede deshacer.',
            style: TextStyle(color: Colors.grey, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar',
                style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Eliminar',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await DatosFiscalesService.eliminar(id);
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
      appBar: const AppHeader(title: 'Datos Fiscales'),
      body: _cargando
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
              : _datos.isEmpty
                  ? const Center(child: Text(
                      'No hay datos fiscales registrados',
                      style: TextStyle(
                          color: Colors.grey, fontSize: 14)))
                  : RefreshIndicator(
                      onRefresh: _cargar,
                      color: const Color(0xFF1695A3),
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(
                            16, 16, 16, 100),
                        itemCount: _datos.length,
                        itemBuilder: (_, i) =>
                            _fiscalCard(_datos[i]),
                      ),
                    ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _navIndex,
        onTap: (i) {},
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF225378),
        onPressed: () async {
          final result = await Navigator.pushNamed(
              context, '/fiscal/nuevo');
          if (result == true) _cargar();
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _fiscalCard(DatosFiscalesItem item) {
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
            horizontal: 14, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFACF0F2).withOpacity(0.4),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.receipt_long_outlined,
              color: Color(0xFF1695A3), size: 22),
        ),
        title: Text(
          item.rfc,
          style: const TextStyle(
            color: Color(0xFF225378),
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(item.nombreORazonSocial,
                style: const TextStyle(
                    color: Colors.grey, fontSize: 12)),
            Text('${item.tipoEntidad} #${item.entidadId}',
                style: const TextStyle(
                    color: Colors.grey, fontSize: 10)),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline,
              color: Colors.red, size: 20),
          onPressed: () => _eliminar(item.id),
        ),
        onTap: () async {
          final result = await Navigator.pushNamed(
            context, '/fiscal/detalle',
            arguments: item.id,
          );
          if (result == true) _cargar();
        },
      ),
    );
  }
}
