import 'package:flutter/material.dart';

class PlayerCard extends StatelessWidget {
  final String name;
  final int chances;
  final bool isEliminated;
  final bool isActive;

  const PlayerCard({
    super.key,
    required this.name,
    required this.chances,
    required this.isEliminated,
    required this.isActive,
  });

  @override
  Widget build(BuildContext _) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.cyanAccent.withAlpha(40)
            : Colors.white.withAlpha(10),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isActive
              ? Colors.cyanAccent
              : (isEliminated
                    ? Colors.redAccent.withAlpha(100)
                    : Colors.white10),
          width: 2,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: Colors.cyanAccent.withAlpha(50),
                  blurRadius: 10,
                ),
              ]
            : [],
      ),
      child: Column(
        children: [
          Icon(
            Icons.person,
            color: isEliminated
                ? Colors.white24
                : (isActive ? Colors.cyanAccent : Colors.white70),
          ),
          const SizedBox(height: 5),
          Text(
            name,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isEliminated ? Colors.white24 : Colors.white,
            ),
          ),
          const SizedBox(height: 5),
          Row(
            children: List.generate(
              4,
              (i) => Icon(
                Icons.favorite,
                size: 12,
                color: i < chances ? Colors.redAccent : Colors.white10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
