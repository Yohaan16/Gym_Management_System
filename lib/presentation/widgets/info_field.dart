import 'package:flutter/material.dart';
import 'package:gms_mobile/core/constants/app_colors.dart';
import 'package:gms_mobile/core/constants/app_constants.dart';

/// Reusable info field widget for displaying profile/user information
class InfoField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool isEditing;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const InfoField({
    super.key,
    required this.label,
    required this.controller,
    required this.isEditing,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            fontSize: AppConstants.fontSmall,
          ),
        ),
        const SizedBox(height: 8),
        isEditing
            ? TextField(
                controller: controller,
                keyboardType: keyboardType,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusMedium),
                    borderSide: const BorderSide(color: AppColors.primaryBlue),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spacingMedium,
                    vertical: AppConstants.spacingSmall,
                  ),
                ),
              )
            : Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingMedium,
                  vertical: AppConstants.spacingSmall,
                ),
                decoration: BoxDecoration(
                  color: AppColors.bgGrey,
                  borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                ),
                child: Text(
                  controller.text,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: AppConstants.fontBase,
                  ),
                ),
              ),
        const SizedBox(height: 12),
      ],
    );
  }
}
