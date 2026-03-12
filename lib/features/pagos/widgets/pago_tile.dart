import 'package:flutter/material.dart';
import 'pago_models.dart';

// ─── TILE DE PAGO ─────────────────────────────────────────────────────────────
class PagoTile extends StatelessWidget {
  final Pago pago;
  final bool isLast;
  final VoidCallback onTap;

  const PagoTile({
    super.key,
    required this.pago,
    required this.isLast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(
                  bottom: BorderSide(color: Colors.grey.shade100)),
        ),
        child: Row(
          children: [
            // Ícono estado
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: pago.estado.bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(pago.estado.icon,
                  color: pago.estado.textColor, size: 18),
            ),
            const SizedBox(width: 14),

            // Info
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
                  Row(
                    children: [
                      Text(pago.periodo,
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 11)),
                      const Text(' · ',
                          style: TextStyle(
                              color: Colors.grey, fontSize: 11)),
                      Text('Límite: ${pago.fechaLimiteFormateada}',
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 11)),
                    ],
                  ),
                  if (pago.factura != null || pago.ficha != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          if (pago.factura != null)
                            _miniChip('Facturado',
                                const Color(0xFFEFF6FF),
                                Colors.blue.shade600),
                          if (pago.factura != null && pago.ficha != null)
                            const SizedBox(width: 4),
                          if (pago.ficha != null)
                            _miniChip('Ficha generada',
                                const Color(0xFFF3FFE2),
                                Colors.green.shade600),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Monto + estado
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(pago.montoFormateado,
                    style: TextStyle(
                        color: pago.estado == PagoEstado.pagado
                            ? const Color(0xFF225378)
                            : Colors.grey.shade600,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: pago.estado.bgColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(pago.estado.label,
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: pago.estado.textColor)),
                ),
                if (pago.recargaMora > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '+${_fmtMora(pago.recargaMora)} mora',
                      style: const TextStyle(
                          color: Color(0xFFBE123C),
                          fontSize: 9),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _fmtMora(double v) =>
      '\$${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';

  static Widget _miniChip(String label, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label,
          style: TextStyle(
              fontSize: 9, fontWeight: FontWeight.bold, color: text)),
    );
  }
}
