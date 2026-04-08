import 'package:flutter/material.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/bottom_navbar.dart';
import '../../../data/services/contratos_service.dart';

class ContratosScreen extends StatefulWidget {
  const ContratosScreen({super.key});

  @override
  State<ContratosScreen> createState() => _ContratosScreenState();
}

class _ContratosScreenState extends State<ContratosScreen> {
  final int _navIndex = 0;
  bool _cargando = true;
  List<ContratoItem> _contratos = [];
  String? _filtroEstado;
  String _error = '';

  void _onNavTap(int index) {
    const routes = [
      '/inicio-usuario', '/propiedades', '/inquilinos', '/pagos', '/mantenimiento',
    ];
    if (index != _navIndex) Navigator.pushNamed(context, routes[index]);
  }

  static const _estados = <String, String>{
    'borrador': 'Borrador',
    'activo': 'Activo',
    'finalizado': 'Finalizado',
    'cancelado': 'Cancelado',
    'renovado': 'Renovado',
  };

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() { _cargando = true; _error = ''; });
    try {
      final lista = await ContratosService.listar(
        estado: _filtroEstado,
      );
      if (!mounted) return;
      setState(() { _contratos = lista; _cargando = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _cargando = false; });
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
      appBar: const AppHeader(title: 'Contratos'),
      body: Column(
        children: [
          // ── Filtros ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _chipFiltro(null, 'Todos'),
                  ..._estados.entries.map(
                    (e) => _chipFiltro(e.key, e.value),
                  ),
                ],
              ),
            ),
          ),

          // ── Contenido ────────────────────────────────
          Expanded(
            child: _cargando
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF1695A3),
                    ),
                  )
                : _error.isNotEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline,
                                size: 48, color: Colors.red),
                            const SizedBox(height: 12),
                            Text(_error,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 13)),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _cargar,
                              child: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      )
                    : _contratos.isEmpty
                        ? const Center(
                            child: Text(
                              'No hay contratos',
                              style: TextStyle(
                                  color: Colors.grey, fontSize: 14),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _cargar,
                            color: const Color(0xFF1695A3),
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(
                                  16, 8, 16, 100),
                              itemCount: _contratos.length,
                              itemBuilder: (_, i) =>
                                  _contratoCard(_contratos[i]),
                            ),
                          ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _navIndex,
        onTap: _onNavTap,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF225378),
        onPressed: () async {
          final result = await Navigator.pushNamed(
              context, '/contratos/nuevo');
          if (result == true) _cargar();
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // ── Chip de filtro ──────────────────────────────────
  Widget _chipFiltro(String? valor, String label) {
    final selected = _filtroEstado == valor;
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
          setState(() => _filtroEstado = valor);
          _cargar();
        },
      ),
    );
  }

  // ── Tarjeta de contrato ─────────────────────────────
  Widget _contratoCard(ContratoItem c) {
    final color = _colorEstado(c.estado);
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
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          final result = await Navigator.pushNamed(
            context,
            '/contratos/detalle',
            arguments: c.id,
          );
          if (result == true) _cargar();
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fila superior: propiedad + estado
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFACF0F2).withOpacity(0.4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.description_outlined,
                        color: Color(0xFF1695A3), size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      c.propiedadNombre,
                      style: const TextStyle(
                        color: Color(0xFF225378),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      c.estado.toUpperCase(),
                      style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Inquilino
              Row(
                children: [
                  const Icon(Icons.person_outline,
                      size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    c.arrendatarioNombre,
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Fechas y renta
              Row(
                children: [
                  const Icon(Icons.calendar_today,
                      size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '${c.fechaInicio} - ${c.fechaFin}',
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 11),
                  ),
                  const Spacer(),
                  Text(
                    '\$${c.rentaAcordada.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Color(0xFF225378),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '/${c.periodoPago}',
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
