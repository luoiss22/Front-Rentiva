import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'pago_models.dart';

// ─── GENERADOR PDF: FACTURA (CFDI) ──────────────────────────────────────────
class FacturaPdf {
  static Future<void> generar(Pago pago) async {
    try {
      final factura = pago.factura;
      if (factura == null) return;
      await _buildAndPrint(pago, factura);
    } catch (e, stackTrace) {
      debugPrint("Error al generar factura PDF: $e\n$stackTrace");
      rethrow;
    }
  }

  /// Genera el PDF con una Factura ya creada (no necesita pago.factura).
  static Future<void> generarConDatos(Pago pago, Factura factura) async {
    try {
      await _buildAndPrint(pago, factura);
    } catch (e, stackTrace) {
      debugPrint("Error al generar factura PDF: $e\n$stackTrace");
      rethrow;
    }
  }

  static Future<void> _buildAndPrint(Pago pago, Factura factura) async {
    final pdf = pw.Document();
    final now = DateTime.now();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(40),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // ── Encabezado ──────────────────────────────────────────────
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: const PdfColor.fromInt(0xFF225378),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('RENTIVA',
                          style: pw.TextStyle(
                              color: PdfColors.white,
                              fontSize: 22,
                              fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 4),
                      pw.Text('Comprobante Fiscal Digital',
                          style: const pw.TextStyle(
                              color: PdfColors.white, fontSize: 10)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('FACTURA',
                          style: pw.TextStyle(
                              color: PdfColors.white,
                              fontSize: 18,
                              fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 4),
                      pw.Text(
                          'Fecha: ${_fmtDate(factura.fechaEmision)}',
                          style: const pw.TextStyle(
                              color: PdfColors.white, fontSize: 10)),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // ── Folio Fiscal ────────────────────────────────────────────
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: const PdfColor.fromInt(0xFFF0FDFA),
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(
                    color: const PdfColor.fromInt(0xFFACF0F2)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('FOLIO FISCAL (UUID)',
                      style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: const PdfColor.fromInt(0xFF1695A3))),
                  pw.SizedBox(height: 4),
                  pw.Text(factura.folioFiscal,
                      style: const pw.TextStyle(fontSize: 11)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // ── Datos emisor / receptor ─────────────────────────────────
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: _datosBox('EMISOR', [
                    factura.emisorDetalles?.nombreORazonSocial ?? 'Emisor no registrado',
                    'RFC: ${factura.emisorDetalles?.rfc ?? "No registrado"}',
                    'Régimen: ${factura.emisorDetalles?.regimenFiscal ?? "No registrado"}',
                    'C.P.: ${factura.emisorDetalles?.codigoPostal ?? "No registrado"}',
                  ]),
                ),
                pw.SizedBox(width: 16),
                pw.Expanded(
                  child: _datosBox('RECEPTOR', [
                    factura.receptorDetalles?.nombreORazonSocial ?? pago.inquilinoNombre,
                    'RFC: ${factura.receptorDetalles?.rfc ?? "No registrado"}',
                    'Uso CFDI: ${factura.receptorDetalles?.usoCfdi ?? "No registrado"}',
                    'C.P.: ${factura.receptorDetalles?.codigoPostal ?? "No registrado"}',
                  ]),
                ),
              ],
            ),
            pw.SizedBox(height: 20),

            // ── Tabla de conceptos ──────────────────────────────────────
            _tablaConcetos(pago, factura),
            pw.SizedBox(height: 20),

            // ── Totales ─────────────────────────────────────────────────
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Container(
                width: 220,
                padding: const pw.EdgeInsets.all(14),
                decoration: pw.BoxDecoration(
                  color: const PdfColor.fromInt(0xFFF8FAFC),
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(
                      color: const PdfColor.fromInt(0xFFE5E7EB)),
                ),
                child: pw.Column(children: [
                  _totalRow('Subtotal', factura.subtotal),
                  pw.SizedBox(height: 6),
                  _totalRow('IVA (16%)', factura.iva),
                  pw.SizedBox(height: 6),
                  pw.Divider(color: const PdfColor.fromInt(0xFFE5E7EB)),
                  pw.SizedBox(height: 6),
                  _totalRow('TOTAL', factura.total, bold: true),
                ]),
              ),
            ),
            pw.SizedBox(height: 20),

            // ── Información complementaria ──────────────────────────────
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: const PdfColor.fromInt(0xFFF8FAFC),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('INFORMACIÓN COMPLEMENTARIA',
                      style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: const PdfColor.fromInt(0xFF225378))),
                  pw.SizedBox(height: 6),
                  pw.Text('Periodo de renta: ${pago.periodo}',
                      style: const pw.TextStyle(fontSize: 10)),
                  if (pago.metodoPago != null)
                    pw.Text(
                        'Método de pago: ${pago.metodoPago!.name[0].toUpperCase()}${pago.metodoPago!.name.substring(1)}',
                        style: const pw.TextStyle(fontSize: 10)),
                  if (pago.referencia.isNotEmpty)
                    pw.Text('Referencia: ${pago.referencia}',
                        style: const pw.TextStyle(fontSize: 10)),
                  if (pago.fechaPago != null)
                    pw.Text('Fecha de pago: ${_fmtDate(pago.fechaPago!)}',
                        style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
            ),

