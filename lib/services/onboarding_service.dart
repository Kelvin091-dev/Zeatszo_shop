import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Service to manage first-time user onboarding state.
///
/// Tracks completion of required setup steps:
/// - Profile completion (shop name, address, etc.)
/// - Pricing completion (chicken price per kg, stock)
///
/// Firestore structure (reads from ROOT shop document):
/// - shops/{shopId}
///   - isProfileCompleted: bool
///   - isPricingCompleted: bool
///   - isActive: bool
///   - createdAt: Timestamp
class OnboardingService {
  OnboardingService._();

  /// Singleton instance
  static final OnboardingService instance = OnboardingService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Get the current user's shop ID (UID)
  String? get _shopId => FirebaseAuth.instance.currentUser?.uid;

  /// Reference to the ROOT shop document (NOT a subcollection)
  DocumentReference<Map<String, dynamic>>? get _shopRef {
    final shopId = _shopId;
    if (shopId == null) return null;
    return _db.collection('shops').doc(shopId);
  }

  /// Legacy reference to the old onboarding subcollection (for backward compatibility)
  DocumentReference<Map<String, dynamic>>? get _legacyOnboardingRef {
    final shopId = _shopId;
    if (shopId == null) return null;
    return _db.collection('shops').doc(shopId).collection('meta').doc('onboarding');
  }

  /// CRITICAL: Initialize onboarding document for NEW users.
  /// 
  /// This is now a NO-OP because ShopService.initializeShopDocument() 
  /// handles creating the root shop document.
  /// 
  /// Kept for backward compatibility.
  Future<void> initializeForNewUser() async {
    // ShopService.initializeShopDocument() now handles this
    // This method is kept for backward compatibility
    debugPrint('✅ OnboardingService.initializeForNewUser() - delegated to ShopService');
  }

  /// Fetch onboarding status once (non-streaming).
  /// 
  /// Reads from the ROOT shops/{shopId} document.
  /// If document doesn't exist, returns NOT completed status.
  Future<OnboardingStatus> getOnboardingStatus() async {
    final ref = _shopRef;
    if (ref == null) {
      return OnboardingStatus.notLoggedIn();
    }

    try {
      final snapshot = await ref.get();
      
      // Document doesn't exist = new user, not completed
      if (!snapshot.exists) {
        debugPrint('📋 Shop doc missing - treating as new user');
        return const OnboardingStatus(
          profileCompleted: false,
          pricingCompleted: false,
        );
      }

      final data = snapshot.data() ?? {};
      return OnboardingStatus(
        profileCompleted: data['isProfileCompleted'] == true,
        pricingCompleted: data['isPricingCompleted'] == true,
      );
    } catch (e) {
      debugPrint('⚠️ Error fetching onboarding status: $e');
      // On error, treat as not completed (user will go through onboarding)
      return const OnboardingStatus(
        profileCompleted: false,
        pricingCompleted: false,
      );
    }
  }

  /// Mark profile as completed
  /// 
  /// This updates the ROOT shops/{shopId} document.
  Future<void> markProfileCompleted() async {
    final ref = _shopRef;
    if (ref == null) return;

    await ref.set({
      'isProfileCompleted': true,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Mark pricing as completed
  /// 
  /// This updates the ROOT shops/{shopId} document.
  Future<void> markPricingCompleted() async {
    final ref = _shopRef;
    if (ref == null) return;

    await ref.set({
      'isPricingCompleted': true,
      'isActive': true, // Shop becomes active when pricing is set
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Check if onboarding is fully completed
  Future<bool> isOnboardingCompleted() async {
    final status = await getOnboardingStatus();
    return status.isFullyCompleted;
  }

  /// Reset onboarding status (for testing/debugging only)
  Future<void> resetOnboarding() async {
    final ref = _shopRef;
    if (ref == null) return;

    await ref.set({
      'isProfileCompleted': false,
      'isPricingCompleted': false,
      'isActive': false,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}

/// Represents the current onboarding status
class OnboardingStatus {
  const OnboardingStatus({
    required this.profileCompleted,
    required this.pricingCompleted,
    this.isLoggedIn = true,
  });

  /// Creates a status for non-logged-in users
  factory OnboardingStatus.notLoggedIn() {
    return const OnboardingStatus(
      profileCompleted: false,
      pricingCompleted: false,
      isLoggedIn: false,
    );
  }

  final bool profileCompleted;
  final bool pricingCompleted;
  final bool isLoggedIn;

  /// Returns true if all onboarding steps are completed
  bool get isFullyCompleted => profileCompleted && pricingCompleted;

  /// Returns the next required step
  OnboardingStep get nextStep {
    if (!isLoggedIn) return OnboardingStep.login;
    if (!profileCompleted) return OnboardingStep.profile;
    if (!pricingCompleted) return OnboardingStep.pricing;
    return OnboardingStep.completed;
  }

  @override
  String toString() {
    return 'OnboardingStatus(profile: $profileCompleted, pricing: $pricingCompleted, nextStep: $nextStep)';
  }
}

/// Enum representing onboarding steps
enum OnboardingStep {
  login,
  profile,
  pricing,
  completed,
}

