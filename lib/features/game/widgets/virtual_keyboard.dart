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

    return Container(
      padding: const EdgeInsets.only(bottom: 25, top: 10, left: 4, right: 4),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(220),
        border: Border(top: BorderSide(color: Colors.cyanAccent.withAlpha(40), width: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: Q-P (10 keys)
          _buildKeyRow(['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P']),
          const SizedBox(height: 6),
          // Row 2: A-L + DEL (10 keys)
          _buildKeyRow(['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L', 'DEL']),
          const SizedBox(height: 6),
          // Row 3: Z-M + SUBMIT (7 + 1 keys = 10 units)
          _buildKeyRow(['Z', 'X', 'C', 'V', 'B', 'N', 'M', 'SUBMIT']),
        ],
      ),
    );
  }

  Widget _buildKeyRow(List<String> keys) {
    return Row(
      children: [
        for (var key in keys)
          if (key == 'DEL')
            _buildSpecialKey("", Icons.backspace_outlined, onBackspace, flex: 1, color: Colors.redAccent)
          else if (key == 'SUBMIT')
            _buildSpecialKey("SUBMIT", Icons.send_rounded, onSubmit, flex: 3, color: Colors.cyanAccent)
          else
            _buildLetterKey(key, () => onKeyTap(key)),
      ],
    );
  }

  Widget _buildLetterKey(String label, VoidCallback onTap) {
    return Expanded(
      flex: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(6),
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(25),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                label,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 19,
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
            borderRadius: BorderRadius.circular(6),
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: color?.withAlpha(45) ?? Colors.white12,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: color?.withAlpha(120) ?? Colors.white24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: color ?? Colors.white, size: 20),
                  if (label.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: GoogleFonts.outfit(
                        color: color ?? Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

