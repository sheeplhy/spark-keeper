import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

enum StatusTone { success, warning, danger, neutral }

class StatusPill extends StatelessWidget {
  const StatusPill({
    required this.label,
    required this.icon,
    this.tone = StatusTone.neutral,
    super.key,
  });

  final String label;
  final IconData icon;
  final StatusTone tone;

  Color get _color => switch (tone) {
    StatusTone.success => AppColors.primary,
    StatusTone.warning => AppColors.warning,
    StatusTone.danger => AppColors.danger,
    StatusTone.neutral => AppColors.muted,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: _color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: _color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
