import 'package:flutter/material.dart';
import 'package:gms_mobile/core/constants/app_colors.dart';
import 'package:gms_mobile/core/constants/app_constants.dart';

/// Custom gradient card widget for consistent card styling
class GradientCard extends StatelessWidget {
  final List<Color> gradientColors;
  final Widget child;
  final double borderWidth;
  final double borderRadius;
  final BoxShadow? shadow;

  const GradientCard({
    super.key,
    required this.gradientColors,
    required this.child,
    this.borderWidth = 2,
    this.borderRadius = AppConstants.radiusBase,
    this.shadow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: gradientColors[0],
          width: borderWidth,
        ),
        color: AppColors.bgWhite,
        boxShadow: shadow != null ? [shadow!] : [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}
