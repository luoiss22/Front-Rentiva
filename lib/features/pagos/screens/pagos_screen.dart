import 'package:flutter/material.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/bottom_navbar.dart';
import '../widgets/pago_models.dart';
import '../widgets/pago_data.dart';
import '../widgets/pago_tile.dart';
import '../widgets/detalle_pago_sheet.dart';
import '../widgets/pago_action_btn.dart';
import '../widgets/factura_pdf.dart';
import '../widgets/ficha_pago_pdf.dart';

// ─── PANTALLA ─────────────────────────────────────────────────────────────────
class PagosScreen extends StatefulWidget {
  const PagosScreen({super.key});

  @override
  State<PagosScreen> createState() => _PagosScreenState();
}

class _PagosScreenState extends State<PagosScreen> {
  final int _navIndex = 3;
  String _filtro = 'todos';
  late final List<Pago> _pagos = List.of(pagosEjemplo);

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
  double get _totalMes => _pagos
      .where((p) => p.estado == PagoEstado.pagado)
      .fold(0, (s, p) => s + p.monto);

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
      body: CustomScrollView(
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

                // ── Botones de acción ─────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: PagoActionBtn(
                          icon: Icons.receipt_outlined,
                          label: 'Generar Factura',
                          primary: true,
                          onTap: () => _mostrarDialogoFactura(context),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: PagoActionBtn(
                          icon: Icons.download_outlined,
                          label: 'Formato Pago',
                          primary: false,
                          onTap: () => _mostrarDialogoFicha(context),
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
      ),
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
            ? () => _marcarComoRecibido(pago)
            : null,
      ),
    );
  }

  // ── MARCAR COMO RECIBIDO ──────────────────────────────────────────────────
  void _marcarComoRecibido(Pago pago) {
    setState(() {
      final idx = _pagos.indexWhere((p) => p.id == pago.id);
      if (idx != -1) {
        _pagos[idx] = pago.copyWith(
          estado: PagoEstado.pagado,
          fechaPago: DateTime.now(),
        );
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Pago de ${pago.inquilinoNombre} marcado como recibido'),
      backgroundColor: const Color(0xFF15803D),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // ── DIÁLOGO GENERAR FACTURA ───────────────────────────────────────────────
  void _mostrarDialogoFactura(BuildContext context) {
    final pagosConFactura =
        _pagos.where((p) => p.factura != null).toList();
    if (pagosConFactura.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('No hay pagos con factura disponible'),
        backgroundColor: Color(0xFFEB7F00),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _SelectorPagoSheet(
        titulo: 'Generar Factura PDF',
        icono: Icons.receipt_outlined,
        color: const Color(0xFF1695A3),
        pagos: pagosConFactura,
        onSeleccionar: (pago) {
          Navigator.pop(context);
          FacturaPdf.generar(pago);
        },
      ),
    );
  }

  // ── DIÁLOGO FORMATO DE PAGO (FICHA) ──────────────────────────────────────
  void _mostrarDialogoFicha(BuildContext context) {
    final pagosPendientes = _pagos
        .where((p) =>
            p.estado == PagoEstado.pendiente ||
            p.estado == PagoEstado.vencido)
        .toList();
    if (pagosPendientes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('No hay pagos pendientes para generar ficha'),
        backgroundColor: Color(0xFFEB7F00),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _SelectorPagoSheet(
        titulo: 'Formato de Pago PDF',
        icono: Icons.download_outlined,
        color: const Color(0xFF225378),
        pagos: pagosPendientes,
        onSeleccionar: (pago) {
          Navigator.pop(context);
          FichaPagoPdf.generar(pago);
        },
      ),
    );
  }
}

// ─── SELECTOR DE PAGO (bottom sheet) ─────────────────────────────────────────
class _SelectorPagoSheet extends StatelessWidget {
  final String titulo;
  final IconData icono;
  final Color color;
  final List<Pago> pagos;
  final ValueChanged<Pago> onSeleccionar;

  const _SelectorPagoSheet({
    required this.titulo,
    required this.icono,
    required this.color,
    required this.pagos,
    required this.onSeleccionar,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Icon(icono, color: color, size: 22),
            const SizedBox(width: 10),
            Text(titulo,
                style: const TextStyle(
                    color: Color(0xFF225378),
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
          ]),
          const SizedBox(height: 6),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Selecciona un pago para generar el PDF:',
                style: TextStyle(color: Colors.grey, fontSize: 13)),
          ),
          const SizedBox(height: 14),
          ...pagos.map((p) => _pagoItem(context, p)),
        ],
      ),
    );
  }

  Widget _pagoItem(BuildContext context, Pago pago) {
    return GestureDetector(
      onTap: () => onSeleccionar(pago),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: pago.estado.bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(pago.estado.icon,
                color: pago.estado.textColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pago.inquilinoNombre,
                    style: const TextStyle(
                        color: Color(0xFF225378),
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
                const SizedBox(height: 2),
                Text(pago.periodo,
                    style:
                        const TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(pago.montoFormateado,
                  style: const TextStyle(
                      color: Color(0xFF225378),
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
              const SizedBox(height: 2),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: pago.estado.bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(pago.estado.label,
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: pago.estado.textColor)),
              ),
            ],
          ),
          const SizedBox(width: 8),
          Icon(Icons.picture_as_pdf_outlined, color: color, size: 20),
        ]),
      ),
    );
  }
}
