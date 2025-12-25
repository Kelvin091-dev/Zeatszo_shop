import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../orders/orders_service.dart';
import '../../theme/app_theme.dart';

/// Full-screen analytics content widget for revenue display.
///
/// This is designed to be used inside IndexedStack without its own Scaffold.
/// Shows Today's, This Month's, and Total Revenue from completed orders.
///
/// IMPORTANT: Revenue is calculated ONLY from completed orders (status == "completed").
/// Pending orders are NOT included in revenue calculations.
///
/// OPTIMIZATION: Uses a SINGLE Firestore stream for all completed orders,
/// then computes Today/Month/Total revenue client-side.
class RevenueContent extends StatelessWidget {
  const RevenueContent({
    super.key,
    required this.shopId,
  });

  final String shopId;

  @override
  Widget build(BuildContext context) {
    // Guard: Check if shopId is valid
    if (shopId.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_circle_outlined,
              size: 64,
              color: AppTheme.warning,
            ),
            const SizedBox(height: AppTheme.spacingM),
            Text(
              'Not Logged In',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              'Please login to view revenue analytics',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.secondaryText,
                  ),
            ),
          ],
        ),
      );
    }

    // ══════════════════════════════════════════════════════════════════════════
    // SINGLE STREAM: Fetch ALL completed orders for this shop
    // Compute Today/Month/Total revenue client-side from this single stream
    // ══════════════════════════════════════════════════════════════════════════
    final stream = OrdersService.instance.streamAllCompletedOrders(shopId);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        final bool isLoading = snapshot.connectionState == ConnectionState.waiting;
        
        // Initialize revenue values
        double todayRevenue = 0;
        double monthRevenue = 0;
        double totalRevenue = 0;
        int todayOrderCount = 0;
        int monthOrderCount = 0;
        int totalOrderCount = 0;

        // Calculate all revenue values from a single data source
        if (!isLoading && snapshot.hasData) {
          final docs = snapshot.data?.docs ?? [];
          final now = DateTime.now();
          final startOfToday = DateTime(now.year, now.month, now.day);
          final startOfMonth = DateTime(now.year, now.month, 1);

          for (final doc in docs) {
            final data = doc.data();
            final double price = OrdersService.extractTotalAmount(data);
            
            // Always add to total (all completed orders)
            totalRevenue += price;
            totalOrderCount++;

            // Check completedAt timestamp for date-based filtering
            final completedAt = data['completedAt'];
            if (completedAt is Timestamp) {
              final completedDate = completedAt.toDate();

              // Check if completed TODAY (same year, month, day)
              if (completedDate.year == now.year &&
                  completedDate.month == now.month &&
                  completedDate.day == now.day) {
                todayRevenue += price;
                todayOrderCount++;
              }

              // Check if completed THIS MONTH (same year and month)
              if (completedDate.year == now.year &&
                  completedDate.month == now.month) {
                monthRevenue += price;
                monthOrderCount++;
              }
            }
          }
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Revenue Analytics',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppTheme.spacingS),
              Text(
                'Track your shop\'s financial performance',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.secondaryText,
                    ),
              ),
              const SizedBox(height: AppTheme.spacingL),

              // Today's Revenue Card
              _RevenueCard(
                title: "Today's Revenue",
                subtitle: 'Revenue earned today',
                value: '₦${todayRevenue.toStringAsFixed(2)}',
                orderCount: todayOrderCount,
                icon: Icons.today,
                iconColor: AppTheme.tertiaryColor,
                gradientColors: [
                  AppTheme.tertiaryColor,
                  AppTheme.tertiaryColor.withOpacity(0.7),
                ],
                isLoading: isLoading,
              ),
              const SizedBox(height: AppTheme.spacingM),

              // This Month's Revenue Card
              _RevenueCard(
                title: 'This Month',
                subtitle: 'Revenue this month',
                value: '₦${monthRevenue.toStringAsFixed(2)}',
                orderCount: monthOrderCount,
                icon: Icons.calendar_month,
                iconColor: AppTheme.secondaryColor,
                gradientColors: [
                  AppTheme.secondaryColor,
                  AppTheme.secondaryColor.withOpacity(0.7),
                ],
                isLoading: isLoading,
              ),
              const SizedBox(height: AppTheme.spacingM),

              // Total Revenue Card (highlighted)
              _RevenueCard(
                title: 'Total Revenue',
                subtitle: 'All-time earnings',
                value: '₦${totalRevenue.toStringAsFixed(2)}',
                orderCount: totalOrderCount,
                icon: Icons.account_balance_wallet,
                iconColor: AppTheme.primaryColor,
                gradientColors: [
                  AppTheme.primaryColor,
                  AppTheme.primaryColor.withOpacity(0.7),
                ],
                isLoading: isLoading,
                isHighlighted: true,
              ),
              
              const SizedBox(height: AppTheme.spacingXl),
              
              // Revenue Summary Section
              _RevenueSummarySection(shopId: shopId),
            ],
          ),
        );
      },
    );
  }
}

