import 'package:flutter/material.dart';
import 'pago_models.dart';
import 'factura_pdf.dart';
import 'ficha_pago_pdf.dart';

// ─── BOTTOM SHEET DETALLE PAGO ────────────────────────────────────────────────
class DetallePagoSheet extends StatelessWidget {
  final Pago pago;
  final VoidCallback? onMarcarRecibido;
  const DetallePagoSheet({super.key, required this.pago, this.onMarcarRecibido});

  @override
  Widget build(BuildContext context) {
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
                    child: Icon(pago.estado.icon,
                        color: pago.estado.textColor, size: 24),
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
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 13)),
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
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
                    '${pago.fechaPago!.day.toString().padLeft(2, '0')}/'
                    '${pago.fechaPago!.month.toString().padLeft(2, '0')}/'
                    '${pago.fechaPago!.year}'),
              if (pago.metodoPago != null)
                _detailRow('Método de pago',
                    pago.metodoPago!.name[0].toUpperCase() +
                        pago.metodoPago!.name.substring(1)),
              if (pago.referencia.isNotEmpty)
                _detailRow('Referencia', pago.referencia),
              if (pago.recargaMora > 0)
                _detailRow('Recargo por mora',
                    '\$${pago.recargaMora.toStringAsFixed(2)}',
                    valueColor: const Color(0xFFBE123C)),

              // Ficha de pago
              if (pago.ficha != null) ...[
                const SizedBox(height: 16),
                _sheetTitle('Ficha de Pago'),
                const SizedBox(height: 10),
                _detailRow('Referencia', pago.ficha!.codigoReferencia),
                _detailRow('CLABE', pago.ficha!.clabeInterbancaria),
                _detailRow('Banco', pago.ficha!.banco),
                _pdfBtn(context, 'Descargar Ficha PDF',
                    Icons.picture_as_pdf_outlined,
                    () => FichaPagoPdf.generar(pago)),
              ]
              else if (pago.estado == PagoEstado.pendiente ||
                       pago.estado == PagoEstado.vencido) ...[
                const SizedBox(height: 16),
                _pdfBtn(context, 'Descargar Ficha PDF',
                    Icons.picture_as_pdf_outlined,
                    () => FichaPagoPdf.generar(pago)),
              ],

              // Factura
              if (pago.factura != null) ...[
                const SizedBox(height: 16),
                _sheetTitle('Factura CFDI'),
                const SizedBox(height: 10),
                _detailRow('Folio Fiscal', pago.factura!.folioFiscal,
                    small: true),
                _detailRow('Subtotal',
                    '\$${pago.factura!.subtotal.toStringAsFixed(2)}'),
                _detailRow('IVA',
                    '\$${pago.factura!.iva.toStringAsFixed(2)}'),
                _detailRow('Total',
                    '\$${pago.factura!.total.toStringAsFixed(2)}',
                    valueColor: const Color(0xFF225378)),
                _pdfBtn(context, 'Descargar Factura PDF',
                    Icons.picture_as_pdf_outlined,
                    () => FacturaPdf.generar(pago)),
              ],

              // Botón marcar como recibido
              if (onMarcarRecibido != null &&
                  (pago.estado == PagoEstado.pendiente ||
                      pago.estado == PagoEstado.vencido)) ...[
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      onMarcarRecibido!();
                    },
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('Marcar como Recibido'),
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

  static Widget _sheetTitle(String title) {
    return Text(title,
        style: const TextStyle(
            color: Color(0xFF225378),
            fontWeight: FontWeight.bold,
            fontSize: 14));
  }

  static Widget _detailRow(String label, String value,
      {Color? valueColor, bool small = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.grey, fontSize: 12)),
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

  static Widget _pdfBtn(
      BuildContext context, String label, IconData icon, VoidCallback onTap) {
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
