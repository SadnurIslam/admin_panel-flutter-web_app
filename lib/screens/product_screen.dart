import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductScreen extends StatefulWidget {
  @override
  _ProductScreenState createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Product Management'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search bar and Add Button
            Row(
              children: [
                Expanded(
                  flex: 8,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchTerm = value;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Search Products',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.grey[200],
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _showAddProductDialog();
                    },
                    icon: Icon(Icons.add),
                    label: Text('Add Product'),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Product Table
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('products')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text('No products found.'));
                  }

                  var products = snapshot.data!.docs.where((doc) {
                    var name = doc['name'] as String;
                    return name
                        .toLowerCase()
                        .contains(_searchTerm.toLowerCase());
                  }).toList();

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: [
                        DataColumn(label: Text('Name')),
                        DataColumn(label: Text('Weight')),
                        DataColumn(label: Text('Price')),
                        DataColumn(label: Text('Discount Price')),
                        DataColumn(label: Text('Category')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: products.map((product) {
                        return DataRow(cells: [
                          DataCell(Text(product['name'])),
                          DataCell(Text(product['weight'])),
                          DataCell(Text('\$${product['price']}')),
                          DataCell(Text('\$${product['discountPrice']}')),
                          DataCell(FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('categories')
                                .doc(product['categoryId'])
                                .get(),
                            builder: (context, categorySnapshot) {
                              if (categorySnapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return Text('Loading...');
                              }

                              if (categorySnapshot.hasError ||
                                  !categorySnapshot.hasData) {
                                return Text('Unknown');
                              }

                              var category = categorySnapshot.data!;
                              return Text(category['name'] ?? 'Unknown');
                            },
                          )),
                          DataCell(Row(
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit, color: Colors.blue),
                                onPressed: () {
                                  _showEditProductDialog(product);
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  FirebaseFirestore.instance
                                      .collection('products')
                                      .doc(product.id)
                                      .delete();
                                },
                              ),
                            ],
                          )),
                        ]);
                      }).toList(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Show Add Product Dialog
  void _showAddProductDialog() {
    var _nameController = TextEditingController();
    var _weightController = TextEditingController();
    var _priceController = TextEditingController();
    var _discountPriceController = TextEditingController();
    var _imageUrlController = TextEditingController();

    String? selectedCategoryId;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add New Product'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                _buildTextField(_nameController, 'Name'),
                SizedBox(height: 8),
                _buildTextField(_weightController, 'Weight'),
                _buildTextField(_priceController, 'Price', isNumber: true),
                SizedBox(height: 8),
                _buildTextField(_discountPriceController, 'Discount Price',
                    isNumber: true),
                SizedBox(height: 8),
                _buildTextField(_imageUrlController, 'Image URL'),
                SizedBox(height: 8),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('categories')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return CircularProgressIndicator();
                    }

                    var categories = snapshot.data!.docs;

                    return DropdownButtonFormField<String>(
                      value: selectedCategoryId,
                      onChanged: (value) {
                        setState(() {
                          selectedCategoryId = value;
                        });
                      },
                      items: categories.map((category) {
                        return DropdownMenuItem(
                          value: category.id,
                          child: Text(category['name']),
                        );
                      }).toList(),
                      decoration: InputDecoration(labelText: 'Select Category'),
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                FirebaseFirestore.instance.collection('products').add({
                  'name': _nameController.text,
                  'weight': _weightController.text,
                  'price': double.tryParse(_priceController.text) ?? 0,
                  'discountPrice':
                      double.tryParse(_discountPriceController.text) ?? 0,
                  'imageUrl': _imageUrlController.text,
                  'categoryId': selectedCategoryId,
                });
                Navigator.pop(context);
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // Show Edit Product Dialog
  void _showEditProductDialog(QueryDocumentSnapshot product) {
    var _nameController = TextEditingController(text: product['name']);
    var _priceController =
        TextEditingController(text: product['price'].toString());
    var _discountPriceController =
        TextEditingController(text: product['discountPrice'].toString());
    var _imageUrlController = TextEditingController(text: product['imageUrl']);
    String? selectedCategoryId = product['categoryId'];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Product'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                _buildTextField(_nameController, 'Name'),
                SizedBox(height: 8),
                _buildTextField(_priceController, 'Price', isNumber: true),
                SizedBox(height: 8),
                _buildTextField(_discountPriceController, 'Discount Price',
                    isNumber: true),
                SizedBox(height: 8),
                _buildTextField(_imageUrlController, 'Image URL'),
                SizedBox(height: 8),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('categories')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return CircularProgressIndicator();
                    }

                    var categories = snapshot.data!.docs;

                    return DropdownButtonFormField<String>(
                      value: selectedCategoryId,
                      onChanged: (value) {
                        setState(() {
                          selectedCategoryId = value;
                        });
                      },
                      items: categories.map((category) {
                        return DropdownMenuItem(
                          value: category.id,
                          child: Text(category['name']),
                        );
                      }).toList(),
                      decoration: InputDecoration(labelText: 'Select Category'),
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                FirebaseFirestore.instance
                    .collection('products')
                    .doc(product.id)
                    .update({
                  'name': _nameController.text,
                  'price': double.tryParse(_priceController.text) ?? 0,
                  'discountPrice':
                      double.tryParse(_discountPriceController.text) ?? 0,
                  'imageUrl': _imageUrlController.text,
                  'categoryId': selectedCategoryId,
                });
                Navigator.pop(context);
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
      ),
    );
  }
}
