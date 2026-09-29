import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final Color? color;

  const StatusBadge({
    super.key,
    required this.status,
    this.color,
  });

  Color _getColor() {
    if (color != null) return color!;
    final upperStatus = status.toUpperCase();
    if (upperStatus == 'ON_TRACK' || upperStatus == 'RESOLVED') {
      return const Color(0xFF4EDEA3); // Tertiary/Green
    } else if (upperStatus == 'AT_RISK') {
      return const Color(0xFFFFB95F); // Secondary/Amber
    } else if (upperStatus == 'DELAYED' || upperStatus == 'OPEN') {
      return Colors.red;
    } else if (upperStatus == 'PLANNING') {
      return const Color(0xFF38BDF8); // PrimaryLight
    }
    return const Color(0xFF94A3B8); // TextSecondary
  }

  String _formatStatus() {
    return status.replaceAll('_', ' ').toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final badgeColor = _getColor();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withAlpha(26),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: badgeColor.withAlpha(128)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: badgeColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            _formatStatus(),
            style: TextStyle(
              color: badgeColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
