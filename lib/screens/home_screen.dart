import 'package:flutter/material.dart';
import 'package:adminweb/screens/chat_screen.dart';
import 'package:adminweb/screens/product_screen.dart';
import 'package:adminweb/screens/categories_screen.dart';
import 'package:adminweb/screens/orders_screen.dart';
import 'package:adminweb/screens/users_screen.dart';
import 'package:adminweb/widgets/sidebar.dart';
import 'package:adminweb/widgets/app_bar.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Widget _currentScreen = ProductScreen();

  // This method will switch the content based on selected sidebar option
  void _updateScreen(String screen) {
    setState(() {
      switch (screen) {
        case 'chat':
          _currentScreen = AdminChatScreen();
          break;
        case 'products':
          _currentScreen = ProductScreen();
          break;
        case 'categories':
          _currentScreen = CategoryScreen();
          break;
        case 'orders':
          _currentScreen = AdminOrderManagementScreen();
          break;
        case 'users':
          _currentScreen = UsersScreen();
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWidget(),
      drawer: Sidebar(onItemTap: _updateScreen),
      body: Row(
        children: [
          // Sidebar stays on the left
          Container(
            width: 250,
            child: Sidebar(onItemTap: _updateScreen),
          ),
          // Main content area that changes dynamically
          Expanded(child: _currentScreen),
        ],
      ),
    );
  }
}
