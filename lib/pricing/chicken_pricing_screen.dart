import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/shop_service.dart';
import '../theme/app_theme.dart';

/// Screen where a shopkeeper can manage ONLY chicken pricing details.
///
/// Data location:
/// - Document path: `shops/{shopId}/chickenPricing`
/// - Example fields:
///   - `price`: number (double / int)
///   - `stock`: number (int)
///   - `imageUrl`: string (download URL from Firebase Storage)
///
/// Supports onboarding flow via [onSaveComplete] callback.
class ChickenPricingScreen extends StatefulWidget {
  const ChickenPricingScreen({
    super.key,
    required this.shopId,
    this.onSaveComplete,
  });

  final String shopId;

  /// Optional callback called after successful save (used for onboarding flow)
  final VoidCallback? onSaveComplete;

  @override
  State<ChickenPricingScreen> createState() => _ChickenPricingScreenState();
}

class _ChickenPricingScreenState extends State<ChickenPricingScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _priceText;
  String? _stockText;

  bool _isSaving = false;

  /// Returns true if shopId is valid and user is logged in
  bool get _hasValidShopId => widget.shopId.isNotEmpty;

  /// FIXED: Document path must have EVEN segments (collection/doc/collection/doc)
  /// 
  /// Old (BROKEN): 'shops/{shopId}/chickenPricing' = 3 segments = COLLECTION
  /// New (FIXED):  'shops/{shopId}/chickenPricing/data' = 4 segments = DOCUMENT
  DocumentReference<Map<String, dynamic>> get _docRef =>
      FirebaseFirestore.instance
          .collection('shops')
          .doc(widget.shopId)
          .collection('chickenPricing')
          .doc('data');

  Future<void> _save(DocumentSnapshot<Map<String, dynamic>>? currentSnap) async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();

    setState(() {
      _isSaving = true;
    });

    try {
      // Parse numeric values, falling back to existing snapshot values if needed.
      final currentData = currentSnap?.data() ?? <String, dynamic>{};

      double? price;

      if (_priceText != null && _priceText!.trim().isNotEmpty) {
        price = double.tryParse(_priceText!.trim());
      } else if (currentData['price'] is num) {
        price = (currentData['price'] as num).toDouble();
      }

      int? stock;

      if (_stockText != null && _stockText!.trim().isNotEmpty) {
        stock = int.tryParse(_stockText!.trim());
      } else if (currentData['stock'] is num) {
        stock = (currentData['stock'] as num).toInt();
      }

      final updateData = <String, dynamic>{};

      if (price != null) updateData['price'] = price;
      if (stock != null) updateData['stock'] = stock;

      if (updateData.isNotEmpty) {
        // Save to subcollection (existing behavior)
        await _docRef.set(updateData, SetOptions(merge: true));

        // CRITICAL: Also sync to ROOT shop document at shops/{shopId}
        // This ensures the shop pricing appears in Firestore UI and user app queries
        await ShopService.instance.syncPricingToRootDocument(
          shopId: widget.shopId,
          pricePerKg: price,
          stockKg: stock,
          productImageUrl: null,
        );
      }

      if (mounted) {
        // Only show snackbar if NOT in onboarding mode
        // (onboarding flow handles its own messages)
        if (widget.onSaveComplete == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Chicken pricing updated successfully'),
              backgroundColor: AppTheme.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }

        // Call onboarding callback if provided
        widget.onSaveComplete?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update pricing: $e'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Guard: Check if shopId is valid
    if (!_hasValidShopId) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Chicken Pricing'),
        ),
        body: Center(
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
                'Please login to manage pricing',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.secondaryText,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chicken Pricing'),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _docRef.snapshots(),
        builder: (context, snapshot) {
          // Still loading - show spinner
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // IMPORTANT: Don't show error for missing documents!
          // Missing document is NOT an error - it just means user hasn't set pricing yet
          // We show empty/default values and let them fill in the form
          
          // Only show error for REAL exceptions (permission denied, network issues, etc.)
          // But even then, we still show the editable form with empty values
          if (snapshot.hasError) {
            debugPrint('Pricing error (non-blocking): ${snapshot.error}');
            // Don't block UI - just log and continue with empty data
          }

          // Extract data - will be empty map if document doesn't exist (NOT an error!)
          final data = snapshot.data?.data() ?? <String, dynamic>{};

          final currentPrice = data['price'];
          final currentStock = data['stock'];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Image Section - STATIC LOCAL IMAGE
                  Center(
                    child: Container(
                      height: 160,
                      width: 160,
                      decoration: BoxDecoration(
                        color: AppTheme.alternateColor,
                        borderRadius: BorderRadius.circular(
                            AppTheme.borderRadiusLarge),
                        border: Border.all(
                          color: AppTheme.tertiaryColor.withOpacity(0.3),
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.asset(
                        'assets/images/chicken.jpg',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingXl),

                  // Pricing Details Section
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacingL),
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryBackground,
                      borderRadius:
                          BorderRadius.circular(AppTheme.borderRadiusLarge),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(AppTheme.spacingS),
                              decoration: BoxDecoration(
                                color: AppTheme.tertiaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(
                                    AppTheme.borderRadiusSmall),
                              ),
                              child: Icon(
                                Icons.price_change,
                                color: AppTheme.tertiaryColor,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: AppTheme.spacingM),
                            Text(
                              'Pricing & Stock',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.spacingL),
                        TextFormField(
                          key: ValueKey('price_${currentPrice ?? ''}'),
                          initialValue: currentPrice == null
                              ? ''
                              : (currentPrice as num).toStringAsFixed(2),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Price per KG',
                            prefixText: '₦ ',
                            prefixIcon: Icon(Icons.attach_money),
                            helperText: 'Set the price per kilogram',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Enter a price';
                            }
                            final parsed = double.tryParse(value.trim());
                            if (parsed == null || parsed <= 0) {
                              return 'Enter a valid price';
                            }
                            return null;
                          },
                          onSaved: (value) => _priceText = value,
                        ),
                        const SizedBox(height: AppTheme.spacingM),
                        TextFormField(
                          key: ValueKey('stock_${currentStock ?? ''}'),
                          initialValue: currentStock == null
                              ? ''
                              : (currentStock as num).toString(),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: false),
                          decoration: const InputDecoration(
                            labelText: 'Available Stock',
                            suffixText: 'KG',
                            prefixIcon: Icon(Icons.inventory_2),
                            helperText: 'Set available stock in kilograms',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Enter stock quantity';
                            }
                            final parsed = int.tryParse(value.trim());
                            if (parsed == null || parsed < 0) {
                              return 'Enter a valid stock number';
                            }
                            return null;
                          },
                          onSaved: (value) => _stockText = value,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingL),

                  // Current Status Card
                  if (currentPrice != null || currentStock != null)
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spacingL),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.secondaryColor,
                            AppTheme.secondaryColor.withOpacity(0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius:
                            BorderRadius.circular(AppTheme.borderRadiusLarge),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.secondaryColor.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: AppTheme.spacingS),
                              Text(
                                'Current Status',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTheme.spacingM),
                          Row(
                            children: [
                              Expanded(
                                child: _StatusItem(
                                  label: 'Current Price',
                                  value: currentPrice != null
                                      ? '₦${(currentPrice as num).toStringAsFixed(2)}/KG'
                                      : 'Not set',
                                  icon: Icons.attach_money,
                                ),
                              ),
                              const SizedBox(width: AppTheme.spacingM),
                              Expanded(
                                child: _StatusItem(
                                  label: 'Available Stock',
                                  value: currentStock != null
                                      ? '${currentStock} KG'
                                      : 'Not set',
                                  icon: Icons.inventory_2,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: AppTheme.spacingL),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed:
                          _isSaving ? null : () => _save(snapshot.data),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.tertiaryColor,
                      ),
                      icon: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.save),
                      label: Text(_isSaving ? 'Saving...' : 'Update Pricing'),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingXl),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StatusItem extends StatelessWidget {
  const _StatusItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: Colors.white.withOpacity(0.8),
                size: 16,
              ),
              const SizedBox(width: AppTheme.spacingXs),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white.withOpacity(0.8),
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingXs),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}
