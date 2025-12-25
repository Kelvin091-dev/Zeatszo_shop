import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/notification_service.dart';

/// Service layer for working with orders and their lifecycle.
///
/// Orders are stored in the central `/orders` collection with fields:
/// - shopId: UID of the shop
/// - userId: UID of the customer
/// - status: "pending" or "completed"
/// - totalAmount: order total
/// - quantity: number of items
/// - createdAt: when order was placed
/// - completedAt: when order was completed (only for completed orders)
class OrdersService {
  OrdersService._();

  /// Singleton instance.
  static final OrdersService instance = OrdersService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ═══════════════════════════════════════════════════════════════════════════
  // STREAMS - Real-time data from central /orders collection
  // ═══════════════════════════════════════════════════════════════════════════

  /// Stream of PENDING orders for a given shop.
  ///
  /// Queries: /orders where shopId == shopId AND status == "pending"
  /// Ordered by: createdAt descending (newest first)
  Stream<QuerySnapshot<Map<String, dynamic>>> streamPendingOrders(
    String shopId,
  ) {
    return _db
        .collection('orders')
        .where('shopId', isEqualTo: shopId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Stream of COMPLETED orders for a given shop.
  ///
  /// Queries: /orders where shopId == shopId AND status == "completed"
  /// Ordered by: completedAt descending (newest first)
  Stream<QuerySnapshot<Map<String, dynamic>>> streamCompletedOrders(
    String shopId,
  ) {
    return _db
        .collection('orders')
        .where('shopId', isEqualTo: shopId)
        .where('status', isEqualTo: 'completed')
        .orderBy('completedAt', descending: true)
        .snapshots();
  }

  /// Stream of completed orders for TODAY (for revenue calculation).
  ///
  /// Queries: /orders where shopId == shopId AND status == "completed"
  ///          AND completedAt >= startOfToday AND completedAt < endOfToday
  Stream<QuerySnapshot<Map<String, dynamic>>> streamTodayCompletedOrders(
    String shopId,
  ) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _db
        .collection('orders')
        .where('shopId', isEqualTo: shopId)
        .where('status', isEqualTo: 'completed')
        .where('completedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('completedAt', isLessThan: Timestamp.fromDate(endOfDay))
        .snapshots();
  }

  /// Stream of completed orders for THIS MONTH (for revenue calculation).
  ///
  /// Queries: /orders where shopId == shopId AND status == "completed"
  ///          AND completedAt >= startOfMonth AND completedAt < startOfNextMonth
  Stream<QuerySnapshot<Map<String, dynamic>>> streamMonthCompletedOrders(
    String shopId,
  ) {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final startOfNextMonth = DateTime(now.year, now.month + 1, 1);

    return _db
        .collection('orders')
        .where('shopId', isEqualTo: shopId)
        .where('status', isEqualTo: 'completed')
        .where('completedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where('completedAt', isLessThan: Timestamp.fromDate(startOfNextMonth))
        .snapshots();
  }

  /// Stream of ALL completed orders (for lifetime revenue calculation).
  ///
  /// Queries: /orders where shopId == shopId AND status == "completed"
  Stream<QuerySnapshot<Map<String, dynamic>>> streamAllCompletedOrders(
    String shopId,
  ) {
    return _db
        .collection('orders')
        .where('shopId', isEqualTo: shopId)
        .where('status', isEqualTo: 'completed')
        .snapshots();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LEGACY METHODS - For backward compatibility
  // ═══════════════════════════════════════════════════════════════════════════

  /// @deprecated Use [streamPendingOrders] instead.
  /// Stream of pending order references from the legacy subcollection.
  Stream<QuerySnapshot<Map<String, dynamic>>> streamPendingOrderRefs(
    String shopId,
  ) {
    // Now using central /orders collection
    return streamPendingOrders(shopId);
  }

  /// Fetch a single order document from the `orders` collection.
  Future<DocumentSnapshot<Map<String, dynamic>>> fetchOrder(String orderId) {
    return _db.collection('orders').doc(orderId).get();
  }

  /// Mark a pending order as completed.
  ///
  /// Updates the central `orders/{orderId}` document:
  /// - Sets `status` to `completed`
  /// - Sets `completedAt` to serverTimestamp
  ///
  /// Also sends an FCM notification to the user.
  Future<void> markOrderAsCompleted({
    required String shopId,
    required String orderId,
  }) async {
    final orderRef = _db.collection('orders').doc(orderId);

    final userId = await _db.runTransaction<String?>((txn) async {
      final orderSnap = await txn.get(orderRef);
      if (!orderSnap.exists) {
        throw StateError('Order not found');
      }

      final data = orderSnap.data() ?? <String, dynamic>{};
      final String? userId = data['userId'] as String?;

      // Update the order status to completed in the central /orders collection
      txn.update(orderRef, {
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
      });

      return userId;
    });

    if (userId != null && userId.isNotEmpty) {
      await NotificationService.instance.sendOrderCompletedNotification(
        userId: userId,
        orderId: orderId,
      );
    }
  }

  /// Undo order completion - move order back to pending.
  ///
  /// Updates the central `orders/{orderId}` document:
  /// - Sets `status` to `pending`
  /// - Removes `completedAt` field
  ///
  /// Order will immediately disappear from Completed and appear in Pending.
  Future<void> undoOrderCompletion({
    required String orderId,
  }) async {
    final orderRef = _db.collection('orders').doc(orderId);

    await _db.runTransaction((txn) async {
      final orderSnap = await txn.get(orderRef);
      if (!orderSnap.exists) {
        throw StateError('Order not found');
      }

      // Update the order status back to pending
      txn.update(orderRef, {
        'status': 'pending',
        'completedAt': FieldValue.delete(),
      });
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Extract totalAmount from order data (handles int/double).
  /// Extract total price from order data.
  /// 
  /// Checks field names in order of priority:
  /// 1. 'totalPrice' (current format from user app)
  /// 2. 'totalAmount' (alternative format)
  /// 3. 'price' (legacy format)
  static double extractTotalAmount(Map<String, dynamic> data) {
    final dynamic amount = data['totalPrice'] ?? data['totalAmount'] ?? data['price'];
    if (amount is int) {
      return amount.toDouble();
    } else if (amount is double) {
      return amount;
    }
    return 0;
  }
}


