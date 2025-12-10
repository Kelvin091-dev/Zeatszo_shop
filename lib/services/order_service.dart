import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order.dart' as model;

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<model.Order>> getShopOrders(String shopId, {model.OrderStatus? statusFilter}) {
    Query query = _firestore.collection('orders').where('shopId', isEqualTo: shopId).orderBy('createdAt', descending: true);
    
    if (statusFilter != null) {
      query = query.where('status', isEqualTo: statusFilter.name);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => model.Order.fromFirestore(doc)).toList();
    });
  }

  Future<model.Order?> getOrderById(String orderId) async {
    try {
      final doc = await _firestore.collection('orders').doc(orderId).get();
      if (doc.exists) {
        return model.Order.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateOrderStatus(String orderId, model.OrderStatus newStatus) async {
    try {
      final updates = <String, dynamic>{'status': newStatus.name};
      
      if (newStatus == model.OrderStatus.completed) {
        updates['completedAt'] = FieldValue.serverTimestamp();
      }

      await _firestore.collection('orders').doc(orderId).update(updates);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> cancelOrder(String orderId, String reason) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': model.OrderStatus.cancelled.name,
        'cancelReason': reason,
        'completedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<List<model.Order>> getOrdersByDateRange(String shopId, DateTime start, DateTime end) async {
    try {
      final snapshot = await _firestore
          .collection('orders')
          .where('shopId', isEqualTo: shopId)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => model.Order.fromFirestore(doc)).toList();
    } catch (e) {
      rethrow;
    }
  }
}
