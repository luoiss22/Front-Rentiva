import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../screens/informacion_propiedad_screen.dart';

/// Genera un PDF del contrato de arrendamiento rellenado con datos reales.
class ContratoPdf {
  static Future<void> generar(PropiedadDetalle propiedad) async {
    final inquilino = propiedad.inquilino;
    if (inquilino == null) return;

    await generarConDatos(
      arrendatario: inquilino.nombre,
      inmuebleDireccion:
          '${propiedad.direccion}, ${propiedad.ciudad}, ${propiedad.estadoGeografico}',
      renta: propiedad.precio,
      ciudad: propiedad.ciudad,
      fechaInicio: inquilino.desde,
    );
  }

  /// Genera el PDF con datos explícitos (reutilizable desde cualquier pantalla).
  static Future<void> generarConDatos({
    required String arrendatario,
    required String inmuebleDireccion,
    required String renta,
    required String ciudad,
    String? arrendador,
    String? fechaInicio,
    String? fechaFin,
    String? deposito,
  }) async {

    final pdf = pw.Document();
    final now = DateTime.now();

    // ── Datos para rellenar ──────────────────────────────────────────────
    final arrendadorNombre = arrendador ?? 'El Propietario';
    final fiador = '________________________';
    final dia = now.day.toString().padLeft(2, '0');
    final meses = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
    ];
    final mes = meses[now.month - 1];
    final anio = now.year.toString();

    // Vigencia del contrato
    final vigencia = (fechaInicio != null && fechaFin != null)
        ? 'Del $fechaInicio al $fechaFin'
        : (fechaInicio != null ? 'Desde $fechaInicio' : 'Según acuerdo entre las partes');

    // Depósito
    final depositoTexto = (deposito != null && deposito.isNotEmpty) ? deposito : renta;

    // ── Estilos ──────────────────────────────────────────────────────────
    const dark = PdfColor.fromInt(0xFF225378);
    const teal = PdfColor.fromInt(0xFF1695A3);

    final titleStyle = pw.TextStyle(
        fontSize: 18, fontWeight: pw.FontWeight.bold, color: dark);
    final subtitleStyle = pw.TextStyle(
        fontSize: 12, fontWeight: pw.FontWeight.bold, color: dark);
    final bodyStyle =
        const pw.TextStyle(fontSize: 9, color: PdfColors.grey800, lineSpacing: 4);
    final boldBody = pw.TextStyle(
        fontSize: 9, fontWeight: pw.FontWeight.bold, color: dark);
    final clauseTitle = pw.TextStyle(
        fontSize: 10, fontWeight: pw.FontWeight.bold, color: teal);

