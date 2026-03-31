import 'package:flutter/material.dart';

// ─── ENUMS según Django ───────────────────────────────────────────────────────
enum PagoEstado { pendiente, pagado, vencido, parcial, cancelado }
enum MetodoPago { transferencia, efectivo, deposito, tarjeta, otro }

extension PagoEstadoExt on PagoEstado {
  String get label {
    switch (this) {
      case PagoEstado.pendiente:  return 'Pendiente';
      case PagoEstado.pagado:     return 'Pagado';
      case PagoEstado.vencido:    return 'Vencido';
      case PagoEstado.parcial:    return 'Parcial';
      case PagoEstado.cancelado:  return 'Cancelado';
    }
  }

  Color get bgColor {
    switch (this) {
      case PagoEstado.pagado:     return const Color(0xFFDCFCE7);
      case PagoEstado.pendiente:  return const Color(0xFFFEF9C3);
      case PagoEstado.vencido:    return const Color(0xFFFFE4E6);
      case PagoEstado.parcial:    return const Color(0xFFFFEDD5);
      case PagoEstado.cancelado:  return const Color(0xFFF1F5F9);
    }
  }

  Color get textColor {
    switch (this) {
      case PagoEstado.pagado:     return const Color(0xFF15803D);
      case PagoEstado.pendiente:  return const Color(0xFFA16207);
      case PagoEstado.vencido:    return const Color(0xFFBE123C);
      case PagoEstado.parcial:    return const Color(0xFFEA580C);
      case PagoEstado.cancelado:  return Colors.grey;
    }
  }

  IconData get icon {
    switch (this) {
      case PagoEstado.pagado:     return Icons.check_circle_outline;
      case PagoEstado.pendiente:  return Icons.schedule_outlined;
      case PagoEstado.vencido:    return Icons.warning_amber_outlined;
      case PagoEstado.parcial:    return Icons.incomplete_circle_outlined;
      case PagoEstado.cancelado:  return Icons.cancel_outlined;
    }
  }
}

// ─── MODELOS según Django ─────────────────────────────────────────────────────
class FichaPago {
  final int id;
  final String codigoReferencia;
  final String clabeInterbancaria;
  final String banco;
  final String? archivoPdfUrl;
  final DateTime fechaGeneracion;

  const FichaPago({
    required this.id,
    required this.codigoReferencia,
    required this.clabeInterbancaria,
    required this.banco,
    this.archivoPdfUrl,
    required this.fechaGeneracion,
  });

  factory FichaPago.fromJson(Map<String, dynamic> json) {
    return FichaPago(
      id: json['id'] as int,
      codigoReferencia: json['codigo_referencia'] ?? '',
      clabeInterbancaria: json['clabe_interbancaria'] ?? '',
      banco: json['banco'] ?? '',
      archivoPdfUrl: json['archivo_pdf'] as String?,
      fechaGeneracion: DateTime.tryParse(json['fecha_generacion'] ?? '') ?? DateTime.now(),
    );
  }
}

class DatosFiscales {
  final int id;
  final String tipoEntidad;
  final String nombreORazonSocial;
  final String rfc;
  final String regimenFiscal;
  final String usoCfdi;
  final String codigoPostal;

  const DatosFiscales({
    required this.id,
    required this.tipoEntidad,
    required this.nombreORazonSocial,
    required this.rfc,
    required this.regimenFiscal,
    required this.usoCfdi,
    required this.codigoPostal,
  });

  factory DatosFiscales.fromJson(Map<String, dynamic> json) {
    return DatosFiscales(
      id: json['id'] as int,
      tipoEntidad: json['tipo_entidad'] ?? '',
      nombreORazonSocial: json['nombre_o_razon_social'] ?? '',
      rfc: json['rfc'] ?? '',
      regimenFiscal: json['regimen_fiscal'] ?? '',
      usoCfdi: json['uso_cfdi'] ?? '',
      codigoPostal: json['codigo_postal'] ?? '',
    );
  }
}

class Factura {
  final int id;
  final String folioFiscal;
  final double subtotal;
  final double iva;
  final double total;
  final String? xmlPath;
  final String? pdfPath;
  final DateTime fechaEmision;
  final DatosFiscales? emisorDetalles;
  final DatosFiscales? receptorDetalles;

  const Factura({
    required this.id,
    required this.folioFiscal,
    required this.subtotal,
    required this.iva,
    required this.total,
    this.xmlPath,
    this.pdfPath,
    required this.fechaEmision,
    this.emisorDetalles,
    this.receptorDetalles,
  });

  factory Factura.fromJson(Map<String, dynamic> json) {
    return Factura(
      id: json['id'] as int,
      folioFiscal: json['folio_fiscal'] ?? '',
      subtotal: double.tryParse(json['subtotal'].toString()) ?? 0,
      iva: double.tryParse(json['iva'].toString()) ?? 0,
      total: double.tryParse(json['total'].toString()) ?? 0,
      xmlPath: json['xml_path'] as String?,
      pdfPath: json['pdf_path'] as String?,
      fechaEmision: DateTime.tryParse(json['fecha_emision'] ?? '') ?? DateTime.now(),
      emisorDetalles: json['emisor_detalles'] != null ? DatosFiscales.fromJson(json['emisor_detalles']) : null,
      receptorDetalles: json['receptor_detalles'] != null ? DatosFiscales.fromJson(json['receptor_detalles']) : null,
    );
  }
}

