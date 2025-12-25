import 'package:flutter/material.dart';

import '../services/onboarding_service.dart';
import '../theme/app_theme.dart';
import 'main_shell.dart';

/// Gate widget that checks onboarding status and routes accordingly.
///
/// Flow:
/// 1. If profile not completed → Open MainShell with Profile tab selected
/// 2. If pricing not completed → Open MainShell with Pricing tab selected
/// 3. If fully completed → Open MainShell with Home tab selected
///
/// This ensures first-time users complete required setup before accessing dashboard.
///
/// CRITICAL: Uses FutureBuilder with get() instead of StreamBuilder with snapshots()
/// to avoid infinite loading when the onboarding document doesn't exist yet.
class OnboardingGate extends StatefulWidget {
  const OnboardingGate({super.key});

  @override
  State<OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends State<OnboardingGate> {
  late Future<OnboardingStatus> _statusFuture;

  @override
  void initState() {
    super.initState();
    // Use get() instead of snapshots() - this will NOT wait forever
    _statusFuture = OnboardingService.instance.getOnboardingStatus();
  }

  /// Refresh onboarding status (called when returning from profile/pricing save)
  void _refreshStatus() {
    setState(() {
      _statusFuture = OnboardingService.instance.getOnboardingStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<OnboardingStatus>(
      future: _statusFuture,
      builder: (context, snapshot) {
        // Still loading onboarding status
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: AppTheme.primaryBackground,
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading...'),
                ],
              ),
            ),
          );
        }

        // SAFE FALLBACK: If error or no data, treat as first-time user
        // This ensures NO infinite spinner - user goes to Profile screen
        final status = snapshot.data ??
            const OnboardingStatus(
              profileCompleted: false,
              pricingCompleted: false,
            );

        // Determine which tab to show based on onboarding status
        final initialTab = _getInitialTab(status);
        final isOnboarding = !status.isFullyCompleted;

        return MainShell(
          key: ValueKey('main_shell_${status.nextStep}'),
          initialTab: initialTab,
          isOnboarding: isOnboarding,
          onboardingStatus: status,
          onOnboardingStepCompleted: _refreshStatus,
        );
      },
    );
  }

  /// Determines the initial tab based on onboarding status
  MainTab _getInitialTab(OnboardingStatus status) {
    switch (status.nextStep) {
      case OnboardingStep.profile:
        return MainTab.profile;
      case OnboardingStep.pricing:
        return MainTab.pricing;
      case OnboardingStep.completed:
      case OnboardingStep.login:
        return MainTab.home;
    }
  }
}

