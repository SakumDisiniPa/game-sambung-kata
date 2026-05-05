import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VirtualKeyboard extends StatelessWidget {
  final Function(String) onKeyTap;
  final VoidCallback onBackspace;
  final VoidCallback onSubmit;

  const VirtualKeyboard({
    super.key,
    required this.onKeyTap,
    required this.onBackspace,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    // Jangan munculkan di Desktop (kecuali Web untuk simulasi)
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      return const SizedBox.shrink();
    }

    const rows = [
      ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'],
      ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L'],
      ['Z', 'X', 'C', 'V', 'B', 'N', 'M'],
    ];

    return Container(
      padding: const EdgeInsets.only(bottom: 20, top: 10, left: 5, right: 5),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(200),
        border: Border(top: BorderSide(color: Colors.cyanAccent.withAlpha(50))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var row in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var key in row)
                    _buildKey(key, () => onKeyTap(key)),
                ],
              ),
            ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSpecialKey("DEL", Icons.backspace_outlined, onBackspace, flex: 2, color: Colors.redAccent),
              const SizedBox(width: 8),
              _buildSpecialKey("SUBMIT", Icons.send_rounded, onSubmit, flex: 3, color: Colors.cyanAccent),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildKey(String label, VoidCallback onTap) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(6),
            child: Container(
              height: 45,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(20),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white10),
              ),
              alignment: Alignment.center,
              child: Text(
                label,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpecialKey(String label, IconData icon, VoidCallback onTap, {int flex = 1, Color? color}) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: color?.withAlpha(40) ?? Colors.white12,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color?.withAlpha(150) ?? Colors.white24),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: color ?? Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: GoogleFonts.outfit(
                      color: color ?? Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

