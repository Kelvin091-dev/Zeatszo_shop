import 'package:cloud_firestore/cloud_firestore.dart';

class Shop {
  final String id;
  final String ownerId;
  final String name;
  final String address;
  final String phone;
  final String email;
  final String? logoUrl;
  final bool isActive;
  final DateTime createdAt;
  final Map<String, dynamic>? settings;

  Shop({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.address,
    required this.phone,
    required this.email,
    this.logoUrl,
    required this.isActive,
    required this.createdAt,
    this.settings,
  });

  factory Shop.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Shop(
      id: doc.id,
      ownerId: data['ownerId'] ?? '',
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'] ?? '',
      logoUrl: data['logoUrl'],
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      settings: data['settings'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'ownerId': ownerId,
      'name': name,
      'address': address,
      'phone': phone,
      'email': email,
      'logoUrl': logoUrl,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'settings': settings,
    };
  }
}
