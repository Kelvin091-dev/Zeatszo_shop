import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../auth/auth_service.dart';
import '../services/shop_service.dart';
import '../theme/app_theme.dart';

/// Profile screen for a shopkeeper to edit shop details.
///
/// Data location:
/// - Document path: `shops/{shopId}/profile`
/// - Example fields:
///   - `name`: String
///   - `address`: String
///   - `phone`: String
///   - `imageUrl`: String (download URL from Firebase Storage)
///
/// Supports onboarding flow via [onSaveComplete] callback.
class ShopProfileScreen extends StatefulWidget {
  const ShopProfileScreen({
    super.key,
    required this.shopId,
    this.onSaveComplete,
  });

  final String shopId;

  /// Optional callback called after successful save (used for onboarding flow)
  final VoidCallback? onSaveComplete;

  @override
  State<ShopProfileScreen> createState() => _ShopProfileScreenState();
}

class _ShopProfileScreenState extends State<ShopProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _name;
  String? _address;
  String? _phone;
  XFile? _selectedImage;

  bool _isSaving = false;
  bool _isLoggingOut = false;

  /// Returns true if shopId is valid and user is logged in
  bool get _hasValidShopId => widget.shopId.isNotEmpty;

  /// FIXED: Document path must have EVEN segments (collection/doc/collection/doc)
  /// 
  /// Old (BROKEN): 'shops/{shopId}/profile' = 3 segments = COLLECTION
  /// New (FIXED):  'shops/{shopId}/profile/info' = 4 segments = DOCUMENT
  DocumentReference<Map<String, dynamic>> get _docRef =>
      FirebaseFirestore.instance
          .collection('shops')
          .doc(widget.shopId)
          .collection('profile')
          .doc('info');

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _selectedImage = picked;
      });
    }
  }

  Future<String?> _uploadImageIfNeeded() async {
    if (_selectedImage == null) {
      debugPrint('🔵 DEBUG: No image selected, skipping upload');
      return null;
    }

    // DEBUG: Log the shopId being used
    final shopId = widget.shopId;
    debugPrint('═══════════════════════════════════════════');
    debugPrint('🔵 DEBUG: Starting image upload');
    debugPrint('🔵 DEBUG: widget.shopId = "$shopId"');
    debugPrint('🔵 DEBUG: shopId.isEmpty = ${shopId.isEmpty}');
    debugPrint('🔵 DEBUG: shopId.length = ${shopId.length}');
    
    if (shopId.isEmpty) {
      debugPrint('❌ ERROR: shopId is EMPTY! Cannot upload.');
      throw Exception('Shop ID is empty - cannot upload image');
    }

    try {
      final file = File(_selectedImage!.path);
      debugPrint('🔵 DEBUG: File path = ${file.path}');
      
      // Verify file exists before uploading
      final fileExists = await file.exists();
      debugPrint('🔵 DEBUG: File exists = $fileExists');
      
      if (!fileExists) {
        debugPrint('❌ ERROR: Image file does not exist at path: ${_selectedImage!.path}');
        throw Exception('Selected image file not found');
      }
      
      final fileSize = await file.length();
      debugPrint('🔵 DEBUG: File size = $fileSize bytes');

      // Create storage reference - use EXACT same ref for upload AND download URL
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('shops')
          .child(shopId)
          .child('profile.jpg');

      debugPrint('🔵 DEBUG: Storage ref created');
      debugPrint('🔵 DEBUG: storageRef.fullPath = "${storageRef.fullPath}"');
      debugPrint('🔵 DEBUG: storageRef.bucket = "${storageRef.bucket}"');
      debugPrint('📤 UPLOADING to: ${storageRef.fullPath}');

      // Upload the file
      final uploadTask = storageRef.putFile(
        file,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      debugPrint('🔵 DEBUG: putFile() called, awaiting completion...');

      // Wait for upload to complete
      final taskSnapshot = await uploadTask;

      debugPrint('🔵 DEBUG: Upload task completed');
      debugPrint('🔵 DEBUG: taskSnapshot.state = ${taskSnapshot.state}');
      debugPrint('🔵 DEBUG: taskSnapshot.bytesTransferred = ${taskSnapshot.bytesTransferred}');
      debugPrint('🔵 DEBUG: taskSnapshot.totalBytes = ${taskSnapshot.totalBytes}');
      debugPrint('🔵 DEBUG: taskSnapshot.ref.fullPath = "${taskSnapshot.ref.fullPath}"');

      // Verify upload was successful
      if (taskSnapshot.state != TaskState.success) {
        debugPrint('❌ ERROR: Upload state is NOT success: ${taskSnapshot.state}');
        throw Exception('Image upload did not complete successfully');
      }

      debugPrint('✅ Upload SUCCESS! Bytes: ${taskSnapshot.bytesTransferred}');
      
      // Get download URL from the SAME reference used for upload
      debugPrint('🔵 DEBUG: Calling getDownloadURL() on storageRef...');
      debugPrint('🔵 DEBUG: storageRef.fullPath for URL = "${storageRef.fullPath}"');
      
      final downloadUrl = await storageRef.getDownloadURL();
      
      debugPrint('✅ Download URL obtained: $downloadUrl');
      debugPrint('═══════════════════════════════════════════');
      
      return downloadUrl;
    } on FirebaseException catch (e) {
      debugPrint('═══════════════════════════════════════════');
      debugPrint('❌ FIREBASE ERROR:');
      debugPrint('❌ Code: ${e.code}');
      debugPrint('❌ Message: ${e.message}');
      debugPrint('❌ Plugin: ${e.plugin}');
      debugPrint('═══════════════════════════════════════════');
      rethrow;
    } catch (e, stackTrace) {
      debugPrint('═══════════════════════════════════════════');
      debugPrint('❌ GENERAL ERROR: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      debugPrint('═══════════════════════════════════════════');
      rethrow;
    }
  }

  Future<void> _save(DocumentSnapshot<Map<String, dynamic>>? currentSnap) async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();

    setState(() {
      _isSaving = true;
    });

    try {
      final currentData = currentSnap?.data() ?? <String, dynamic>{};

      final name = _name ?? currentData['name'] as String?;
      final address = _address ?? currentData['address'] as String?;
      final phone = _phone ?? currentData['phone'] as String?;

      final imageUrl = await _uploadImageIfNeeded() ??
          (currentData['imageUrl'] as String?);

      final updateData = <String, dynamic>{};

      if (name != null && name.isNotEmpty) updateData['name'] = name;
      if (address != null && address.isNotEmpty) {
        updateData['address'] = address;
      }
      if (phone != null && phone.isNotEmpty) updateData['phone'] = phone;
      if (imageUrl != null && imageUrl.isNotEmpty) {
        updateData['imageUrl'] = imageUrl;
      }

      if (updateData.isNotEmpty) {
        // Save to subcollection (existing behavior)
        await _docRef.set(updateData, SetOptions(merge: true));

        // CRITICAL: Also sync to ROOT shop document at shops/{shopId}
        // This ensures the shop appears in Firestore UI and user app queries
        await ShopService.instance.syncProfileToRootDocument(
          shopId: widget.shopId,
          shopName: name,
          address: address,
          phone: phone,
          imageUrl: imageUrl,
        );
      }

      if (mounted) {
        // Only show snackbar if NOT in onboarding mode
        // (onboarding flow handles its own messages)
        if (widget.onSaveComplete == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Profile updated successfully'),
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
            content: Text('Failed to update profile: $e'),
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

  Future<void> _logout() async {
    // Show confirmation dialog
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout != true) return;

    setState(() {
      _isLoggingOut = true;
    });

    try {
      await AuthService.instance.signOut();
      // After sign-out, the auth stream will automatically redirect to login
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to logout: $e'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() {
          _isLoggingOut = false;
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
          title: const Text('Shop Profile'),
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
                'Please login to view your profile',
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
        title: const Text('Shop Profile'),
        actions: [
          // Logout button in app bar
          IconButton(
            onPressed: _isLoggingOut ? null : _logout,
            icon: _isLoggingOut
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
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
          // Missing document is NOT an error - it just means user hasn't set profile yet
          // We show empty/default values and let them fill in the form
          
          // Only log errors for debugging - don't block UI
          if (snapshot.hasError) {
            debugPrint('Profile error (non-blocking): ${snapshot.error}');
            // Don't block UI - just log and continue with empty data
          }

          // Extract data - will be empty map if document doesn't exist (NOT an error!)
          final data = snapshot.data?.data() ?? <String, dynamic>{};

          final currentName = data['name'] as String?;
          final currentAddress = data['address'] as String?;
          final currentPhone = data['phone'] as String?;
          final currentImageUrl = data['imageUrl'] as String?;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Image Section
                  Center(
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            Container(
                              height: 120,
                              width: 120,
                              decoration: BoxDecoration(
                                color: AppTheme.alternateColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppTheme.primaryColor.withOpacity(0.3),
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: _selectedImage != null
                                  ? Image.file(
                                      File(_selectedImage!.path),
                                      fit: BoxFit.cover,
                                    )
                                  : (currentImageUrl != null &&
                                          currentImageUrl.isNotEmpty)
                                      ? Image.network(
                                          currentImageUrl,
                                          fit: BoxFit.cover,
                                        )
                                      : Icon(
                                          Icons.store,
                                          size: 48,
                                          color: AppTheme.secondaryText,
                                        ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _pickImage,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.primaryColor
                                            .withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.spacingS),
                        Text(
                          'Tap to change shop image',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.secondaryText,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingXl),

                  // Shop Details Section
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
                                color: AppTheme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(
                                    AppTheme.borderRadiusSmall),
                              ),
                              child: Icon(
                                Icons.store_mall_directory,
                                color: AppTheme.primaryColor,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: AppTheme.spacingM),
                            Text(
                              'Shop Details',
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
                          key: ValueKey('name_${currentName ?? ''}'),
                          initialValue: currentName ?? '',
                          decoration: const InputDecoration(
                            labelText: 'Shop Name',
                            prefixIcon: Icon(Icons.storefront),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Enter shop name';
                            }
                            return null;
                          },
                          onSaved: (value) => _name = value?.trim(),
                        ),
                        const SizedBox(height: AppTheme.spacingM),
                        TextFormField(
                          key: ValueKey('address_${currentAddress ?? ''}'),
                          initialValue: currentAddress ?? '',
                          decoration: const InputDecoration(
                            labelText: 'Address',
                            prefixIcon: Icon(Icons.location_on),
                          ),
                          maxLines: 2,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Enter address';
                            }
                            return null;
                          },
                          onSaved: (value) => _address = value?.trim(),
                        ),
                        const SizedBox(height: AppTheme.spacingM),
                        TextFormField(
                          key: ValueKey('phone_${currentPhone ?? ''}'),
                          initialValue: currentPhone ?? '',
                          decoration: const InputDecoration(
                            labelText: 'Phone Number',
                            prefixIcon: Icon(Icons.phone),
                          ),
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Enter phone number';
                            }
                            if (value.trim().length < 7) {
                              return 'Enter a valid phone number';
                            }
                            return null;
                          },
                          onSaved: (value) => _phone = value?.trim(),
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
                      label: Text(_isSaving ? 'Saving...' : 'Save Changes'),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingL),

                  // Logout Section
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacingL),
                    decoration: BoxDecoration(
                      color: AppTheme.error.withOpacity(0.05),
                      borderRadius:
                          BorderRadius.circular(AppTheme.borderRadiusLarge),
                      border: Border.all(
                        color: AppTheme.error.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.logout,
                              color: AppTheme.error,
                              size: 20,
                            ),
                            const SizedBox(width: AppTheme.spacingS),
                            Text(
                              'Account',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.error,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.spacingM),
                        Text(
                          'Sign out from your account. You will need to login again to access the dashboard.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.secondaryText,
                              ),
                        ),
                        const SizedBox(height: AppTheme.spacingM),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _isLoggingOut ? null : _logout,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.error,
                              side: BorderSide(color: AppTheme.error),
                            ),
                            icon: _isLoggingOut
                                ? SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          AppTheme.error),
                                    ),
                                  )
                                : const Icon(Icons.logout),
                            label:
                                Text(_isLoggingOut ? 'Logging out...' : 'Logout'),
                          ),
                        ),
                      ],
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
