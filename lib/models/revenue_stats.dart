import 'package:cloud_firestore/cloud_firestore.dart';

class RevenueStats {
  final double todayRevenue;
  final double weekRevenue;
  final double monthRevenue;
  final int todayOrders;
  final int weekOrders;
  final int monthOrders;
  final DateTime lastUpdated;

  RevenueStats({
    required this.todayRevenue,
    required this.weekRevenue,
    required this.monthRevenue,
    required this.todayOrders,
    required this.weekOrders,
    required this.monthOrders,
    required this.lastUpdated,
  });

  factory RevenueStats.empty() {
    return RevenueStats(
      todayRevenue: 0,
      weekRevenue: 0,
      monthRevenue: 0,
      todayOrders: 0,
      weekOrders: 0,
      monthOrders: 0,
      lastUpdated: DateTime.now(),
    );
  }

  factory RevenueStats.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RevenueStats(
      todayRevenue: (data['todayRevenue'] ?? 0).toDouble(),
      weekRevenue: (data['weekRevenue'] ?? 0).toDouble(),
      monthRevenue: (data['monthRevenue'] ?? 0).toDouble(),
      todayOrders: data['todayOrders'] ?? 0,
      weekOrders: data['weekOrders'] ?? 0,
      monthOrders: data['monthOrders'] ?? 0,
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'todayRevenue': todayRevenue,
      'weekRevenue': weekRevenue,
      'monthRevenue': monthRevenue,
      'todayOrders': todayOrders,
      'weekOrders': weekOrders,
      'monthOrders': monthOrders,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }
}