    // ── Helper para cláusulas ────────────────────────────────────────────
    pw.Widget clausula(String titulo, String contenido) {
      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 10),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(titulo, style: clauseTitle),
            pw.SizedBox(height: 3),
            pw.Text(contenido, style: bodyStyle, textAlign: pw.TextAlign.justify),
          ],
        ),
      );
    }

    // ── Página 1: Portada + Declaraciones ────────────────────────────────
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(40),
        header: (ctx) => ctx.pageNumber == 1
            ? pw.SizedBox.shrink()
            : pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 10),
                padding: const pw.EdgeInsets.only(bottom: 6),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                      bottom: pw.BorderSide(color: teal, width: 0.5)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('RENTIVA — Contrato de Arrendamiento',
                        style: const pw.TextStyle(
                            fontSize: 8, color: PdfColors.grey500)),
                    pw.Text('Página ${ctx.pageNumber}',
                        style: const pw.TextStyle(
                            fontSize: 8, color: PdfColors.grey500)),
                  ],
                ),
              ),
        footer: (ctx) => pw.Container(
          margin: const pw.EdgeInsets.only(top: 10),
          padding: const pw.EdgeInsets.only(top: 6),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
                top: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Documento generado por Rentiva',
                  style: const pw.TextStyle(
                      fontSize: 7, color: PdfColors.grey400)),
              pw.Text('$dia/$mes/$anio',
                  style: const pw.TextStyle(
                      fontSize: 7, color: PdfColors.grey400)),
            ],
          ),
        ),
        build: (ctx) => [
          // ── Encabezado con branding ──────────────────────────────────
          pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              color: dark,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              children: [
                pw.Text('CONTRATO DE ARRENDAMIENTO',
                    style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white)),
                pw.SizedBox(height: 6),
                pw.Container(
                  width: 40,
                  height: 2,
                  color: const PdfColor.fromInt(0xFFEB7F00),
                ),
                pw.SizedBox(height: 6),
                pw.Text('RENTIVA',
                    style: pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.white,
                        fontWeight: pw.FontWeight.bold,
                        letterSpacing: 4)),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // ── Datos generales ──────────────────────────────────────────
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: teal, width: 0.5),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('DATOS DEL CONTRATO', style: subtitleStyle),
                pw.SizedBox(height: 8),
                _datoRow('Arrendador:', arrendadorNombre, boldBody, bodyStyle),
                _datoRow('Arrendatario:', arrendatario, boldBody, bodyStyle),
                _datoRow('Fiador:', fiador, boldBody, bodyStyle),
                _datoRow('Inmueble:', inmuebleDireccion, boldBody, bodyStyle),
                _datoRow('Renta mensual:', renta, boldBody, bodyStyle),
                _datoRow('Vigencia:', vigencia, boldBody, bodyStyle),
                _datoRow('Fecha:', '$dia de $mes de $anio', boldBody, bodyStyle),
                _datoRow('Lugar:', ciudad, boldBody, bodyStyle),
              ],
            ),
          ),
          pw.SizedBox(height: 16),

          // ── Preámbulo ────────────────────────────────────────────────
          pw.Text(
            'En $ciudad, siendo los $dia días del mes de $mes de $anio, '
            'se celebra el presente Contrato de Arrendamiento entre '
            '$arrendadorNombre, como Arrendador, y $arrendatario, como '
            'Arrendatario, respecto del inmueble ubicado en '
            '$inmuebleDireccion, de conformidad con lo siguiente:',
            style: bodyStyle,
            textAlign: pw.TextAlign.justify,
          ),
          pw.SizedBox(height: 14),

          // ── DECLARACIONES ────────────────────────────────────────────
          pw.Text('DECLARACIONES', style: titleStyle),
          pw.SizedBox(height: 10),

          pw.Text('I. DECLARA EL ARRENDADOR:', style: subtitleStyle),
          pw.SizedBox(height: 4),
          pw.Text(
            'a) Que tiene las facultades suficientes y bastantes para obligarse en términos del presente instrumento.\n'
            'b) Que es el único legítimo propietario del inmueble ubicado en $inmuebleDireccion '
            '(el "Inmueble") según consta en la escritura que se adjunta a este Contrato como Anexo número 1, '
            'y que es su deseo darlo en arrendamiento en favor del Arrendatario.\n'
            'c) Que está legalmente facultado para dar en arrendamiento el Inmueble en los términos y '
            'condiciones establecidos en este Contrato.',
            style: bodyStyle,
            textAlign: pw.TextAlign.justify,
          ),
          pw.SizedBox(height: 10),

          pw.Text('II. DECLARA EL ARRENDATARIO:', style: subtitleStyle),
          pw.SizedBox(height: 4),
          pw.Text(
            'a) Que tiene las facultades suficientes y bastantes para obligarse en términos del presente Contrato, '
            'así como los recursos suficientes para cumplir con las obligaciones derivadas del mismo, los cuales '
            'obtiene de actividades lícitas.\n'
            'b) Que es su deseo tomar en arrendamiento el Inmueble, el cual conoce y reconoce que se encuentra en '
            'las condiciones necesarias de seguridad, higiene y salubridad para ser habitado.',
            style: bodyStyle,
            textAlign: pw.TextAlign.justify,
          ),
          pw.SizedBox(height: 10),

          pw.Text('III. DECLARA EL FIADOR:', style: subtitleStyle),
          pw.SizedBox(height: 4),
          pw.Text(
            'a) Que tiene las facultades suficientes y bastantes para obligarse en términos del presente Contrato.\n'
            'b) Ser propietario del inmueble que se describe en la escritura pública que se adjunta al presente como '
            'Anexo número 3, el cual, junto con el resto de su patrimonio, señala como garantía del cabal cumplimiento '
            'de sus obligaciones contraídas en el presente contrato.\n'
            'c) Que es su voluntad constituirse en fiador del Arrendatario en términos del presente Contrato.',
            style: bodyStyle,
            textAlign: pw.TextAlign.justify,
          ),
          pw.SizedBox(height: 10),

          pw.Text('IV. DECLARAN LAS PARTES:', style: subtitleStyle),
          pw.SizedBox(height: 4),
          pw.Text(
            'a) Que en el presente Contrato no existe dolo, error, mala fe o cualquier otro vicio de la voluntad, '
            'por lo que expresamente renuncian a invocarlos en cualquier tiempo.\n'
            'b) Que se reconocen la personalidad con la que comparecen a la celebración de este contrato y '
            'expresamente convienen en someterse a las obligaciones contenidas en las siguientes cláusulas.',
            style: bodyStyle,
            textAlign: pw.TextAlign.justify,
          ),
          pw.SizedBox(height: 16),

          // ── CLÁUSULAS ────────────────────────────────────────────────
          pw.Text('CLÁUSULAS', style: titleStyle),
          pw.SizedBox(height: 10),

          clausula(
            'PRIMERA. OBJETO.',
            'Sujeto a los plazos, términos y condiciones aquí acordadas, el Arrendador otorga en arrendamiento '
            'al Arrendatario, y éste toma en dicha calidad, el Inmueble ubicado en $inmuebleDireccion.',
          ),

          clausula(
            'SEGUNDA. RENTA.',
            'El Arrendatario pagará mensualmente al Arrendador o a quién sus derechos representen, por concepto '
            'de renta, la cantidad de $renta (Pesos, Moneda Nacional), sujeto a los siguientes términos:\n'
            'a) El pago de la renta será por meses adelantados, debiendo cubrirse íntegra la renta mensual.\n'
            'b) El pago se cubrirá en su totalidad dentro de los primeros diez días naturales de cada mes.\n'
            'c) Será causa de rescisión de este Contrato el hecho de que se pague extemporáneamente la renta.\n'
            'd) De no hacer el pago en tiempo y forma, se aplicará una pena convencional del 5% sobre el importe de la renta.\n'
            'e) Si el Arrendador recibe la renta en fecha y forma distinta, no se entenderá novado el Contrato.\n'
            'f) En caso de prórroga, la renta se incrementará conforme al INPC.',
          ),

          clausula(
            'TERCERA. DEPÓSITO EN GARANTÍA.',
            'A la fecha de firma del presente Contrato, el Arrendatario entrega al Arrendador por concepto de '
            'depósito en garantía la cantidad de $depositoTexto. '
            'El depósito no podrá utilizarse para compensar la falta de pago de rentas. '
            'El Arrendador devolverá el depósito dentro de los sesenta días posteriores a la entrega del Inmueble.',
          ),

          clausula(
            'CUARTA. VIGENCIA.',
            'La vigencia del presente Contrato es: $vigencia. '
            'El Arrendatario deberá avisar al Arrendador con al menos '
            'treinta días hábiles de anticipación su deseo de prorrogar o no el arrendamiento.',
          ),

          clausula(
            'QUINTA. USO DE SUELO.',
            'El inmueble será destinado únicamente para casa habitación, quedándole prohibido al Arrendatario '
            'cambiar el uso referido, siendo causa de rescisión el incumplimiento a esta disposición.',
          ),

          clausula(
            'SEXTA. SERVICIOS.',
            'El Arrendatario se obliga a cubrir oportunamente el importe de todos los servicios utilizados en '
            'el Inmueble, incluyendo energía eléctrica, agua potable, teléfono, gas y cuota de mantenimiento.',
          ),

          clausula(
            'SÉPTIMA. INMUEBLE.',
            'El Arrendatario reconoce que recibe el Inmueble en buen estado y se compromete a devolverlo con el '
            'deterioro natural de su uso. No podrá variar la forma del Inmueble sin consentimiento previo y por '
            'escrito del Arrendador.',
          ),

          clausula(
            'OCTAVA. CESIÓN DE DERECHOS.',
            'El Arrendatario no podrá subarrendar, traspasar o ceder sus derechos derivados de este Contrato. '
            'El Arrendador podrá ceder sus derechos mediante simple notificación por escrito.',
          ),

          clausula(
            'NOVENA. SUSTANCIAS PELIGROSAS.',
            'El Arrendatario se compromete a no almacenar sustancias peligrosas, inflamables, corrosivas, '
            'deletéreas o ilegales dentro del Inmueble.',
          ),

          clausula(
            'DÉCIMA. TERMINACIÓN ANTICIPADA.',
            'En caso de terminación anticipada, se pagará como pena convencional el importe de 2 meses de renta, '
            'debiendo desocupar el Inmueble en un plazo no mayor a diez días posteriores a dicho pago.',
          ),

          clausula(
            'DÉCIMA PRIMERA. FIADOR.',
            'Para garantizar el cumplimiento de las obligaciones del Arrendatario, el Fiador firma solidariamente, '
            'renunciando expresamente a sus beneficios de orden y excusión.',
          ),

          clausula(
            'DÉCIMA SEGUNDA. RESCISIÓN.',
            'La falsedad en las declaraciones y/o el incumplimiento de cualquiera de las obligaciones será motivo '
            'de rescisión sin necesidad de intervención judicial.',
          ),

          clausula(
            'DÉCIMA TERCERA. DOMICILIOS.',
            'a. El Arrendador: Domicilio fiscal de $arrendadorNombre.\n'
            'b. El Arrendatario: $inmuebleDireccion.',
          ),

          clausula(
            'DÉCIMA CUARTA. ACUERDO TOTAL.',
            'Este Contrato y todos sus Anexos constituyen la totalidad de los acuerdos celebrados entre las partes '
            'respecto al objeto del mismo.',
          ),

          clausula(
            'DÉCIMA QUINTA. LEYES APLICABLES.',
            'Para todo lo relacionado con la interpretación y ejecución con este instrumento son aplicables las '
            'leyes correspondientes y, en caso de controversia, serán competentes los tribunales de $ciudad.',
          ),

          pw.SizedBox(height: 30),

          // ── Firmas ───────────────────────────────────────────────────
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Column(
              children: [
                pw.Text('FIRMAS', style: subtitleStyle),
                pw.SizedBox(height: 24),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                  children: [
                    _firmaBloque('EL ARRENDADOR', arrendadorNombre),
                    _firmaBloque('EL ARRENDATARIO', arrendatario),
                  ],
                ),
                pw.SizedBox(height: 24),
                pw.Center(child: _firmaBloque('EL FIADOR', fiador)),
              ],
            ),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) => pdf.save(),
      name: 'Contrato_${arrendatario.replaceAll(' ', '_')}.pdf',
    );
  }

  /// Fila con etiqueta + valor.
  static pw.Widget _datoRow(
      String label, String value, pw.TextStyle labelSt, pw.TextStyle valueSt) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(width: 110, child: pw.Text(label, style: labelSt)),
          pw.Expanded(child: pw.Text(value, style: valueSt)),
        ],
      ),
    );
  }

  /// Bloque de firma con línea y nombre.
  static pw.Widget _firmaBloque(String rol, String nombre) {
    return pw.Column(
      children: [
        pw.Container(width: 160, height: 0.5, color: PdfColors.grey600),
        pw.SizedBox(height: 4),
        pw.Text(rol,
            style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: const PdfColor.fromInt(0xFF225378))),
        pw.SizedBox(height: 2),
        pw.Text(nombre,
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
      ],
    );
  }
}
