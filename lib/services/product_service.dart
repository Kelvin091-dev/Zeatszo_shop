import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Product>> getShopProducts(String shopId) {
    return _firestore
        .collection('shops')
        .doc(shopId)
        .collection('products')
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();
    });
  }

  Future<Product?> getProductById(String shopId, String productId) async {
    try {
      final doc = await _firestore.collection('shops').doc(shopId).collection('products').doc(productId).get();
      if (doc.exists) {
        return Product.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> createProduct(String shopId, Product product) async {
    try {
      await _firestore.collection('shops').doc(shopId).collection('products').add(product.toFirestore());
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateProduct(String shopId, String productId, Product product) async {
    try {
      await _firestore.collection('shops').doc(shopId).collection('products').doc(productId).update(product.toFirestore());
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteProduct(String shopId, String productId) async {
    try {
      await _firestore.collection('shops').doc(shopId).collection('products').doc(productId).delete();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateProductAvailability(String shopId, String productId, bool available) async {
    try {
      await _firestore.collection('shops').doc(shopId).collection('products').doc(productId).update({
        'available': available,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateProductStock(String shopId, String productId, int quantity) async {
    try {
      await _firestore.collection('shops').doc(shopId).collection('products').doc(productId).update({
        'stockQuantity': quantity,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }
}
