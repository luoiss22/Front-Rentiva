import 'package:flutter/material.dart';

// ─── BOTÓN DE ACCIÓN ──────────────────────────────────────────────────────────
class PagoActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool primary;
  final VoidCallback onTap;

  const PagoActionBtn({
    super.key,
    required this.icon,
    required this.label,
    required this.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: primary ? const Color(0xFF1695A3) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: primary
              ? null
              : Border.all(color: const Color(0xFF225378)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05), blurRadius: 6),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                color: primary
                    ? Colors.white
                    : const Color(0xFF225378),
                size: 18),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    color: primary
                        ? Colors.white
                        : const Color(0xFF225378),
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
