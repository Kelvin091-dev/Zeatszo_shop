import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/shop.dart';

class ShopService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Shop?> getShopByOwnerId(String ownerId) async {
    try {
      final querySnapshot = await _firestore.collection('shops').where('ownerId', isEqualTo: ownerId).limit(1).get();

      if (querySnapshot.docs.isNotEmpty) {
        return Shop.fromFirestore(querySnapshot.docs.first);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<Shop?> getShopById(String shopId) async {
    try {
      final doc = await _firestore.collection('shops').doc(shopId).get();
      if (doc.exists) {
        return Shop.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> createShop(Shop shop) async {
    try {
      await _firestore.collection('shops').add(shop.toFirestore());
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateShop(String shopId, Shop shop) async {
    try {
      await _firestore.collection('shops').doc(shopId).update(shop.toFirestore());
    } catch (e) {
      rethrow;
    }
  }

  Stream<Shop?> streamShop(String shopId) {
    return _firestore.collection('shops').doc(shopId).snapshots().map((doc) {
      if (doc.exists) {
        return Shop.fromFirestore(doc);
      }
      return null;
    });
  }
}
