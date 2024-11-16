import 'package:flutter/material.dart';
import 'home_page.dart';
import 'login_page.dart';
import 'contact_us_page.dart';
import 'product_categories_page.dart';
import 'cart_items_page.dart';
//import 'payment_page.dart';
import 'landing_page.dart'; // Import landing page
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CakesByDarQ',
      theme: ThemeData(primarySwatch: Colors.pink),
      initialRoute: '/landing', // Set LandingPage as the initial route
      routes: {
        '/': (context) => HomePage(),
        '/landing': (context) => LandingPage(), // Add the landing page route
        '/categories': (context) => ProductCategoriesPage(),
        '/cart': (context) => CartItemsPage(),
        '/login': (context) => LoginPage(),
        '/contactus': (context) => ContactUsPage(),
      },
    );
  }
}
