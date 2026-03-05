import 'package:flutter/material.dart';
import 'package:gms_mobile/presentation/widgets/gradient_button.dart';

/// A reusable centered dialog with nice typography and gradient primary button.
/// Use `showPopUpDialog` helper to display it.
class PopUpDialog extends StatelessWidget {
  final String title;
  final String message;
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  const PopUpDialog({
    super.key,
    required this.title,
    required this.message,
    required this.primaryLabel,
    this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            // Primary gradient button
            SizedBox(
              width: double.infinity,
              child: GradientButton(
                label: primaryLabel,
                onPressed: () {
                  Navigator.of(context).pop();
                  if (onPrimary != null) onPrimary!();
                },
              ),
            ),
            if (secondaryLabel != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    if (onSecondary != null) onSecondary!();
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: theme.colorScheme.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    secondaryLabel!,
                    style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}

/// Helper to show the PopUpDialog easily
Future<void> showPopUpDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String primaryLabel,
  VoidCallback? onPrimary,
  String? secondaryLabel,
  VoidCallback? onSecondary,
}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => PopUpDialog(
      title: title,
      message: message,
      primaryLabel: primaryLabel,
      onPrimary: onPrimary,
      secondaryLabel: secondaryLabel,
      onSecondary: onSecondary,
    ),
  );
}
