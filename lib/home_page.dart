import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_page.dart';
import 'signup.dart';
import 'user_page.dart';
import 'product_categories_page.dart';
import 'nav_drawer.dart'; // Import the NavDrawer widget

class HomePage extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final Map<String, String> categories = {
    'Cakes': 'https://abakeshop.com/cdn/shop/collections/New_Styles_Collection_1200x798.jpg?v=1662591050',
    'Pastries': 'https://www.valio.fi/cdn-cgi/image/format=auto/https://cdn-wp.valio.fi/valio-wp-network/2023/10/Wienerit-12-scaled.jpg',
    'Desserts': 'https://images.ctfassets.net/0dkgxhks0leg/2W0e0i39df3qb9O05tsm8W/877bbaef4e6158eef162496144faf2f5/TF_20FW_22_20Dessert_20Collection_498.jpg',
    'Shop': 'https://www.posist.com/restaurant-times/wp-content/uploads/2016/10/A-Detailed-Guide-On-Starting-A-Bakery-Business-In-India-In-2023.jpg'
  };

  final List<Map<String, dynamic>> products = [
    {
      'name': 'Chocolate Cake',
      'price': 2500.0,
      'imageUrl': 'https://bluebowlrecipes.com/wp-content/uploads/2023/08/chocolate-truffle-cake-8844.jpg'
    },
    {
      'name': 'Vanilla Cake',
      'price': 2200.0,
      'imageUrl': 'https://www.eatingbirdfood.com/wp-content/uploads/2023/07/healthy-vanilla-cake-hero-500x375.jpg'
    },
    {
      'name': 'Strawberry Cake',
      'price': 2300.0,
      'imageUrl': 'https://amycakesbakes.com/wp-content/uploads/2021/07/Fresh-Strawberry-Cake-by-Amycakes-Bakes.jpg'
    },
    {
      'name': 'Blueberry Cake',
      'price': 2500.0,
      'imageUrl': 'https://amycakesbakes.com/wp-content/uploads/2022/05/Blueberry-Birthday-cake-with-frozen-blueberries.jpg'
    },
    {
      'name': 'Orange Cake',
      'price': 2800.0,
      'imageUrl': 'https://www.thesugarcoatedcottage.com/wp-content/uploads/2019/04/Vanilla-Orange-Almond-Cake-Recipe-3.jpg'
    },
    {
      'name': 'Pinacolada Cake',
      'price': 2700.0,
      'imageUrl': 'https://www.mycakeschool.com/images/2016/08/pina-colada-cake-featured-image.jpg'
    },
    // Add more products here...
  ];

  @override
  Widget build(BuildContext context) {
    final User? currentUser = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
        actions: [
          if (currentUser != null)
            IconButton(
              icon: Icon(Icons.account_circle),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => UserPage()),
                );
              },
            )
          else
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),
                );
              },
              child: Text(
                "Sign In",
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
            ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              if (currentUser != null) {
                await _auth.signOut();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),
                );
              }
            },
          ),
        ],
      ),
      drawer: NavDrawer(), // Add the NavDrawer here
      body: Padding(
        padding: const EdgeInsets.all(5.0),
        child: Column(
          children: [
            Container(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  String categoryName = categories.keys.elementAt(index);
                  String imageUrl = categories[categoryName] ?? '';
                  return CategoryTile(
                    category: categoryName,
                    imageUrl: imageUrl,
                  );
                },
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductCategoriesPage(),
                        ),
                      );
                    },
                    child: ProductTile(
                      productName: product['name'],
                      price: product['price'],
                      imageUrl: product['imageUrl'],
                      category: product['category'],
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
}

class CategoryTile extends StatelessWidget {
  final String category;
  final String imageUrl;

  CategoryTile({required this.category, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              image: DecorationImage(
                image: NetworkImage(imageUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(height: 5),
          Text(
            category,
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class ProductTile extends StatelessWidget {
  final String productName;
  final double price;
  final String imageUrl;

  ProductTile({
    required this.productName,
    required this.price,
    required this.imageUrl,
    required category,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 3,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.network(imageUrl, height: 100, width: 100),
          SizedBox(height: 10),
          Text(productName, style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 5),
          Text('Ksh $price'),
        ],
      ),
    );
  }
}
