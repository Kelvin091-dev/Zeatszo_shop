import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A selector card widget for the dashboard top navigation.
///
/// Acts as a "tab-like" button that can be active or inactive.
/// Used to switch between different content screens in the dashboard.
class DashboardSelectorCard extends StatelessWidget {
  const DashboardSelectorCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.isActive,
    required this.onTap,
    this.iconColor,
    this.isLoading = false,
  });

  final String title;
  final String value;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;
  final Color? iconColor;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = iconColor ?? AppTheme.primaryColor;
    
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingM,
            vertical: AppTheme.spacingM,
          ),
          decoration: BoxDecoration(
            color: isActive 
                ? AppTheme.primaryColor 
                : AppTheme.secondaryBackground,
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
            border: Border.all(
              color: isActive 
                  ? AppTheme.primaryColor 
                  : AppTheme.alternateColor,
              width: isActive ? 2 : 1,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon with background
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingS),
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.white.withOpacity(0.2)
                      : effectiveIconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                ),
                child: Icon(
                  icon,
                  color: isActive ? Colors.white : effectiveIconColor,
                  size: 20,
                ),
              ),
              const SizedBox(height: AppTheme.spacingS),
              
              // Value
              if (isLoading)
                SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isActive ? Colors.white : AppTheme.primaryColor,
                    ),
                  ),
                )
              else
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isActive ? Colors.white : AppTheme.primaryText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 2),
              
              // Title
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isActive 
                      ? Colors.white.withOpacity(0.9) 
                      : AppTheme.secondaryText,
                  fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

