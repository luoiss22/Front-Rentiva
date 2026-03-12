import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─── Helpers compartidos para bottom sheets y formularios ─────────────────────

Widget adminHandle() => Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(2)),
      ),
    );

Widget adminSeccion(String t) => Text(t,
    style: const TextStyle(
        color: Color(0xFF225378),
        fontWeight: FontWeight.bold,
        fontSize: 14));

Widget adminFila(String label, String value) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: Colors.grey, fontSize: 12)),
          const SizedBox(width: 16),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.right,
                style: const TextStyle(
                    color: Color(0xFF225378),
                    fontWeight: FontWeight.w600,
                    fontSize: 12)),
          ),
        ],
      ),
    );

Widget adminChip(String label, Color bg, Color textColor) =>
    Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: textColor)),
    );

Widget adminFieldLabel(String label) => Text(label,
    style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: Color(0xFF225378)));

InputDecoration adminFieldDecoration(String hint, IconData icon) =>
    InputDecoration(
      hintText: hint,
      hintStyle:
          TextStyle(color: Colors.grey.shade400, fontSize: 13),
      prefixIcon:
          Icon(icon, color: const Color(0xFF1695A3), size: 18),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(
          vertical: 13, horizontal: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide:
            const BorderSide(color: Color(0xFF1695A3), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
    );

Widget adminSearchBar(
  TextEditingController ctrl,
  String hint,
  ValueChanged<String> onChanged, {
  required VoidCallback onClear,
  required bool showClear,
}) =>
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)
        ],
      ),
      child: Row(children: [
        const Icon(Icons.search, color: Colors.grey, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: ctrl,
            onChanged: onChanged,
            style:
                const TextStyle(fontSize: 13, color: Color(0xFF225378)),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle:
                  const TextStyle(color: Colors.grey, fontSize: 13),
              border: InputBorder.none,
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        if (showClear)
          GestureDetector(
              onTap: onClear,
              child:
                  const Icon(Icons.close, color: Colors.grey, size: 16)),
      ]),
    );

Widget adminEmptyState(String msg) => Center(
    child:
        Text(msg, style: const TextStyle(color: Colors.grey, fontSize: 14)));

Widget adminEspLabel(String t) => Text(t,
    style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: Color(0xFF225378)));

InputDecoration adminEspDeco(String hint, IconData icon) => InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
      prefixIcon: Icon(icon, color: const Color(0xFF1695A3), size: 18),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding:
          const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: Color(0xFF1695A3), width: 2)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red)),
      focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red, width: 2)),
    );

String adminFmtDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

Widget adminSectionTitle(IconData icon, String title) => Row(children: [
      Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
              color: const Color(0xFF1695A3),
              borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 8),
      Icon(icon, color: const Color(0xFF1695A3), size: 16),
      const SizedBox(width: 6),
      Text(title,
          style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF225378))),
    ]);

// ─── FORMATTER ────────────────────────────────────────────────────────────────
class UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
          TextEditingValue o, TextEditingValue n) =>
      n.copyWith(text: n.text.toUpperCase());
}
