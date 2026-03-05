import 'package:flutter/material.dart';
import 'package:gms_mobile/core/constants/app_colors.dart';

/// Reusable gradient button widget
class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final double? width;
  final double height;
  final bool isLoading;

  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.width,
    this.height = 50,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: AppColors.gradientBluePink),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextButton(
        onPressed: isLoading ? null : onPressed,
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: isLoading
            ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
            : Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}