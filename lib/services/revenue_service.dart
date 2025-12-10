import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order.dart' as model;
import '../models/revenue_stats.dart';

class RevenueService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<RevenueStats> calculateRevenueStats(String shopId) async {
    try {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final monthStart = DateTime(now.year, now.month, 1);

      final todayOrders = await _getOrdersInRange(shopId, todayStart, now);
      final weekOrders = await _getOrdersInRange(shopId, weekStart, now);
      final monthOrders = await _getOrdersInRange(shopId, monthStart, now);

      final todayCompleted = todayOrders.where((o) => o.status == model.OrderStatus.completed).toList();
      final weekCompleted = weekOrders.where((o) => o.status == model.OrderStatus.completed).toList();
      final monthCompleted = monthOrders.where((o) => o.status == model.OrderStatus.completed).toList();

      return RevenueStats(
        todayRevenue: todayCompleted.fold(0.0, (sum, order) => sum + order.totalAmount),
        weekRevenue: weekCompleted.fold(0.0, (sum, order) => sum + order.totalAmount),
        monthRevenue: monthCompleted.fold(0.0, (sum, order) => sum + order.totalAmount),
        todayOrders: todayCompleted.length,
        weekOrders: weekCompleted.length,
        monthOrders: monthCompleted.length,
        lastUpdated: now,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<List<model.Order>> _getOrdersInRange(String shopId, DateTime start, DateTime end) async {
    final snapshot = await _firestore
        .collection('orders')
        .where('shopId', isEqualTo: shopId)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .get();

    return snapshot.docs.map((doc) => model.Order.fromFirestore(doc)).toList();
  }

  Future<Map<String, double>> getDailyRevenue(String shopId, DateTime start, DateTime end) async {
    try {
      final orders = await _getOrdersInRange(shopId, start, end);
      final Map<String, double> dailyRevenue = {};

      for (var order in orders) {
        if (order.status == model.OrderStatus.completed) {
          final dateKey = '${order.createdAt.year}-${order.createdAt.month.toString().padLeft(2, '0')}-${order.createdAt.day.toString().padLeft(2, '0')}';
          dailyRevenue[dateKey] = (dailyRevenue[dateKey] ?? 0) + order.totalAmount;
        }
      }

      return dailyRevenue;
    } catch (e) {
      rethrow;
    }
  }
}