class Pago {
  final int id;
  final String periodo;
  final double monto;
  final DateTime fechaLimite;
  final DateTime? fechaPago;
  final MetodoPago? metodoPago;
  final String referencia;
  final String? comprobanteUrl;
  final double recargaMora;
  final PagoEstado estado;
  final DateTime createdAt;
  final String inquilinoNombre;
  final String propietarioNombre;
  final String propietarioBanco;
  final String propietarioClabe;
  final FichaPago? ficha;
  final Factura? factura;
  final List<String> datosFiscalesFaltantes;

  const Pago({
    required this.id,
    required this.periodo,
    required this.monto,
    required this.fechaLimite,
    this.fechaPago,
    this.metodoPago,
    required this.referencia,
    this.comprobanteUrl,
    required this.recargaMora,
    required this.estado,
    required this.createdAt,
    required this.inquilinoNombre,
    required this.propietarioNombre,
    this.propietarioBanco = '',
    this.propietarioClabe = '',
    this.ficha,
    this.factura,
    this.datosFiscalesFaltantes = const [],
  });

  factory Pago.fromJson(Map<String, dynamic> json) {
    return Pago(
      id: json['id'] as int,
      periodo: json['periodo'] ?? '',
      monto: double.tryParse(json['monto'].toString()) ?? 0,
      fechaLimite: DateTime.tryParse(json['fecha_limite'] ?? '') ?? DateTime.now(),
      fechaPago: json['fecha_pago'] != null ? DateTime.tryParse(json['fecha_pago']) : null,
      metodoPago: _parseMetodo(json['metodo_pago']),
      referencia: json['referencia'] ?? '',
      comprobanteUrl: json['comprobante_url'] as String?,
      recargaMora: double.tryParse(json['recargo_mora'].toString()) ?? 0,
      estado: _parseEstado(json['estado']),
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      inquilinoNombre: json['inquilino_nombre'] ?? 'Sin nombre',
      propietarioNombre: json['propietario_nombre'] ?? 'Propietario no registrado',
      propietarioBanco: json['propietario_banco'] ?? '',
      propietarioClabe: json['propietario_clabe'] ?? '',
      ficha: json['ficha'] != null ? FichaPago.fromJson(json['ficha']) : null,
      factura: json['factura'] != null ? Factura.fromJson(json['factura']) : null,
      datosFiscalesFaltantes: List<String>.from(json['datos_fiscales_faltantes'] ?? []),
    );
  }

  static PagoEstado _parseEstado(String? val) {
    switch (val) {
      case 'pagado':    return PagoEstado.pagado;
      case 'pendiente': return PagoEstado.pendiente;
      case 'vencido':   return PagoEstado.vencido;
      case 'parcial':   return PagoEstado.parcial;
      case 'cancelado': return PagoEstado.cancelado;
      default:          return PagoEstado.pendiente;
    }
  }

  static MetodoPago? _parseMetodo(String? val) {
    switch (val) {
      case 'transferencia': return MetodoPago.transferencia;
      case 'efectivo':      return MetodoPago.efectivo;
      case 'deposito':      return MetodoPago.deposito;
      case 'tarjeta':       return MetodoPago.tarjeta;
      case 'otro':          return MetodoPago.otro;
      default:              return null;
    }
  }

  Pago copyWith({
    PagoEstado? estado,
    DateTime? fechaPago,
    MetodoPago? metodoPago,
    String? referencia,
    String? comprobanteUrl,
    double? recargaMora,
    List<String>? datosFiscalesFaltantes,
  }) {
    return Pago(
      id: id,
      periodo: periodo,
      monto: monto,
      fechaLimite: fechaLimite,
      fechaPago: fechaPago ?? this.fechaPago,
      metodoPago: metodoPago ?? this.metodoPago,
      referencia: referencia ?? this.referencia,
      comprobanteUrl: comprobanteUrl ?? this.comprobanteUrl,
      recargaMora: recargaMora ?? this.recargaMora,
      estado: estado ?? this.estado,
      createdAt: createdAt,
      inquilinoNombre: inquilinoNombre,
      propietarioNombre: propietarioNombre,
      propietarioBanco: propietarioBanco,
      propietarioClabe: propietarioClabe,
      ficha: ficha,
      factura: factura,
      datosFiscalesFaltantes: datosFiscalesFaltantes ?? this.datosFiscalesFaltantes,
    );
  }

  String get montoFormateado {
    final n = monto + recargaMora;
    return '\$${n.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
  }

  String get fechaLimiteFormateada =>
      '${fechaLimite.day.toString().padLeft(2, '0')}/'
      '${fechaLimite.month.toString().padLeft(2, '0')}/'
      '${fechaLimite.year}';
}
