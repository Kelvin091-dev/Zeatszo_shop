import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'orders_service.dart';

/// Pending Orders screen for a given shop.
///
/// Firestore structure:
/// - `pendingOrders/{shopId}/orders/{orderId}`: pending order references
/// - `orders/{orderId}`: full order details with at least:
///   - `userName`: String
///   - `quantity`: int
///   - `price`: num (double or int)
///   - `deliveryType`: String
///   - `address`: String
///
/// This screen listens to pending orders in real-time and, for each orderId,
/// fetches the full order document from the `orders` collection.
class PendingOrdersScreen extends StatelessWidget {
  const PendingOrdersScreen({
    super.key,
    required this.shopId,
  });

  final String shopId;

  @override
  Widget build(BuildContext context) {
    final stream = OrdersService.instance.streamPendingOrderRefs(shopId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Orders'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Error loading pending orders'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final docs = snapshot.data?.docs ?? const [];

          if (docs.isEmpty) {
            return const Center(
              child: Text('No pending orders'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final orderId = doc.id;

              return _PendingOrderTile(
                shopId: shopId,
                orderId: orderId,
              );
            },
          );
        },
      ),
    );
  }
}

class _PendingOrderTile extends StatefulWidget {
  const _PendingOrderTile({
    required this.shopId,
    required this.orderId,
  });

  final String shopId;
  final String orderId;

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
          const SnackBar(content: Text('Order marked as completed')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to complete order: $e')),
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
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: OrdersService.instance.fetchOrder(widget.orderId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const ListTile(
            title: Text('Error loading order'),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ListTile(
            title: Text('Loading order...'),
            trailing: SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        final data = snapshot.data!.data();
        if (data == null) {
          return const ListTile(
            title: Text('Order not found'),
          );
        }

        final userName = data['userName'] as String? ?? 'Unknown customer';
        final quantity = data['quantity'] as int? ?? 0;
        final dynamic priceRaw = data['price'];
        double price = 0;
        if (priceRaw is int) {
          price = priceRaw.toDouble();
        } else if (priceRaw is double) {
          price = priceRaw;
        }
        final deliveryType = data['deliveryType'] as String? ?? 'N/A';
        final address = data['address'] as String? ?? 'No address';

        return Card(
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text('Quantity: $quantity'),
                Text('Price: ₦${price.toStringAsFixed(2)}'),
                Text('Delivery: $deliveryType'),
                Text('Address: $address'),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _markAsCompleted,
                    child: _isProcessing
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Mark as Completed'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}



