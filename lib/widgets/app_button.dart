import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Reusable primary button widget with loading state support.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.variant = AppButtonVariant.primary,
    this.fullWidth = true,
  });

  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final AppButtonVariant variant;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final button = ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: _getButtonStyle(variant),
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20),
                  const SizedBox(width: AppTheme.spacingS),
                ],
                Text(text),
              ],
            ),
    );

    if (fullWidth) {
      return SizedBox(
        width: double.infinity,
        height: 48,
        child: button,
      );
    }

    return button;
  }

  ButtonStyle _getButtonStyle(AppButtonVariant variant) {
    switch (variant) {
      case AppButtonVariant.primary:
        return ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
        );
      case AppButtonVariant.secondary:
        return ElevatedButton.styleFrom(
          backgroundColor: AppTheme.secondaryColor,
          foregroundColor: Colors.white,
        );
      case AppButtonVariant.success:
        return ElevatedButton.styleFrom(
          backgroundColor: AppTheme.success,
          foregroundColor: Colors.white,
        );
      case AppButtonVariant.error:
        return ElevatedButton.styleFrom(
          backgroundColor: AppTheme.error,
          foregroundColor: Colors.white,
        );
      case AppButtonVariant.outline:
        return ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: AppTheme.primaryColor,
          elevation: 0,
          side: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
        );
    }
  }
}

enum AppButtonVariant {
  primary,
  secondary,
  success,
  error,
  outline,
}








