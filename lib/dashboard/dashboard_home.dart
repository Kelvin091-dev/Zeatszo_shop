import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/dashboard_selector_card.dart';
import 'screens/completed_orders_content.dart';
import 'screens/pending_orders_content.dart';
import 'screens/revenue_content.dart';

/// Enum for dashboard screen selection state.
enum DashboardScreen {
  pending,
  completed,
  revenue,
}

/// Main dashboard home screen for the shopkeeper app.
///
/// Uses IndexedStack for fragment-like screen switching.
/// Top selector cards control which screen is displayed below.
///
/// Features:
/// - Three selector cards at the top (Pending, Completed, Revenue)
/// - Only one screen visible at a time
/// - No Navigator.push - instant screen switching
/// - State managed internally with enum
///
/// Firestore expectations:
/// - Collection: `pendingOrders/{shopId}/orders`
/// - Collection: `completedOrders/{shopId}/orders`
/// - Fields: status, amount, price, createdAt, completedAt
class DashboardHome extends StatefulWidget {
  const DashboardHome({super.key});

  @override
  State<DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<DashboardHome> {
  /// Currently selected screen - defaults to pending orders
  DashboardScreen _selectedScreen = DashboardScreen.pending;

  /// Shop ID derived from current user's UID
  String get _shopId => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;

    // ══════════════════════════════════════════════════════════════════
    // FIX: Use central /orders collection with proper filters
    // ══════════════════════════════════════════════════════════════════

    // Pending orders: status == 'pending' AND shopId == _shopId
    final pendingOrdersStream = firestore
        .collection('orders')
        .where('shopId', isEqualTo: _shopId)
        .where('status', isEqualTo: 'pending')
        .snapshots();

    // Completed orders: status == 'completed' AND shopId == _shopId
    final completedOrdersStream = firestore
        .collection('orders')
        .where('shopId', isEqualTo: _shopId)
        .where('status', isEqualTo: 'completed')
        .snapshots();

    // Today's revenue: fetch all completed orders, filter by today's date client-side
    // This avoids complex composite index requirements
    final todayRevenueStream = firestore
        .collection('orders')
        .where('shopId', isEqualTo: _shopId)
        .where('status', isEqualTo: 'completed')
        .snapshots();

    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      body: Column(
        children: [
          // ══════════════════════════════════════════════════════════════════
          // TOP SELECTOR CARDS - Acts like tab buttons
          // ══════════════════════════════════════════════════════════════════
          Container(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.spacingM,
              AppTheme.spacingM,
              AppTheme.spacingM,
              AppTheme.spacingS,
            ),
            decoration: BoxDecoration(
              color: AppTheme.secondaryBackground,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Header
                Text(
                  'Welcome Back!',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Select a category to view details',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.secondaryText,
                      ),
                ),
                const SizedBox(height: AppTheme.spacingM),

                // Selector Cards Row
                Row(
                  children: [
                    // Pending Orders Selector
                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: pendingOrdersStream,
                      builder: (context, snapshot) {
                        final count = snapshot.data?.docs.length ?? 0;
                        final isLoading =
                            snapshot.connectionState == ConnectionState.waiting;

                        return DashboardSelectorCard(
                          title: 'Pending',
                          value: '$count',
                          icon: Icons.pending_actions,
                          iconColor: AppTheme.warning,
                          isActive: _selectedScreen == DashboardScreen.pending,
                          isLoading: isLoading,
                          onTap: () => _selectScreen(DashboardScreen.pending),
                        );
                      },
                    ),

                    // Completed Orders Selector
                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: completedOrdersStream,
                      builder: (context, snapshot) {
                        final count = snapshot.data?.docs.length ?? 0;
                        final isLoading =
                            snapshot.connectionState == ConnectionState.waiting;

                        return DashboardSelectorCard(
                          title: 'Completed',
                          value: '$count',
                          icon: Icons.check_circle,
                          iconColor: AppTheme.success,
                          isActive: _selectedScreen == DashboardScreen.completed,
                          isLoading: isLoading,
                          onTap: () => _selectScreen(DashboardScreen.completed),
                        );
                      },
                    ),

                    // Today's Revenue Selector
                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: todayRevenueStream,
                      builder: (context, snapshot) {
                        double total = 0;
                        final isLoading =
                            snapshot.connectionState == ConnectionState.waiting;

                        if (!isLoading && !snapshot.hasError) {
                          final docs = snapshot.data?.docs ?? [];
                          final now = DateTime.now();
                          
                          for (final doc in docs) {
                            final data = doc.data();
                            
                            // Filter by TODAY's date (client-side)
                            final completedAt = data['completedAt'];
                            if (completedAt is Timestamp) {
                              final completedDate = completedAt.toDate();
                              
                              // Check if completedAt is TODAY (same year, month, day)
                              if (completedDate.year == now.year &&
                                  completedDate.month == now.month &&
                                  completedDate.day == now.day) {
                                // Use totalPrice field (primary) or fallback to price
                                final dynamic priceRaw = data['totalPrice'] ?? data['price'];
                                if (priceRaw is int) {
                                  total += priceRaw.toDouble();
                                } else if (priceRaw is double) {
                                  total += priceRaw;
                                }
                              }
                            }
                          }
                        }

                        return DashboardSelectorCard(
                          title: "Today's Revenue",
                          value: '₦${total.toStringAsFixed(0)}',
                          icon: Icons.account_balance_wallet,
                          iconColor: AppTheme.tertiaryColor,
                          isActive: _selectedScreen == DashboardScreen.revenue,
                          isLoading: isLoading,
                          onTap: () => _selectScreen(DashboardScreen.revenue),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ══════════════════════════════════════════════════════════════════
          // CONTENT AREA - Fragment-like screen switching with IndexedStack
          // ══════════════════════════════════════════════════════════════════
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeInOut,
              switchOutCurve: Curves.easeInOut,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.02, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: _buildSelectedScreen(),
            ),
          ),
        ],
      ),
    );
  }

  /// Selects a screen and updates state
  void _selectScreen(DashboardScreen screen) {
    if (_selectedScreen != screen) {
      setState(() {
        _selectedScreen = screen;
      });
    }
  }

  /// Builds the currently selected screen content
  Widget _buildSelectedScreen() {
    switch (_selectedScreen) {
      case DashboardScreen.pending:
        return PendingOrdersContent(
          key: const ValueKey('pending'),
          shopId: _shopId,
        );
      case DashboardScreen.completed:
        return CompletedOrdersContent(
          key: const ValueKey('completed'),
          shopId: _shopId,
        );
      case DashboardScreen.revenue:
        return RevenueContent(
          key: const ValueKey('revenue'),
          shopId: _shopId,
        );
    }
  }
}
