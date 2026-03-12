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

  const Factura({
    required this.id,
    required this.folioFiscal,
    required this.subtotal,
    required this.iva,
    required this.total,
    this.xmlPath,
    this.pdfPath,
    required this.fechaEmision,
  });
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
  final FichaPago? ficha;
  final Factura? factura;

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
    this.ficha,
    this.factura,
  });

  Pago copyWith({
    PagoEstado? estado,
    DateTime? fechaPago,
    MetodoPago? metodoPago,
    String? referencia,
    String? comprobanteUrl,
    double? recargaMora,
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
      ficha: ficha,
      factura: factura,
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
