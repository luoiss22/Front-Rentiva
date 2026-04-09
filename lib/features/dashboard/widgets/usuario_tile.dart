import 'package:flutter/material.dart';
import 'admin_models.dart';
import '../../../core/services/api_client.dart';

// ─── TILE USUARIO ─────────────────────────────────────────────────────────────
class UsuarioTile extends StatelessWidget {
  final UsuarioAdmin usuario;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const UsuarioTile({
    super.key,
    required this.usuario,
    required this.onDelete,
    required this.onTap,
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
            // Avatar
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: usuario.activo
                    ? const Color(0xFFACF0F2)
                    : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: () {
                  final url = usuario.fotoUrl != null
                      ? ApiClient.resolveMediaUrl(usuario.fotoUrl)
                      : null;
                  if (url != null && url.isNotEmpty) {
                    return Image.network(
                      url,
                      width: 42, height: 42,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Center(
                        child: Text(usuario.inicial,
                            style: TextStyle(
                                color: usuario.activo
                                    ? const Color(0xFF1695A3)
                                    : Colors.grey,
                                fontWeight: FontWeight.bold,
                                fontSize: 17)),
                      ),
                    );
                  }
                  return Center(
                    child: Text(usuario.inicial,
                        style: TextStyle(
                            color: usuario.activo
                                ? const Color(0xFF1695A3)
                                : Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 17)),
                  );
                }(),
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(usuario.nombreCompleto,
                      style: const TextStyle(
                          color: Color(0xFF225378),
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFACF0F2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          usuario.rol.toUpperCase(),
                          style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1695A3)),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(usuario.propiedad,
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),

            // Estado dot + eliminar
            Row(
              children: [
                Container(
                  width: 8, height: 8,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: usuario.activo
                        ? Colors.green
                        : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
                GestureDetector(
                  onTap: onDelete,
                  child: Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.delete_outline,
                        color: Colors.red.shade400, size: 18),
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
