import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/order_service.dart';
import '../../services/shop_service.dart';
import '../../models/order.dart';
import '../../models/shop.dart';
import '../../widgets/order_card.dart';
import '../../theme/app_theme.dart';
import '../pricing/pricing_screen.dart';
import '../profile/profile_screen.dart';
import '../revenue/revenue_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final OrderService _orderService = OrderService();
  final ShopService _shopService = ShopService();
  Shop? _currentShop;
  OrderStatus? _statusFilter;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadShop();
  }

  Future<void> _loadShop() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final shop = await _shopService.getShopByOwnerId(user.uid);
      setState(() {
        _currentShop = shop;
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _updateOrderStatus(String orderId, OrderStatus newStatus) async {
    try {
      await _orderService.updateOrderStatus(orderId, newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order status updated to ${newStatus.name}'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update order: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showOrderDetails(Order order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Order Details',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                OrderCard(order: order),
                const SizedBox(height: 20),
                if (order.status != OrderStatus.completed && order.status != OrderStatus.cancelled) ...[
                  const Text(
                    'Update Status',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (order.status == OrderStatus.pending)
                        ElevatedButton.icon(
                          onPressed: () {
                            _updateOrderStatus(order.id, OrderStatus.confirmed);
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.check),
                          label: const Text('Confirm'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                        ),
                      if (order.status == OrderStatus.confirmed || order.status == OrderStatus.pending)
                        ElevatedButton.icon(
                          onPressed: () {
                            _updateOrderStatus(order.id, OrderStatus.preparing);
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.soup_kitchen),
                          label: const Text('Preparing'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                        ),
                      if (order.status == OrderStatus.preparing)
                        ElevatedButton.icon(
                          onPressed: () {
                            _updateOrderStatus(order.id, OrderStatus.ready);
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.done_all),
                          label: const Text('Ready'),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                        ),
                      if (order.status == OrderStatus.ready)
                        ElevatedButton.icon(
                          onPressed: () {
                            _updateOrderStatus(order.id, OrderStatus.completed);
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Complete'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700),
                        ),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showCancelDialog(order.id);
                        },
                        icon: const Icon(Icons.cancel),
                        label: const Text('Cancel'),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCancelDialog(String orderId) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            hintText: 'Enter cancellation reason',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Back'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.isNotEmpty) {
                await _orderService.cancelOrder(orderId, reasonController.text);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Order cancelled'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Cancel Order'),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersTab() {
    if (_currentShop == null) {
      return const Center(child: Text('No shop found. Please contact support.'));
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: _statusFilter == null,
                  onSelected: (_) => setState(() => _statusFilter = null),
                ),
                const SizedBox(width: 8),
                ...OrderStatus.values.map((status) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(status.name),
                      selected: _statusFilter == status,
                      onSelected: (_) => setState(() => _statusFilter = status),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Order>>(
            stream: _orderService.getShopOrders(_currentShop!.id, statusFilter: _statusFilter),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final orders = snapshot.data ?? [];

              if (orders.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No orders found', style: TextStyle(fontSize: 18, color: Colors.grey)),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  return OrderCard(
                    order: order,
                    onTap: () => _showOrderDetails(order),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      _buildOrdersTab(),
      if (_currentShop != null) PricingScreen(shopId: _currentShop!.id),
      if (_currentShop != null) RevenueScreen(shopId: _currentShop!.id),
      const ProfileScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Zeatszo Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<AuthService>().signOut();
            },
          ),
        ],
      ),
      body: _currentShop == null
          ? const Center(child: CircularProgressIndicator())
          : screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: AppColors.primary,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: 'Products'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Revenue'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
