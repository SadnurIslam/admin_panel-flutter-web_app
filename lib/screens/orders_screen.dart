import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminOrderManagementScreen extends StatefulWidget {
  @override
  _AdminOrderManagementScreenState createState() =>
      _AdminOrderManagementScreenState();
}

class _AdminOrderManagementScreenState
    extends State<AdminOrderManagementScreen> {
  String _searchTerm = '';

  // Fetch orders for each user from Firestore
  Future<List<Map<String, dynamic>>> _fetchOrders() async {
    List<Map<String, dynamic>> ordersList = [];

    try {
      // Fetch all users
      QuerySnapshot userSnapshot =
          await FirebaseFirestore.instance.collection('users').get();

      // Loop through each user to fetch their orders
      for (var userDoc in userSnapshot.docs) {
        String userId = userDoc.id;
        String name = userDoc['name'] ?? 'No Name';
        String address = userDoc['address'] ?? 'No Address';
        String phone = userDoc['phone'] ?? 'No Phone';

        // Fetch orders for the current user
        QuerySnapshot orderSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('orders')
            .get();

        for (var orderDoc in orderSnapshot.docs) {
          ordersList.add({
            'userId': userId,
            'name': name,
            'address': address,
            'phone': phone,
            'orderId': orderDoc.id,
            'paymentMethod': orderDoc['paymentMethod'],
            'status': orderDoc['status'],
            'timestamp': orderDoc['timestamp'],
            'totalPrice': orderDoc['totalPrice'],
            'products': orderDoc['products'],
          });
        }
      }
    } catch (e) {
      // Log the error to help debug
      print('Error fetching orders: $e');
      throw 'Error fetching orders: $e';
    }

    return ordersList;
  }

  // Remove order from Firestore
  Future<void> _removeOrder(String userId, String orderId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('orders')
          .doc(orderId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order removed successfully.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error removing order: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Order Management'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search bar to filter orders by user name
            TextField(
              onChanged: (value) {
                setState(() {
                  _searchTerm = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                labelText: 'Search Orders by User Name',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),

            // Order List
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _fetchOrders(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                        child:
                            Text('Error fetching orders: ${snapshot.error}'));
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text('No orders found.'));
                  }

                  var orders = snapshot.data!
                      .where((order) => order['name']
                          .toString()
                          .toLowerCase()
                          .contains(_searchTerm))
                      .toList();

                  return ListView.builder(
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      var order = orders[index];
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 8.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 5,
                        child: ListTile(
                          contentPadding: EdgeInsets.all(16.0),
                          title: Text(
                            'Order ID: ${order['orderId']}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('User: ${order['name']}'),
                              Text('Address: ${order['address']}'),
                              Text('Phone: ${order['phone']}'),
                              Text('Payment Method: ${order['paymentMethod']}'),
                              Text('Status: ${order['status']}'),
                              Text('Total Price: \$${order['totalPrice']}'),
                            ],
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              _removeOrder(order['userId'], order['orderId']);
                            },
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
