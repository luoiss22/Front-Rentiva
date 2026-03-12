import 'package:flutter/material.dart';
import 'admin_models.dart';

// ─── TILE ADMIN ───────────────────────────────────────────────────────────────
class AdminTile extends StatelessWidget {
  final Admin admin;
  final VoidCallback onTap, onEdit, onDelete;

  const AdminTile({
    super.key,
    required this.admin,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  Color get _dot => admin.estado == 'activo'
      ? Colors.green
      : admin.estado == 'suspendido'
          ? Colors.orange
          : Colors.grey;

  @override
  Widget build(BuildContext context) => GestureDetector(
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
          child: Row(children: [
            // Gradient avatar
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: admin.activo
                      ? [const Color(0xFF225378), const Color(0xFF1695A3)]
                      : [Colors.grey.shade300, Colors.grey.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                  child: Text(admin.inicial,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18))),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(admin.nombreCompleto,
                      style: const TextStyle(
                          color: Color(0xFF225378),
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                  const SizedBox(height: 4),
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                          color: const Color(0xFFE8F4FD),
                          borderRadius: BorderRadius.circular(20)),
                      child: Text(admin.rol.toUpperCase(),
                          style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF225378))),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                        child: Text(admin.email,
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 10),
                            overflow: TextOverflow.ellipsis)),
                  ]),
                ])),
            Row(mainAxisSize: MainAxisSize.min, children: [
              Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                      color: _dot, shape: BoxShape.circle)),
              GestureDetector(
                  onTap: onEdit,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.edit_outlined,
                        color: Color(0xFFEB7F00), size: 16),
                  )),
              const SizedBox(width: 6),
              GestureDetector(
                  onTap: onDelete,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(10)),
                    child: Icon(Icons.delete_outline,
                        color: Colors.red.shade400, size: 16),
                  )),
            ]),
          ]),
        ),
      );
}
