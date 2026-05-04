import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LobbyHeader extends StatelessWidget {
  final bool isMuted;
  final VoidCallback onMuteToggle;
  final String userName;

  const LobbyHeader({
    super.key,
    required this.isMuted,
    required this.onMuteToggle,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Sound Toggle (Left)
            _buildHeaderButton(
              onPressed: onMuteToggle,
              icon: isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
            ),
            // Profile Section (Right)
            _buildProfileHeader(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderButton({required VoidCallback onPressed, required IconData icon}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withAlpha(30)),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.cyanAccent, size: 22),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            userName.isEmpty ? "Pemain" : userName,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 10),
          CircleAvatar(
            radius: 14,
            backgroundColor: Colors.cyanAccent.withAlpha(50),
            child: const Icon(Icons.person, size: 18, color: Colors.cyanAccent),
          ),
        ],
      ),
    );
  }
}