/// Reusable Revenue Card Widget
class _RevenueCard extends StatelessWidget {
  const _RevenueCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.orderCount,
    required this.icon,
    required this.iconColor,
    required this.gradientColors,
    this.isLoading = false,
    this.isHighlighted = false,
  });

  final String title;
  final String subtitle;
  final String value;
  final int orderCount;
  final IconData icon;
  final Color iconColor;
  final List<Color> gradientColors;
  final bool isLoading;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
        gradient: isHighlighted
            ? LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isHighlighted ? null : AppTheme.secondaryBackground,
        boxShadow: [
          BoxShadow(
            color: isHighlighted
                ? iconColor.withOpacity(0.3)
                : Colors.black.withOpacity(0.08),
            blurRadius: isHighlighted ? 16 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Row(
          children: [
            // Icon Container
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              decoration: BoxDecoration(
                color: isHighlighted
                    ? Colors.white.withOpacity(0.2)
                    : iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
              ),
              child: Icon(
                icon,
                color: isHighlighted ? Colors.white : iconColor,
                size: 32,
              ),
            ),
            const SizedBox(width: AppTheme.spacingL),

            // Text Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: isHighlighted
                              ? Colors.white.withOpacity(0.9)
                              : AppTheme.secondaryText,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const SizedBox(height: AppTheme.spacingXs),
                  if (isLoading)
                    SizedBox(
                      height: 32,
                      width: 32,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isHighlighted ? Colors.white : iconColor,
                        ),
                      ),
                    )
                  else
                    Text(
                      value,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isHighlighted
                                ? Colors.white
                                : AppTheme.primaryText,
                          ),
                    ),
                  if (!isLoading) ...[
                    const SizedBox(height: AppTheme.spacingXs),
                    Text(
                      '$orderCount ${orderCount == 1 ? 'order' : 'orders'}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isHighlighted
                                ? Colors.white.withOpacity(0.8)
                                : AppTheme.secondaryText,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Revenue Summary Section with additional insights
class _RevenueSummarySection extends StatelessWidget {
  const _RevenueSummarySection({required this.shopId});

  final String shopId;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: AppTheme.secondaryBackground,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
        border: Border.all(color: AppTheme.alternateColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingS),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                ),
                child: const Icon(
                  Icons.insights,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Text(
                'Quick Insights',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          const Divider(),
          const SizedBox(height: AppTheme.spacingM),
          _buildInsightRow(
            context,
            icon: Icons.trending_up,
            label: 'Performance',
            value: 'Real-time tracking enabled',
            color: AppTheme.success,
          ),
          const SizedBox(height: AppTheme.spacingM),
          _buildInsightRow(
            context,
            icon: Icons.sync,
            label: 'Data Sync',
            value: 'Live Firestore updates',
            color: AppTheme.secondaryColor,
          ),
          const SizedBox(height: AppTheme.spacingM),
          _buildInsightRow(
            context,
            icon: Icons.security,
            label: 'Security',
            value: 'Shop-specific data only',
            color: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildInsightRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: AppTheme.spacingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.secondaryText,
                    ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Note: Price extraction is now handled by OrdersService.extractTotalAmount()
// which supports both 'price' (old format) and 'totalAmount' (new format) fields.


