import 'package:cloud_firestore/cloud_firestore.dart';

class ProductService {
  // Delete product by ID
  static Future<void> deleteProduct(String productId) async {
    await FirebaseFirestore.instance
        .collection('products')
        .doc(productId)
        .delete();
  }

  // Add a new product to Firestore (Example method for adding products)
  static Future<void> addProduct(Map<String, dynamic> product) async {
    await FirebaseFirestore.instance.collection('products').add(product);
  }

  // Edit product details
  static Future<void> editProduct(
      String productId, Map<String, dynamic> updatedProduct) async {
    await FirebaseFirestore.instance
        .collection('products')
        .doc(productId)
        .update(updatedProduct);
  }
}
