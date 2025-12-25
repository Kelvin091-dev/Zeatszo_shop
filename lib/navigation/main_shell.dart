import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../dashboard/dashboard_home.dart';
import '../pricing/chicken_pricing_screen.dart';
import '../profile/shop_profile_screen.dart';
import '../services/onboarding_service.dart';
import '../theme/app_theme.dart';

/// Enum for bottom navigation tab selection.
enum MainTab {
  home,
  pricing,
  profile,
}

/// Main navigation shell that holds the BottomNavigationBar.
///
/// This is the root widget for the authenticated app state.
/// Uses IndexedStack to preserve state of each tab when switching.
///
/// Supports onboarding flow:
/// - Can be initialized with a specific tab (for onboarding)
/// - Can restrict tab switching during onboarding
/// - Provides callbacks for onboarding step completion
///
/// Tabs:
/// - Home: DashboardHome (manages its own internal screens)
/// - Pricing: ChickenPricingScreen (set price & stock)
/// - Profile: ShopProfileScreen (edit shop details + logout)
class MainShell extends StatefulWidget {
  const MainShell({
    super.key,
    this.initialTab = MainTab.home,
    this.isOnboarding = false,
    this.onboardingStatus,
    this.onOnboardingStepCompleted,
  });

  /// Initial tab to display (used for onboarding flow)
  final MainTab initialTab;

  /// Whether the user is currently in onboarding mode
  final bool isOnboarding;

  /// Current onboarding status (used to restrict navigation)
  final OnboardingStatus? onboardingStatus;

  /// Callback when an onboarding step is completed
  /// This triggers OnboardingGate to refresh and route to the next step
  final VoidCallback? onOnboardingStepCompleted;

  @override
  State<MainShell> createState() => MainShellState();
}

class MainShellState extends State<MainShell> {
  /// Currently selected tab
  late MainTab _currentTab;

  /// Shop ID derived from current user's UID
  String get _shopId => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _currentTab = widget.initialTab;
  }

  @override
  void didUpdateWidget(MainShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If onboarding status changes, update the tab
    if (widget.initialTab != oldWidget.initialTab && widget.isOnboarding) {
      setState(() {
        _currentTab = widget.initialTab;
      });
    }
  }

  /// Navigates to the next onboarding step
  void _navigateToNextOnboardingStep() {
    final status = widget.onboardingStatus;
    if (status == null) return;

    switch (status.nextStep) {
      case OnboardingStep.profile:
        _selectTab(MainTab.profile, forceAllow: true);
        break;
      case OnboardingStep.pricing:
        _selectTab(MainTab.pricing, forceAllow: true);
        break;
      case OnboardingStep.completed:
        _selectTab(MainTab.home, forceAllow: true);
        break;
      case OnboardingStep.login:
        // Should not happen here
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ════════════════════════════════════════════════════════════════════════
      // BODY: IndexedStack preserves state of all tabs
      // ════════════════════════════════════════════════════════════════════════
      body: IndexedStack(
        index: _currentTab.index,
        children: [
          // Tab 0: Home - DashboardHome
          const DashboardHome(),

          // Tab 1: Pricing - ChickenPricingScreen with onboarding callback
          ChickenPricingScreen(
            shopId: _shopId,
            onSaveComplete: widget.isOnboarding ? _onPricingSaved : null,
          ),

          // Tab 2: Profile - ShopProfileScreen with onboarding callback
          ShopProfileScreen(
            shopId: _shopId,
            onSaveComplete: widget.isOnboarding ? _onProfileSaved : null,
          ),
        ],
      ),

      // ════════════════════════════════════════════════════════════════════════
      // BOTTOM NAVIGATION BAR
      // ════════════════════════════════════════════════════════════════════════
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.secondaryBackground,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingS,
              vertical: AppTheme.spacingS,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavBarItem(
                  icon: Icons.dashboard_rounded,
                  label: 'Home',
                  isActive: _currentTab == MainTab.home,
                  isEnabled: _isTabEnabled(MainTab.home),
                  onTap: () => _selectTab(MainTab.home),
                ),
                _NavBarItem(
                  icon: Icons.price_change_rounded,
                  label: 'Pricing',
                  isActive: _currentTab == MainTab.pricing,
                  isEnabled: _isTabEnabled(MainTab.pricing),
                  onTap: () => _selectTab(MainTab.pricing),
                ),
                _NavBarItem(
                  icon: Icons.store_rounded,
                  label: 'Profile',
                  isActive: _currentTab == MainTab.profile,
                  isEnabled: _isTabEnabled(MainTab.profile),
                  onTap: () => _selectTab(MainTab.profile),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Checks if a tab is enabled based on onboarding status
  bool _isTabEnabled(MainTab tab) {
    // If not onboarding, all tabs are enabled
    if (!widget.isOnboarding) return true;

    final status = widget.onboardingStatus;
    if (status == null) return true;

    switch (tab) {
      case MainTab.profile:
        // Profile is always accessible during onboarding
        return true;
      case MainTab.pricing:
        // Pricing is accessible only after profile is completed
        return status.profileCompleted;
      case MainTab.home:
        // Home is accessible only after both steps are completed
        return status.isFullyCompleted;
    }
  }

  /// Selects a tab and updates state
  void _selectTab(MainTab tab, {bool forceAllow = false}) {
    // Check if tab is allowed
    if (!forceAllow && !_isTabEnabled(tab)) {
      _showOnboardingMessage(tab);
      return;
    }

    if (_currentTab != tab) {
      setState(() {
        _currentTab = tab;
      });
    }
  }

  /// Shows a message when user tries to access a locked tab
  void _showOnboardingMessage(MainTab tab) {
    String message;
    switch (tab) {
      case MainTab.home:
        message = 'Please complete your profile and pricing setup first.';
        break;
      case MainTab.pricing:
        message = 'Please complete your shop profile first.';
        break;
      case MainTab.profile:
        message = '';
        break;
    }

    if (message.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.warning,
        ),
      );
    }
  }

  /// Callback when profile is saved during onboarding
  Future<void> _onProfileSaved() async {
    // Mark profile as completed
    await OnboardingService.instance.markProfileCompleted();

    if (mounted) {
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profile saved! Now set your pricing.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.success,
        ),
      );

      // Trigger refresh in OnboardingGate to navigate to pricing
      widget.onOnboardingStepCompleted?.call();
    }
  }

  /// Callback when pricing is saved during onboarding
  Future<void> _onPricingSaved() async {
    // Mark pricing as completed
    await OnboardingService.instance.markPricingCompleted();

    if (mounted) {
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Setup complete! Welcome to your dashboard.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.success,
        ),
      );

      // Trigger refresh in OnboardingGate to navigate to home
      widget.onOnboardingStepCompleted?.call();
    }
  }
}

/// Custom navigation bar item with active/inactive states.
class _NavBarItem extends StatelessWidget {
  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.isEnabled = true,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final bool isEnabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = isEnabled
        ? (isActive ? AppTheme.primaryColor : AppTheme.secondaryText)
        : AppTheme.secondaryText.withOpacity(0.4);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? AppTheme.spacingL : AppTheme.spacingM,
          vertical: AppTheme.spacingS,
        ),
        decoration: BoxDecoration(
          color: isActive && isEnabled
              ? AppTheme.primaryColor.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: effectiveColor,
              size: 24,
            ),
            if (isActive && isEnabled) ...[
              const SizedBox(width: AppTheme.spacingS),
              Text(
                label,
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
