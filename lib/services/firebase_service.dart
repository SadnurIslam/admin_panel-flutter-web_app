import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Fetch all products from Firestore
  Future<List<Map<String, dynamic>>> getProducts() async {
    var querySnapshot = await _db.collection('products').get();
    return querySnapshot.docs.map((doc) => doc.data()).toList();
  }

  // Add new product to Firestore
  Future<void> addProduct(Map<String, dynamic> productData) async {
    await _db.collection('products').add(productData);
  }

  // Update an existing product
  Future<void> updateProduct(
      String productId, Map<String, dynamic> productData) async {
    await _db.collection('products').doc(productId).update(productData);
  }

  // Delete a product
  Future<void> deleteProduct(String productId) async {
    await _db.collection('products').doc(productId).delete();
  }
}
