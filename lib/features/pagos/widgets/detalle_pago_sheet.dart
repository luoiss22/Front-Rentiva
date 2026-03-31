import 'package:flutter/material.dart';
import '../../../core/services/api_client.dart';
import 'pago_models.dart';
import 'factura_pdf.dart';
import 'ficha_pago_pdf.dart';

// ─── BOTTOM SHEET DETALLE PAGO ────────────────────────────────────────────────
class DetallePagoSheet extends StatefulWidget {
  final Pago pago;
  // Ahora recibe el callback con método y referencia opcionales
  final Future<void> Function(String? metodo, String? referencia)? onMarcarRecibido;
  const DetallePagoSheet({super.key, required this.pago, this.onMarcarRecibido});

  @override
  State<DetallePagoSheet> createState() => _DetallePagoSheetState();
}

class _DetallePagoSheetState extends State<DetallePagoSheet> {
  Factura? _facturaLocal;
  bool _generando = false;
  bool _marcando = false;

  Factura? get _factura => widget.pago.factura ?? _facturaLocal;

  // ── Helpers de UI ──────────────────────────────────────────────────────────
  void _snack(String msg, Color color, {int segundos = 4}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      duration: Duration(seconds: segundos),
    ));
  }

  // ── Diálogo método de pago (opcional) ─────────────────────────────────────
  Future<void> _mostrarDialogoRecibido() async {
    String? metodoSeleccionado;
    final referenciaCtrl = TextEditingController();

    const metodos = <String, String>{
      'transferencia': 'Transferencia',
      'efectivo':      'Efectivo',
      'deposito':      'Depósito bancario',
      'tarjeta':       'Tarjeta',
      'otro':          'Otro',
    };

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Registrar pago recibido',
              style: TextStyle(color: Color(0xFF225378), fontWeight: FontWeight.bold, fontSize: 15)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Método de pago (opcional)',
                  style: TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: metodos.entries.map((e) {
                  final sel = metodoSeleccionado == e.key;
                  return GestureDetector(
                    onTap: () => setModalState(() =>
                        metodoSeleccionado = sel ? null : e.key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: sel
                            ? const Color(0xFF1695A3)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: sel ? const Color(0xFF1695A3) : Colors.grey.shade300,
                        ),
                      ),
                      child: Text(e.value,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: sel ? Colors.white : Colors.grey.shade600,
                          )),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: referenciaCtrl,
                decoration: InputDecoration(
                  labelText: 'Referencia (opcional)',
                  labelStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                  prefixIcon: const Icon(Icons.tag, color: Color(0xFF1695A3), size: 18),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF1695A3), width: 2),
                  ),
                ),
                style: const TextStyle(fontSize: 13, color: Color(0xFF225378)),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF15803D),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: const Text('Confirmar', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );

    if (confirmar != true || !mounted) return;

    setState(() => _marcando = true);
    try {
      await widget.onMarcarRecibido!(
        metodoSeleccionado,
        referenciaCtrl.text.trim().isEmpty ? null : referenciaCtrl.text.trim(),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        _snack('Error al registrar pago: $e', Colors.red);
        setState(() => _marcando = false);
      }
    }
  }

  // ── Lógica: generar factura ────────────────────────────────────────────────
  Future<void> _generarFactura() async {
    final faltantes = widget.pago.datosFiscalesFaltantes;

    if (faltantes.isNotEmpty) {
      String mensaje;
      if (faltantes.contains('inquilino') && faltantes.contains('propietario')) {
        mensaje = 'Faltan datos fiscales del inquilino (${widget.pago.inquilinoNombre}) '
            'y del propietario. Registra RFC, Régimen Fiscal, Uso CFDI y '
            'Código Postal de ambos para generar la factura.';
      } else if (faltantes.contains('inquilino')) {
        mensaje = 'Faltan datos fiscales del inquilino: ${widget.pago.inquilinoNombre}. '
            'Registra su RFC, Régimen Fiscal, Uso CFDI y Código Postal para continuar.';
      } else {
        mensaje = 'Faltan tus datos fiscales como propietario/arrendador. '
            'Regístralos en tu perfil (RFC, Régimen Fiscal, Uso CFDI y '
            'Código Postal) para poder generar la factura.';
      }
      _snack(mensaje, const Color(0xFFEB7F00), segundos: 6);
      return;
    }

    setState(() => _generando = true);
    _snack('Generando factura...', const Color(0xFF1695A3), segundos: 20);

    try {
      final subtotal = widget.pago.monto;
      final iva     = double.parse((subtotal * 0.16).toStringAsFixed(2));
      final total   = double.parse((subtotal + iva).toStringAsFixed(2));

      final data = await ApiClient.post('/facturas/', {
        'pago'         : widget.pago.id,
        'folio_fiscal' : 'CFDI-${widget.pago.id}-${DateTime.now().millisecondsSinceEpoch}',
        'subtotal'     : subtotal.toString(),
        'iva'          : iva.toString(),
        'total'        : total.toString(),
        'fecha_emision': DateTime.now().toIso8601String(),
      });

      final facturaCreada = Factura.fromJson(data);
      setState(() { _facturaLocal = facturaCreada; _generando = false; });

      _snack('Factura creada. Abriendo PDF...', const Color(0xFF1695A3));
      await FacturaPdf.generarConDatos(widget.pago, facturaCreada);

      if (mounted) _snack('Factura generada correctamente.', const Color(0xFF15803D));
    } catch (e) {
      if (mounted) {
        setState(() => _generando = false);
        _snack('Error al generar la factura: $e', Colors.red, segundos: 6);
      }
    }
  }

  // ── Lógica: ver factura existente ──────────────────────────────────────────
  Future<void> _verFactura() async {
    final factura = _factura;
    if (factura == null) return;
    try {
      await FacturaPdf.generarConDatos(widget.pago, factura);
    } catch (e) {
      _snack('Error al generar PDF: $e', Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pago = widget.pago;
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      expand: false,
      builder: (_, ctrl) => SingleChildScrollView(
        controller: ctrl,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Encabezado
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: pago.estado.bgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(pago.estado.icon, color: pago.estado.textColor, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(pago.inquilinoNombre,
                            style: const TextStyle(
                                color: Color(0xFF225378),
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                        Text(pago.periodo,
                            style: const TextStyle(color: Colors.grey, fontSize: 13)),
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
                              fontSize: 20)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: pago.estado.bgColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(pago.estado.label,
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: pago.estado.textColor)),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Divider(color: Colors.grey.shade100),
              const SizedBox(height: 12),
              // Detalles del pago
              _sheetTitle('Detalles del Pago'),
              const SizedBox(height: 10),
              _detailRow('Fecha límite', pago.fechaLimiteFormateada),
              if (pago.fechaPago != null)
                _detailRow('Fecha de pago',
                    '${pago.fechaPago!.day.toString().padLeft(2,'0')}/'
                    '${pago.fechaPago!.month.toString().padLeft(2,'0')}/'
                    '${pago.fechaPago!.year}'),
              if (pago.metodoPago != null)
                _detailRow('Método de pago',
                    pago.metodoPago!.name[0].toUpperCase() + pago.metodoPago!.name.substring(1)),
              if (pago.referencia.isNotEmpty)
                _detailRow('Referencia', pago.referencia),
              if (pago.recargaMora > 0)
                _detailRow('Recargo por mora',
                    '\$${pago.recargaMora.toStringAsFixed(2)}',
                    valueColor: const Color(0xFFBE123C)),

              // Ficha de pago
              if (pago.ficha != null) ...[
                const SizedBox(height: 16),
                _sheetTitle('Formato de Pago'),
                const SizedBox(height: 10),
                _detailRow('Referencia', pago.ficha!.codigoReferencia),
                _detailRow('CLABE', pago.ficha!.clabeInterbancaria),
                _detailRow('Banco', pago.ficha!.banco),
                _pdfBtn('Ver Formato de Pago', Icons.picture_as_pdf_outlined, () async {
                  try {
                    await FichaPagoPdf.generar(pago);
                  } catch (e) {
                    _snack(e.toString(), Colors.red);
                  }
                }),
              ] else if (pago.estado == PagoEstado.pendiente ||
                         pago.estado == PagoEstado.vencido) ...[
                const SizedBox(height: 16),
                _pdfBtn('Generar Formato de Pago', Icons.download_outlined, () async {
                  _snack('Verificando datos y generando formato...', const Color(0xFF1695A3));
                  try {
                    await FichaPagoPdf.generar(pago);
                  } catch (e) {
                    _snack(e.toString(), Colors.red);
                  }
                }),
              ],

              // ── Factura ──────────────────────────────────────────────────
              if (_factura != null) ...[
                const SizedBox(height: 16),
                _sheetTitle('Factura CFDI'),
                const SizedBox(height: 10),
                _detailRow('Folio Fiscal', _factura!.folioFiscal, small: true),
                _detailRow('Subtotal', '\$${_factura!.subtotal.toStringAsFixed(2)}'),
                _detailRow('IVA',      '\$${_factura!.iva.toStringAsFixed(2)}'),
                _detailRow('Total',    '\$${_factura!.total.toStringAsFixed(2)}',
                    valueColor: const Color(0xFF225378)),
                _pdfBtn('Ver Factura', Icons.picture_as_pdf_outlined, _verFactura),
              ] else if (pago.estado != PagoEstado.cancelado) ...[
                const SizedBox(height: 16),
                _generando
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: CircularProgressIndicator(
                            color: Color(0xFF1695A3),
                            strokeWidth: 2,
                          ),
                        ),
                      )
                    : _pdfBtn('Generar Factura', Icons.receipt_outlined, _generarFactura),
              ],

              // Botón marcar como recibido
              if (widget.onMarcarRecibido != null &&
                  (pago.estado == PagoEstado.pendiente ||
                      pago.estado == PagoEstado.vencido)) ...[
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _marcando ? null : _mostrarDialogoRecibido,
                    icon: _marcando
                        ? const SizedBox(width: 18, height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check_circle_outline, size: 18),
                    label: Text(_marcando ? 'Registrando...' : 'Marcar como Recibido'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF15803D),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      textStyle: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── Widgets estáticos ─────────────────────────────────────────────────────
  Widget _sheetTitle(String title) {
    return Text(title,
        style: const TextStyle(
            color: Color(0xFF225378), fontWeight: FontWeight.bold, fontSize: 14));
  }

  Widget _detailRow(String label, String value,
      {Color? valueColor, bool small = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.right,
                style: TextStyle(
                    color: valueColor ?? const Color(0xFF225378),
                    fontWeight: FontWeight.w600,
                    fontSize: small ? 10 : 12)),
          ),
        ],
      ),
    );
  }

  Widget _pdfBtn(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFACF0F2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF1695A3), size: 16),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    color: Color(0xFF1695A3),
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
