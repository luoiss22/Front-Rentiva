import 'pago_models.dart';

// ─── DATOS EJEMPLO ────────────────────────────────────────────────────────────
final List<Pago> pagosEjemplo = [
  Pago(
    id: 1, periodo: 'Mayo 2023', monto: 12500,
    fechaLimite: DateTime(2023, 5, 5),
    fechaPago: DateTime(2023, 5, 1),
    metodoPago: MetodoPago.transferencia,
    referencia: 'TRF-001', recargaMora: 0,
    estado: PagoEstado.pagado,
    createdAt: DateTime(2023, 4, 25),
    inquilinoNombre: 'Juan Pérez',
    factura: Factura(
      id: 1, folioFiscal: 'A1B2C3D4-...', subtotal: 10776.0,
      iva: 1724.0, total: 12500.0, fechaEmision: DateTime(2023, 5, 1),
    ),
  ),
  Pago(
    id: 2, periodo: 'Abril 2023', monto: 8200,
    fechaLimite: DateTime(2023, 4, 5),
    metodoPago: null, referencia: '', recargaMora: 0,
    estado: PagoEstado.pendiente,
    createdAt: DateTime(2023, 3, 25),
    inquilinoNombre: 'Maria González',
    ficha: FichaPago(
      id: 1, codigoReferencia: 'REF-20230401',
      clabeInterbancaria: '012345678901234567',
      banco: 'BBVA', fechaGeneracion: DateTime(2023, 3, 28),
    ),
  ),
  Pago(
    id: 3, periodo: 'Marzo 2023', monto: 15000,
    fechaLimite: DateTime(2023, 3, 5),
    metodoPago: null, referencia: '', recargaMora: 750,
    estado: PagoEstado.vencido,
    createdAt: DateTime(2023, 2, 25),
    inquilinoNombre: 'Carlos Ruiz',
  ),
  Pago(
    id: 4, periodo: 'Febrero 2023', monto: 12500,
    fechaLimite: DateTime(2023, 2, 5),
    fechaPago: DateTime(2023, 2, 3),
    metodoPago: MetodoPago.efectivo,
    referencia: 'EFT-002', recargaMora: 0,
    estado: PagoEstado.pagado,
    createdAt: DateTime(2023, 1, 25),
    inquilinoNombre: 'Juan Pérez',
  ),
];
