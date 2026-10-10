import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

class SparkLogo extends StatelessWidget {
  const SparkLogo({super.key, this.size = 42});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.3),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.secondary],
        ),
      ),
      child: Icon(
        Icons.local_fire_department_rounded,
        color: AppColors.background,
        size: size * 0.68,
      ),
    );
  }
}
