import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:adminweb/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase configuration for your web app
  const firebaseConfig = FirebaseOptions(
    apiKey: "AIzaSyDLWKmQHOPfj9UVO1JDnuCuw5AkKEAZZSI",
    authDomain: "grocery-app-46483.firebaseapp.com",
    projectId: "grocery-app-46483",
    storageBucket: "grocery-app-46483.firebasestorage.app",
    messagingSenderId: "916184582101",
    appId: "1:916184582101:web:c441f1b27c1331dbabdf5c",
    measurementId: "G-JZW2EFHHBR",
  );

  // Initialize Firebase
  await Firebase.initializeApp(options: firebaseConfig);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Web Admin Panel',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomeScreen(), // Your HomeScreen widget
    );
  }
}