            pw.Spacer(),

            // ── Pie de página ───────────────────────────────────────────
            pw.Divider(color: const PdfColor.fromInt(0xFFE5E7EB)),
            pw.SizedBox(height: 6),
            pw.Center(
              child: pw.Text(
                'Este documento es una representación impresa de un CFDI  -  Generado: ${_fmtDate(now)}',
                style: const pw.TextStyle(
                    color: PdfColors.grey600, fontSize: 8),
              ),
            ),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(
        onLayout: (format) async => pdf.save(),
        name: 'Factura_${pago.periodo.replaceAll(' ', '_')}_${pago.inquilinoNombre.replaceAll(' ', '_')}.pdf',
      );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  static String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  static String _fmtMoney(double v) =>
      '\$${v.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+\.)'), (m) => '${m[1]},')}';

  static pw.Widget _datosBox(String titulo, List<String> lineas) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: const PdfColor.fromInt(0xFFE5E7EB)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(titulo,
              style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: const PdfColor.fromInt(0xFF225378))),
          pw.SizedBox(height: 6),
          ...lineas.map((l) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 3),
                child: pw.Text(l, style: const pw.TextStyle(fontSize: 10)),
              )),
        ],
      ),
    );
  }

  static pw.Widget _tablaConcetos(Pago pago, Factura factura) {
    return pw.TableHelper.fromTextArray(
      border: pw.TableBorder.all(color: const PdfColor.fromInt(0xFFE5E7EB)),
      headerDecoration: const pw.BoxDecoration(
        color: PdfColor.fromInt(0xFF225378),
      ),
      headerStyle: pw.TextStyle(
          color: PdfColors.white,
          fontSize: 10,
          fontWeight: pw.FontWeight.bold),
      cellStyle: const pw.TextStyle(fontSize: 10),
      cellAlignment: pw.Alignment.centerLeft,
      headerAlignment: pw.Alignment.centerLeft,
      cellPadding: const pw.EdgeInsets.all(8),
      headers: ['Concepto', 'Periodo', 'Cantidad', 'Importe'],
      data: [
        [
          'Renta de inmueble',
          pago.periodo,
          '1',
          _fmtMoney(factura.subtotal),
        ],
        if (pago.recargaMora > 0)
          [
            'Recargo por mora',
            pago.periodo,
            '1',
            _fmtMoney(pago.recargaMora),
          ],
      ],
    );
  }

  static pw.Widget _totalRow(String label, double value,
      {bool bold = false}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label,
            style: pw.TextStyle(
                fontSize: bold ? 12 : 10,
                fontWeight: bold ? pw.FontWeight.bold : null,
                color: const PdfColor.fromInt(0xFF225378))),
        pw.Text(_fmtMoney(value),
            style: pw.TextStyle(
                fontSize: bold ? 12 : 10,
                fontWeight: bold ? pw.FontWeight.bold : null,
                color: const PdfColor.fromInt(0xFF225378))),
      ],
    );
  }
}
