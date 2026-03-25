import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'pago_models.dart';

// ─── GENERADOR PDF: FICHA DE PAGO ─────────────────────────────────────────── 
class FichaPagoPdf {
  static Future<void> generar(Pago pago) async {
    try {
      final ficha = pago.ficha;

    // Datos por defecto si no existe ficha asociada
    final codigo = ficha?.codigoReferencia ??
        'REF-${pago.id.toString().padLeft(6, '0')}';
    final clabe = ficha?.clabeInterbancaria ?? '012345678901234567';
    final banco = ficha?.banco ?? 'BBVA México';
    final fechaGen = ficha?.fechaGeneracion ?? DateTime.now();

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
                      pw.Text('Sistema de Administración de Rentas',
                          style: const pw.TextStyle(
                              color: PdfColors.white, fontSize: 10)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('FORMATO DE PAGO',
                          style: pw.TextStyle(
                              color: PdfColors.white,
                              fontSize: 16,
                              fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 4),
                      pw.Text('Generado: ${_fmtDate(now)}',
                          style: const pw.TextStyle(
                              color: PdfColors.white, fontSize: 10)),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 24),

            // ── Código de referencia (destacado) ────────────────────────
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(
                  vertical: 16, horizontal: 20),
              decoration: pw.BoxDecoration(
                color: const PdfColor.fromInt(0xFFF0FDFA),
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(
                    color: const PdfColor.fromInt(0xFF1695A3), width: 1.5),
              ),
              child: pw.Column(children: [
                pw.Text('CÓDIGO DE REFERENCIA',
                    style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: const PdfColor.fromInt(0xFF1695A3))),
                pw.SizedBox(height: 8),
                pw.Text(codigo,
                    style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: const PdfColor.fromInt(0xFF225378),
                        letterSpacing: 2)),
              ]),
            ),
            pw.SizedBox(height: 24),

            // ── Datos del pago ──────────────────────────────────────────
            _seccionTitulo('DATOS DEL PAGO'),
            pw.SizedBox(height: 10),
            _infoCard([
              _row('Inquilino', pago.inquilinoNombre),
              _row('Periodo', pago.periodo),
              _row('Monto a pagar', _fmtMoney(pago.monto)),
              if (pago.recargaMora > 0)
                _row('Recargo por mora', _fmtMoney(pago.recargaMora)),
              if (pago.recargaMora > 0)
                _row('Total a pagar',
                    _fmtMoney(pago.monto + pago.recargaMora),
                    bold: true),
              _row('Fecha límite', _fmtDate(pago.fechaLimite)),
              _row('Estado', pago.estado.label),
            ]),
            pw.SizedBox(height: 20),

            // ── Datos bancarios ─────────────────────────────────────────
            _seccionTitulo('DATOS BANCARIOS PARA DEPÓSITO / TRANSFERENCIA'),
            pw.SizedBox(height: 10),
            _infoCard([
              _row('Banco destino', banco),
              _row('CLABE interbancaria', clabe),
              _row('Beneficiario', 'Rentiva S.A. de C.V.'),
              _row('Referencia', codigo),
              _row('Concepto', 'Renta ${pago.periodo}'),
            ]),
            pw.SizedBox(height: 20),

            // ── Instrucciones ───────────────────────────────────────────
            _seccionTitulo('INSTRUCCIONES'),
            pw.SizedBox(height: 10),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                color: const PdfColor.fromInt(0xFFFFFBEB),
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(
                    color: const PdfColor.fromInt(0xFFFCD34D)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _instruccion('1',
                      'Realice la transferencia o depósito con la CLABE y referencia indicadas.'),
                  _instruccion('2',
                      'El pago debe realizarse antes de la fecha límite para evitar recargos.'),
                  _instruccion('3',
                      'Conserve su comprobante de pago como respaldo.'),
                  _instruccion('4',
                      'Una vez confirmado el depósito, su pago se reflejará en el sistema.'),
                ],
              ),
            ),

            pw.Spacer(),

            // ── Pie de página ───────────────────────────────────────────
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: const PdfColor.fromInt(0xFFF8FAFC),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Column(children: [
                pw.Text(
                  'Ficha generada: ${_fmtDate(fechaGen)}  •  Válida hasta: ${_fmtDate(pago.fechaLimite)}',
                  style: const pw.TextStyle(
                      color: PdfColors.grey600, fontSize: 8),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  'Cualquier duda comuníquese al soporte de Rentiva.',
                  style: const pw.TextStyle(
                      color: PdfColors.grey600, fontSize: 8),
                ),
              ]),
            ),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(
        onLayout: (format) async => pdf.save(),
        name: 'FichaPago_${pago.periodo.replaceAll(' ', '_')}_${pago.inquilinoNombre.replaceAll(' ', '_')}.pdf',
      );
    } catch (e, stackTrace) {
      debugPrint("Error al generar ficha de pago PDF: $e\n$stackTrace");
      rethrow;
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  static String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  static String _fmtMoney(double v) =>
      '\$${v.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+\.)'), (m) => '${m[1]},')}';

  static pw.Widget _seccionTitulo(String titulo) {
    return pw.Row(children: [
      pw.Container(
        width: 4, height: 14,
        decoration: pw.BoxDecoration(
            color: const PdfColor.fromInt(0xFF1695A3),
            borderRadius: pw.BorderRadius.circular(2)),
      ),
      pw.SizedBox(width: 8),
      pw.Text(titulo,
          style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: const PdfColor.fromInt(0xFF225378))),
    ]);
  }

  static pw.Widget _infoCard(List<pw.Widget> children) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: const PdfColor.fromInt(0xFFE5E7EB)),
      ),
      child: pw.Column(children: children),
    );
  }

  static pw.Widget _row(String label, String value, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label,
              style: const pw.TextStyle(
                  color: PdfColors.grey700, fontSize: 10)),
          pw.Text(value,
              style: pw.TextStyle(
                  fontSize: bold ? 11 : 10,
                  fontWeight: bold ? pw.FontWeight.bold : null,
                  color: const PdfColor.fromInt(0xFF225378))),
        ],
      ),
    );
  }

  static pw.Widget _instruccion(String num, String texto) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 18, height: 18,
            decoration: pw.BoxDecoration(
              color: const PdfColor.fromInt(0xFFEB7F00),
              shape: pw.BoxShape.circle,
            ),
            child: pw.Center(
                child: pw.Text(num,
                    style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold))),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
              child: pw.Text(texto,
                  style: const pw.TextStyle(fontSize: 10))),
        ],
      ),
    );
  }
}
