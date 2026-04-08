import 'package:flutter/material.dart';
import '../../../core/services/api_client.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/bottom_navbar.dart';
import '../widgets/pago_models.dart';
import '../widgets/pago_tile.dart';
import '../widgets/detalle_pago_sheet.dart';

// ─── PANTALLA ─────────────────────────────────────────────────────────────────
class PagosScreen extends StatefulWidget {
  const PagosScreen({super.key});

  @override
  State<PagosScreen> createState() => _PagosScreenState();
}

class _PagosScreenState extends State<PagosScreen> {
  final int _navIndex = 3;
  String _filtro = 'todos';
  List<Pago> _pagos = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarPagos();
  }

  Future<void> _cargarPagos() async {
    setState(() { _loading = true; _error = null; });
    try {
      // Cargamos todas las páginas para que los totales sean correctos
      final List<Pago> todos = [];
      int page = 1;
      while (true) {
        final data = await ApiClient.get('/pagos/?page=$page&page_size=100');
        final results = data['results'] as List;
        todos.addAll(results.map((e) => Pago.fromJson(e)));
        // Si no hay siguiente página, salimos
        if (data['next'] == null) break;
        page++;
      }
      setState(() {
        _pagos = todos;
        _loading = false;
      });
    } on ApiException catch (e) {
      setState(() { _error = e.message; _loading = false; });
    } catch (e) {
      setState(() { _error = 'Error de conexión'; _loading = false; });
    }
  }

  static const List<Map<String, String>> _filtros = [
    {'value': 'todos',      'label': 'Todos'},
    {'value': 'pagado',     'label': 'Recibidos'},
    {'value': 'pendiente',  'label': 'Pendientes'},
    {'value': 'vencido',    'label': 'Vencidos'},
  ];

  void _onNavTap(int index) {
    const routes = [
      '/inicio-usuario', '/propiedades', '/inquilinos', '', '/mantenimiento',
    ];
    if (index != _navIndex) Navigator.pushNamed(context, routes[index]);
  }

  List<Pago> get _filtrados {
    if (_filtro == 'todos') return _pagos;
    return _pagos
        .where((p) => p.estado.name == _filtro)
        .toList();
  }

  // Totales
  double get _totalMes {
    final ahora = DateTime.now();
    return _pagos
        .where((p) =>
            p.estado == PagoEstado.pagado &&
            p.fechaPago != null &&
            p.fechaPago!.year == ahora.year &&
            p.fechaPago!.month == ahora.month)
        .fold(0, (s, p) => s + p.monto);
  }

  double get _totalPendiente => _pagos
      .where((p) =>
          p.estado == PagoEstado.pendiente || p.estado == PagoEstado.vencido)
      .fold(0, (s, p) => s + p.monto + p.recargaMora);

  String _fmt(double v) =>
      '\$${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const AppHeader(title: 'Pagos y Facturas'),
      bottomNavigationBar:
          BottomNavBar(currentIndex: _navIndex, onTap: _onNavTap),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1695A3)))
          : _error != null
              ? Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 12),
                    ElevatedButton(onPressed: _cargarPagos, child: const Text('Reintentar')),
                  ],
                ))
              : CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              children: [
                // ── Tarjetas resumen ──────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    children: [
                      // Ingresos del mes
                      Expanded(
                        child: Container(
                          height: 100,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF225378),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                  color: const Color(0xFF225378).withOpacity(0.3),
                                  blurRadius: 12, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('INGRESOS (MES)',
                                  style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 10,
                                      letterSpacing: 1)),
                              Text(_fmt(_totalMes),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Pendiente
                      Expanded(
                        child: Container(
                          height: 100,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: const Color(0xFFACF0F2)),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 8),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('PENDIENTE',
                                  style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 10,
                                      letterSpacing: 1)),
                              Text(_fmt(_totalPendiente),
                                  style: const TextStyle(
                                      color: Color(0xFFEB7F00),
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Filtros ───────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 6),
                      ],
                    ),
                    child: Row(
                      children: _filtros.map((f) {
                        final isActive = _filtro == f['value'];
                        return Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _filtro = f['value']!),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? const Color(0xFFACF0F2)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                f['label']!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isActive
                                      ? const Color(0xFF1695A3)
                                      : Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),

          // ── Lista de movimientos ────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
                    child: Text('Movimientos Recientes',
                        style: TextStyle(
                            color: Color(0xFF225378),
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
                  ),
                  if (_filtrados.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Text('No hay movimientos',
                            style: TextStyle(
                                color: Colors.grey, fontSize: 14)),
                      ),
                    )
                  else
                    ...List.generate(_filtrados.length, (i) {
                      final pago = _filtrados[i];
                      return PagoTile(
                        pago: pago,
                        isLast: i == _filtrados.length - 1,
                        onTap: () => _mostrarDetallePago(context, pago),
                      );
                    }),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),  // CustomScrollView end
    );
  }

  // ── DIÁLOGO DETALLE PAGO ──────────────────────────────────────────────────
  void _mostrarDetallePago(BuildContext context, Pago pago) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => DetallePagoSheet(
        pago: pago,
        onMarcarRecibido: (pago.estado == PagoEstado.pendiente ||
                pago.estado == PagoEstado.vencido)
            ? (metodo, referencia) => _marcarComoRecibido(pago, metodo, referencia)
            : null,
      ),
    );
  }

  // ── MARCAR COMO RECIBIDO ──────────────────────────────────────────────────
  Future<void> _marcarComoRecibido(Pago pago, String? metodo, String? referencia) async {
    final body = <String, dynamic>{
      'estado':     'pagado',
      'fecha_pago': DateTime.now().toIso8601String().split('T').first,
    };
    if (metodo != null) body['metodo_pago'] = metodo;
    if (referencia != null && referencia.isNotEmpty) body['referencia'] = referencia;

    try {
      await ApiClient.patch('/pagos/${pago.id}/', body);
      await _cargarPagos();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Pago de ${pago.inquilinoNombre} marcado como recibido'),
          backgroundColor: const Color(0xFF15803D),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Error al registrar el pago'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

}