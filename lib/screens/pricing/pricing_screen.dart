import 'package:flutter/material.dart';
import '../../services/product_service.dart';
import '../../models/product.dart';
import '../../theme/app_theme.dart';
import 'package:intl/intl.dart';

class PricingScreen extends StatefulWidget {
  final String shopId;

  const PricingScreen({super.key, required this.shopId});

  @override
  State<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends State<PricingScreen> {
  final ProductService _productService = ProductService();

  void _showProductDialog({Product? product}) {
    final nameController = TextEditingController(text: product?.name ?? '');
    final descController = TextEditingController(text: product?.description ?? '');
    final priceController = TextEditingController(text: product?.price.toString() ?? '');
    final stockController = TextEditingController(text: product?.stockQuantity.toString() ?? '0');
    final categoryController = TextEditingController(text: product?.category ?? 'Chicken');
    final unitController = TextEditingController(text: product?.unit ?? 'kg');
    bool available = product?.available ?? true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(product == null ? 'Add Product' : 'Edit Product'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Product Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Price',
                    prefixText: '\$ ',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: stockController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Stock Quantity',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: categoryController,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: unitController,
                  decoration: const InputDecoration(
                    labelText: 'Unit (e.g., kg, piece)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Available'),
                  value: available,
                  onChanged: (value) {
                    setDialogState(() => available = value);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty || priceController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill in all required fields')),
                  );
                  return;
                }

                final newProduct = Product(
                  id: product?.id ?? '',
                  name: nameController.text,
                  description: descController.text,
                  price: double.tryParse(priceController.text) ?? 0,
                  category: categoryController.text,
                  available: available,
                  stockQuantity: int.tryParse(stockController.text) ?? 0,
                  unit: unitController.text,
                  createdAt: product?.createdAt ?? DateTime.now(),
                  updatedAt: DateTime.now(),
                );

                try {
                  if (product == null) {
                    await _productService.createProduct(widget.shopId, newProduct);
                  } else {
                    await _productService.updateProduct(widget.shopId, product.id, newProduct);
                  }
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(product == null ? 'Product added' : 'Product updated'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${e.toString()}')),
                    );
                  }
                }
              },
              child: Text(product == null ? 'Add' : 'Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteProduct(Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _productService.deleteProduct(widget.shopId, product.id);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Product deleted'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Scaffold(
      body: StreamBuilder<List<Product>>(
        stream: _productService.getShopProducts(widget.shopId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final products = snapshot.data ?? [];

          if (products.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inventory, size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No products yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showProductDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Product'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: product.available ? AppColors.success : Colors.grey,
                    child: Icon(
                      product.available ? Icons.check : Icons.close,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product.description),
                      const SizedBox(height: 4),
                      Text(
                        '${currencyFormat.format(product.price)} per ${product.unit}',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Stock: ${product.stockQuantity} ${product.unit}',
                        style: TextStyle(
                          color: product.stockQuantity > 0 ? Colors.green : Colors.red,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'toggle',
                        child: Row(
                          children: [
                            Icon(
                              product.available ? Icons.visibility_off : Icons.visibility,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(product.available ? 'Mark Unavailable' : 'Mark Available'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: AppColors.error),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: AppColors.error)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) async {
                      if (value == 'edit') {
                        _showProductDialog(product: product);
                      } else if (value == 'toggle') {
                        await _productService.updateProductAvailability(
                          widget.shopId,
                          product.id,
                          !product.available,
                        );
                      } else if (value == 'delete') {
                        _deleteProduct(product);
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showProductDialog(),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }
}
