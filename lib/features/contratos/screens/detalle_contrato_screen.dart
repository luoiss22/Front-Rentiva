import 'package:flutter/material.dart';
import '../../../core/widgets/app_header.dart';
import '../../../data/services/contratos_service.dart';

class DetalleContratoScreen extends StatefulWidget {
  final int? contratoId;
  const DetalleContratoScreen({super.key, this.contratoId});

  @override
  State<DetalleContratoScreen> createState() => _DetalleContratoScreenState();
}

class _DetalleContratoScreenState extends State<DetalleContratoScreen> {
  bool _cargando = true;
  Map<String, dynamic>? _contrato;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final data = await ContratosService.detalle(widget.contratoId!);
      if (!mounted) return;
      setState(() { _contrato = data; _cargando = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _cargando = false; });
    }
  }

  Future<void> _eliminar() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Eliminar contrato',
            style: TextStyle(
                color: Color(0xFF225378),
                fontWeight: FontWeight.bold)),
        content: const Text(
          'Esta acción no se puede deshacer.',
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
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
      await ContratosService.eliminar(widget.contratoId!);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<void> _cancelarContrato() async {
    final estadoActual = (_contrato?['estado'] ?? '').toString();
    if (estadoActual == 'cancelado' || estadoActual == 'finalizado') {
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancelar contrato',
            style: TextStyle(
                color: Color(0xFF225378),
                fontWeight: FontWeight.bold)),
        content: const Text(
          'El contrato se marcará como cancelado y la propiedad quedará disponible si no hay otro contrato activo.',
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEB7F00),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Sí, cancelar',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final actualizado = await ContratosService.actualizar(
        widget.contratoId!,
        {'estado': 'cancelado'},
      );
      if (!mounted) return;
      setState(() {
        _contrato = actualizado;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contrato cancelado correctamente'),
          backgroundColor: Color(0xFF1695A3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating),
      );
    }
  }

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'activo':    return const Color(0xFF1695A3);
      case 'finalizado': return Colors.blueGrey;
      case 'renovado':   return const Color(0xFF225378);
      case 'vencido':   return Colors.red;
      case 'cancelado': return Colors.grey;
      default:          return const Color(0xFFEB7F00);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const AppHeader(title: 'Detalle Contrato', showBack: true),
      body: _cargando
          ? const Center(
              child: CircularProgressIndicator(
                  color: Color(0xFF1695A3)))
          : _error.isNotEmpty
              ? Center(child: Text(_error,
                  style: const TextStyle(color: Colors.red)))
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final c = _contrato!;
    final estado = c['estado'] ?? 'borrador';
    final color = _colorEstado(estado);
    final observaciones = (c['observaciones'] ?? c['notas'] ?? '').toString();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Estado badge
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                estado.toUpperCase(),
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Info card
          _infoCard([
            _row(Icons.home_outlined, 'Propiedad',
                c['propiedad_nombre'] ?? 'ID ${c['propiedad']}'),
            _row(Icons.person_outline, 'Arrendatario',
                c['arrendatario_nombre'] ?? 'ID ${c['arrendatario']}'),
            _row(Icons.calendar_today, 'Inicio',
                c['fecha_inicio'] ?? ''),
            _row(Icons.event, 'Fin',
                c['fecha_fin'] ?? ''),
            _row(Icons.attach_money, 'Renta acordada',
                '\$${c['renta_acordada'] ?? 0}'),
            _row(Icons.repeat, 'Periodo',
                c['periodo_pago'] ?? ''),
          ]),
          const SizedBox(height: 16),

          // Deposito y observaciones si existen
          if (c['deposito'] != null)
            _infoCard([
              _row(Icons.savings_outlined, 'Depósito',
                  '\$${c['deposito']}'),
            ]),
          if (observaciones.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: _infoCard([
                _row(Icons.notes_outlined, 'Notas',
                    observaciones),
              ]),
            ),
          const SizedBox(height: 32),

          // Botones de acción
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: (estado == 'cancelado' || estado == 'finalizado')
                      ? null
                      : _cancelarContrato,
                  icon: const Icon(Icons.block_outlined, size: 18),
                  label: const Text('Cancelar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEB7F00),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Eliminar
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _eliminar,
                  icon: const Icon(Icons.delete_outline,
                      color: Colors.red, size: 18),
                  label: const Text('Eliminar',
                      style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────
  Widget _infoCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF1695A3)),
          const SizedBox(width: 8),
          SizedBox(
            width: 90,
            child: Text(label,
                style: const TextStyle(
                    color: Colors.grey, fontSize: 12)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    color: Color(0xFF225378),
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
