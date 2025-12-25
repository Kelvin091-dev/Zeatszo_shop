import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../orders/orders_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/dashboard_card.dart';

/// Embeddable content widget for pending orders.
///
/// This is designed to be used inside IndexedStack without its own Scaffold.
/// Real-time Firestore updates with mark as completed functionality.
class PendingOrdersContent extends StatelessWidget {
  const PendingOrdersContent({
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
              'Please login to view pending orders',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.secondaryText,
                  ),
            ),
          ],
        ),
      );
    }

    // Stream from central /orders collection where shopId == shopId AND status == "pending"
    final stream = OrdersService.instance.streamPendingOrders(shopId);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        // Only show error for REAL exceptions (network, permission, etc.)
        // NOT for missing documents or empty collections
        if (snapshot.hasError) {
          final error = snapshot.error;
          // Log the actual error for debugging
          debugPrint('Pending orders error: $error');
          
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppTheme.error,
                ),
                const SizedBox(height: AppTheme.spacingM),
                Text(
                  'Something went wrong',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppTheme.spacingS),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingL),
                  child: Text(
                    error.toString(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.secondaryText,
                        ),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }

        // Still loading - show spinner
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        // Data loaded successfully - extract documents
        final docs = snapshot.data?.docs ?? const [];

        // Empty collection = show friendly empty state (NOT an error!)
        if (docs.isEmpty) {
          return Center(
            child: EmptyStateCard(
              icon: Icons.pending_actions,
              title: 'No Pending Orders',
              subtitle: 'All orders have been processed. Great job!',
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(AppTheme.spacingS),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppTheme.spacingS),
          itemBuilder: (context, index) {
            final doc = docs[index];
            final orderId = doc.id;
            final orderData = doc.data();

            // Pass order data directly - no need for separate fetch
            return _PendingOrderTile(
              shopId: shopId,
              orderId: orderId,
              orderData: orderData,
            );
          },
        );
      },
    );
  }
}

class _PendingOrderTile extends StatefulWidget {
  const _PendingOrderTile({
    required this.shopId,
    required this.orderId,
    required this.orderData,
  });

  final String shopId;
  final String orderId;
  final Map<String, dynamic> orderData;

  @override
  State<_PendingOrderTile> createState() => _PendingOrderTileState();
}

class _PendingOrderTileState extends State<_PendingOrderTile> {
  bool _isProcessing = false;

  Future<void> _markAsCompleted() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      await OrdersService.instance.markOrderAsCompleted(
        shopId: widget.shopId,
        orderId: widget.orderId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Order marked as completed'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to complete order: $e'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.orderData;

    // Extract order data - uses 'totalPrice' field from Firestore
    final userName = data['userName'] as String? ?? 'Unknown';
    final quantity = (data['quantity'] as num?)?.toInt() ?? 0;
    final double totalPrice = OrdersService.extractTotalAmount(data);
    final deliveryType = data['deliveryType'] as String? ?? 'N/A';
    final address = data['address'] as String? ?? '';
    final bool isHomeDelivery = deliveryType.toLowerCase() == 'home_delivery' ||
        deliveryType.toLowerCase() == 'home delivery';

    return Card(
      elevation: AppTheme.elevationLow,
      color: Colors.black,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingM,
          vertical: AppTheme.spacingS,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header: Username + PENDING badge (same row, NO avatar)
            Row(
              children: [
                Expanded(
                  child: Text(
                    userName,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingS),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.warning,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'PENDING',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppTheme.spacingS),
            
            // Order details - 2x2 GRID LAYOUT for compact display
            Row(
              children: [
                // LEFT COLUMN: Quantity + Total
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _CompactDetailItem(
                        label: 'Qty',
                        value: '$quantity kg',
                      ),
                      const SizedBox(height: 2),
                      _CompactDetailItem(
                        label: 'Total',
                        value: '₦${totalPrice.toStringAsFixed(0)}',
                        isHighlighted: true,
                      ),
                    ],
                  ),
                ),
                // RIGHT COLUMN: Delivery + Address (conditional)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _CompactDetailItem(
                        label: 'Type',
                        value: isHomeDelivery ? 'Home' : 'Pickup',
                      ),
                      if (isHomeDelivery && address.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        _CompactDetailItem(
                          label: 'Addr',
                          value: address,
                          maxLines: 1,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppTheme.spacingS),
            
            // Action button - compact
            SizedBox(
              width: double.infinity,
              height: 36,
              child: ElevatedButton.icon(
                onPressed: _isProcessing ? null : _markAsCompleted,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM),
                ),
                icon: _isProcessing
                    ? const SizedBox(
                        height: 14,
                        width: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.check_circle, size: 16),
                label: Text(
                  _isProcessing ? 'Processing...' : 'Complete',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact detail item for 2x2 grid layout (black card background)
class _CompactDetailItem extends StatelessWidget {
  const _CompactDetailItem({
    required this.label,
    required this.value,
    this.isHighlighted = false,
    this.maxLines = 1,
  });

  final String label;
  final String value;
  final bool isHighlighted;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey,
            fontSize: 11,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isHighlighted ? AppTheme.success : Colors.white,
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w500,
              fontSize: isHighlighted ? 14 : 12,
            ),
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}


