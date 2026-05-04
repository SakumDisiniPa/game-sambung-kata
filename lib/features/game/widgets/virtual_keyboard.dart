import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VirtualKeyboard extends StatefulWidget {
  final Function(String) onSubmit;
  final String currentPrefix;

  const VirtualKeyboard({
    super.key,
    required this.onSubmit,
    required this.currentPrefix,
  });

  @override
  State<VirtualKeyboard> createState() => _VirtualKeyboardState();
}

class _VirtualKeyboardState extends State<VirtualKeyboard> {
  String _currentWord = "";

  @override
  void didUpdateWidget(VirtualKeyboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset word jika prefix berubah (berarti sudah ganti giliran)
    if (oldWidget.currentPrefix != widget.currentPrefix) {
      _currentWord = "";
    }
  }

  void _addKey(String key) {
    setState(() {
      _currentWord += key;
    });
  }

  void _delete() {
    if (_currentWord.isNotEmpty) {
      setState(() {
        _currentWord = _currentWord.substring(0, _currentWord.length - 1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const rows = [
      ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'],
      ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L'],
      ['Z', 'X', 'C', 'V', 'B', 'N', 'M'],
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      decoration: const BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Tampilan Kata yang sedang diketik
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            margin: const EdgeInsets.only(bottom: 15),
            decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(15)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(widget.currentPrefix, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
                Text(_currentWord, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
          ),

          for (var row in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var key in row)
                    _buildKey(key, flex: 1),
                ],
              ),
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildSpecialKey(Icons.backspace, _delete, flex: 2),
              const SizedBox(width: 10),
              _buildSpecialKey(Icons.check_circle, () {
                widget.onSubmit(widget.currentPrefix + _currentWord);
                setState(() => _currentWord = "");
              }, flex: 3, color: Colors.cyanAccent),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildKey(String label, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: GestureDetector(
        onTap: () => _addKey(label),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white12,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white24),
          ),
          alignment: Alignment.center,
          child: Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildSpecialKey(IconData icon, VoidCallback onTap, {int flex = 1, Color? color}) {
    return Expanded(
      flex: flex,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            color: color?.withAlpha(51) ?? Colors.white10,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color ?? Colors.white24),
          ),
          child: Icon(icon, color: color ?? Colors.white),
        ),
      ),
    );
  }
}
