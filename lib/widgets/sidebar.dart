import 'package:flutter/material.dart';

class Sidebar extends StatelessWidget {
  final Function(String) onItemTap;

  Sidebar({required this.onItemTap});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          ListTile(
            title: Text('Chat'),
            onTap: () => onItemTap('chat'),
          ),
          ListTile(
            title: Text('Products'),
            onTap: () => onItemTap('products'),
          ),
          ListTile(
            title: Text('Categories'),
            onTap: () => onItemTap('categories'),
          ),
          ListTile(
            title: Text('Orders'),
            onTap: () => onItemTap('orders'),
          ),
          ListTile(
            title: Text('Users'),
            onTap: () => onItemTap('users'),
          ),
        ],
      ),
    );
  }
}
