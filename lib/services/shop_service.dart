import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Service to manage the root shop document at `shops/{shopId}`.
///
/// CRITICAL: This service ensures the root shop document exists and is updated
/// whenever profile or pricing data changes.
///
/// Why this matters:
/// - Firestore subcollections do NOT automatically create their parent documents.
/// - Queries like `collection('shops').get()` only return documents that exist,
///   NOT documents that only have subcollections.
/// - User apps that need to list shops must query the root `shops` collection,
///   which requires the root `shops/{shopId}` document to exist.
///
/// Structure (on creation):
/// shops/{shopId} {
///   shopId: string
///   isProfileCompleted: false
///   isPricingCompleted: false
///   isActive: false
///   createdAt: timestamp
///   updatedAt: timestamp
/// }
///
/// After profile saved:
/// shops/{shopId} {
///   ...existing fields...
///   shopName: string
///   address: string
///   phone: string (optional)
///   shopImageUrl: string (optional)
///   isProfileCompleted: true
///   updatedAt: timestamp
/// }
///
/// After pricing saved:
/// shops/{shopId} {
///   ...existing fields...
///   chickenPricePerKg: number
///   isPricingCompleted: true
///   isActive: true
///   updatedAt: timestamp
/// }
class ShopService {
  ShopService._();

  /// Singleton instance
  static final ShopService instance = ShopService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Get current user's shop ID (UID)
  String? get currentShopId => FirebaseAuth.instance.currentUser?.uid;

  /// Reference to the root shop document
  DocumentReference<Map<String, dynamic>> _shopDocRef(String shopId) =>
      _db.collection('shops').doc(shopId);

  /// CRITICAL: Initialize the root shop document for NEW users.
  ///
  /// This MUST be called immediately after successful signup,
  /// BEFORE any navigation happens.
  ///
  /// Creates:
  /// shops/{shopId} {
  ///   shopId: "<uid>",
  ///   isProfileCompleted: false,
  ///   isPricingCompleted: false,
  ///   isActive: false,
  ///   createdAt: serverTimestamp(),
  ///   updatedAt: serverTimestamp()
  /// }
  Future<void> initializeShopDocument() async {
    final shopId = currentShopId;
    if (shopId == null || shopId.isEmpty) {
      debugPrint('❌ ShopService: Cannot initialize - no user logged in');
      return;
    }

    try {
      // Check if document already exists (returning user)
      final existing = await _shopDocRef(shopId).get();
      if (existing.exists) {
        debugPrint('✅ ShopService: Shop document already exists');
        return;
      }

      // Create new shop document for first-time user
      await _shopDocRef(shopId).set({
        'shopId': shopId,
        'isProfileCompleted': false,
        'isPricingCompleted': false,
        'isActive': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ ShopService: Root shop document created at shops/$shopId');
    } catch (e) {
      debugPrint('❌ ShopService: Failed to create shop document: $e');
      // Don't throw - we don't want to break the signup flow
    }
  }

  /// Update root shop document with profile data.
  ///
  /// Call this whenever shop profile is saved.
  /// Uses `SetOptions(merge: true)` to preserve existing fields.
  ///
  /// Updates:
  /// - shopName
  /// - address
  /// - phone (optional)
  /// - shopImageUrl (optional)
  /// - isProfileCompleted = true
  /// - updatedAt
  Future<void> syncProfileToRootDocument({
    required String shopId,
    required String? shopName,
    required String? address,
    required String? phone,
    required String? imageUrl,
  }) async {
    if (shopId.isEmpty) {
      debugPrint('❌ ShopService: Cannot sync profile - shopId is empty');
      return;
    }

    try {
      final updateData = <String, dynamic>{
        'shopId': shopId,
        'isProfileCompleted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Only add non-null fields
      if (shopName != null && shopName.isNotEmpty) {
        updateData['shopName'] = shopName;
      }
      if (address != null && address.isNotEmpty) {
        updateData['address'] = address;
      }
      if (phone != null && phone.isNotEmpty) {
        updateData['phone'] = phone;
      }
      if (imageUrl != null && imageUrl.isNotEmpty) {
        updateData['shopImageUrl'] = imageUrl;
      }

      // Check if document exists to set createdAt only once
      final docSnapshot = await _shopDocRef(shopId).get();
      if (!docSnapshot.exists) {
        updateData['createdAt'] = FieldValue.serverTimestamp();
        updateData['isProfileCompleted'] = false;
        updateData['isPricingCompleted'] = false;
        updateData['isActive'] = false;
      }

      await _shopDocRef(shopId).set(updateData, SetOptions(merge: true));
      debugPrint('✅ ShopService: Profile saved to shops/$shopId');
    } catch (e) {
      debugPrint('❌ ShopService: Failed to sync profile to root: $e');
      rethrow; // Rethrow so the UI can show error message
    }
  }

  /// Update root shop document with pricing data.
  ///
  /// Call this whenever pricing is saved.
  /// Uses `SetOptions(merge: true)` to preserve existing fields.
  ///
  /// Updates:
  /// - chickenPricePerKg
  /// - isPricingCompleted = true
  /// - isActive = true (shop is now visible to users)
  /// - updatedAt
  Future<void> syncPricingToRootDocument({
    required String shopId,
    required double? pricePerKg,
    required int? stockKg,
    required String? productImageUrl,
  }) async {
    if (shopId.isEmpty) {
      debugPrint('❌ ShopService: Cannot sync pricing - shopId is empty');
      return;
    }

    try {
      final updateData = <String, dynamic>{
        'shopId': shopId,
        'isPricingCompleted': true,
        'isActive': true, // Shop becomes active and visible to users
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Only add non-null fields
      if (pricePerKg != null && pricePerKg > 0) {
        updateData['chickenPricePerKg'] = pricePerKg;
      }
      if (stockKg != null && stockKg >= 0) {
        updateData['stockKg'] = stockKg;
      }
      if (productImageUrl != null && productImageUrl.isNotEmpty) {
        updateData['productImageUrl'] = productImageUrl;
      }

      // Check if document exists to set createdAt only once
      final docSnapshot = await _shopDocRef(shopId).get();
      if (!docSnapshot.exists) {
        updateData['createdAt'] = FieldValue.serverTimestamp();
        updateData['isProfileCompleted'] = false;
        updateData['isPricingCompleted'] = false;
        updateData['isActive'] = false;
      }

      await _shopDocRef(shopId).set(updateData, SetOptions(merge: true));
      debugPrint('✅ ShopService: Pricing saved to shops/$shopId');
    } catch (e) {
      debugPrint('❌ ShopService: Failed to sync pricing to root: $e');
      rethrow; // Rethrow so the UI can show error message
    }
  }

  /// Get the root shop document.
  Future<DocumentSnapshot<Map<String, dynamic>>> getShop(String shopId) {
    return _shopDocRef(shopId).get();
  }

  /// Stream the root shop document.
  Stream<DocumentSnapshot<Map<String, dynamic>>> streamShop(String shopId) {
    return _shopDocRef(shopId).snapshots();
  }

  /// Get all active shops (for user app listing).
  Future<QuerySnapshot<Map<String, dynamic>>> getAllActiveShops() {
    return _db
        .collection('shops')
        .where('isActive', isEqualTo: true)
        .get();
  }

  /// Stream all active shops (for user app listing).
  Stream<QuerySnapshot<Map<String, dynamic>>> streamAllActiveShops() {
    return _db
        .collection('shops')
        .where('isActive', isEqualTo: true)
        .snapshots();
  }
}


