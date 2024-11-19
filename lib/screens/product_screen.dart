import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductScreen extends StatefulWidget {
  @override
  _ProductScreenState createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';

  // Function to fetch products from Firestore
  Future<List<Map<String, dynamic>>> _fetchProducts() async {
    QuerySnapshot querySnapshot =
        await FirebaseFirestore.instance.collection('products').get();

    List<Map<String, dynamic>> products = [];
    for (var doc in querySnapshot.docs) {
      products.add(doc.data() as Map<String, dynamic>);
    }

    // Perform case-insensitive and substring search locally
    if (_searchTerm.isNotEmpty) {
      products = products.where((product) {
        return product['name']
            .toLowerCase()
            .contains(_searchTerm.toLowerCase());
      }).toList();
    }

    return products;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Products Management'),
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
                      // Handle Add New Product
                    },
                    icon: Icon(Icons.add),
                    label: Text('Add New Product'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Product Table
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _fetchProducts(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text('No products found.'));
                  }

                  var products = snapshot.data!;

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints:
                              BoxConstraints(minWidth: constraints.maxWidth),
                          child: DataTable(
                            columnSpacing: constraints.maxWidth * 0.05,
                            columns: [
                              DataColumn(label: Text('Name')),
                              DataColumn(label: Text('Price')),
                              DataColumn(label: Text('Discount Price')),
                              DataColumn(label: Text('Category')),
                              DataColumn(label: Text('Actions')),
                            ],
                            rows: products.map((product) {
                              return DataRow(cells: [
                                DataCell(Text(product['name'])),
                                DataCell(Text('\$${product['price']}')),
                                DataCell(Text('\$${product['discountPrice']}')),
                                DataCell(FutureBuilder<QuerySnapshot>(
                                  future: FirebaseFirestore.instance
                                      .collection('categories')
                                      .where('id',
                                          isEqualTo: product['categoryId'])
                                      .get(),
                                  builder: (context, categorySnapshot) {
                                    if (categorySnapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return Text('Loading...');
                                    }

                                    if (categorySnapshot.hasError) {
                                      return Text('Error');
                                    }

                                    if (categorySnapshot.data!.docs.isEmpty) {
                                      return Text('Category not found');
                                    }

                                    var category =
                                        categorySnapshot.data!.docs.first;
                                    return Text(category['name'] ?? 'Unknown');
                                  },
                                )),
                                DataCell(Row(
                                  children: [
                                    IconButton(
                                      icon:
                                          Icon(Icons.edit, color: Colors.blue),
                                      onPressed: () {
                                        // Handle Edit Product
                                      },
                                    ),
                                    IconButton(
                                      icon:
                                          Icon(Icons.delete, color: Colors.red),
                                      onPressed: () {
                                        // Delete product (implement delete logic)
                                      },
                                    ),
                                  ],
                                )),
                              ]);
                            }).toList(),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
