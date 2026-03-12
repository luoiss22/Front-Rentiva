import 'package:flutter/material.dart';
import 'admin_models.dart';

// ─── TILE ESPECIALISTA ────────────────────────────────────────────────────────
class EspecialistaTile extends StatelessWidget {
  final Especialista especialista;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const EspecialistaTile({
    super.key,
    required this.especialista,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
        child: Row(
          children: [
            // Avatar inicial + disponible indicator
            Stack(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle),
                  child: Center(
                    child: Text(
                      especialista.inicial,
                      style: const TextStyle(
                          color: Color(0xFF225378),
                          fontWeight: FontWeight.bold,
                          fontSize: 18),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(especialista.nombre,
                      style: const TextStyle(
                          color: Color(0xFF225378),
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(especialista.especialidad,
                      style: const TextStyle(
                          color: Color(0xFF1695A3),
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star,
                          color: Color(0xFFEB7F00), size: 12),
                      const SizedBox(width: 3),
                      Text(
                        especialista.calificacion.toStringAsFixed(1),
                        style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 11,
                            fontWeight: FontWeight.w600),
                      ),
                      const Text(' · ',
                          style: TextStyle(
                              color: Colors.grey, fontSize: 11)),
                      const Icon(Icons.phone_outlined,
                          color: Colors.grey, size: 11),
                      const SizedBox(width: 2),
                      Text(especialista.telefono,
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),

            // Acciones editar / eliminar
            if (onEdit != null || onDelete != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onEdit != null)
                    GestureDetector(
                      onTap: onEdit,
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEB7F00).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.edit_outlined,
                            size: 16, color: Color(0xFFEB7F00)),
                      ),
                    ),
                  if (onEdit != null && onDelete != null)
                    const SizedBox(width: 6),
                  if (onDelete != null)
                    GestureDetector(
                      onTap: onDelete,
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.delete_outline,
                            size: 16, color: Colors.red.shade400),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
