import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LoadingStateWidget extends StatelessWidget {
  const LoadingStateWidget({super.key});

  @override
  Widget build(BuildContext _) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(color: Colors.cyanAccent),
        const SizedBox(height: 20),
        Text(
          "MEMPROSES KAMUS DEWA...",
          style: GoogleFonts.outfit(color: Colors.cyanAccent, letterSpacing: 2),
        ),
        const Text(
          "Tunggu sebentar, arena sedang disiapkan",
          style: TextStyle(fontSize: 12, color: Colors.white54),
        ),
      ],
    );
  }
}
