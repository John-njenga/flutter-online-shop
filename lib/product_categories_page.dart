import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'cart_items_page.dart';
import 'customize_item.dart';

class ProductCategoriesPage extends StatefulWidget {
  @override
  _ProductCategoriesPageState createState() => _ProductCategoriesPageState();
}

class _ProductCategoriesPageState extends State<ProductCategoriesPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Products'),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(6.0),
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('Product').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text('No products found'));
                  }

                  final products = snapshot.data!.docs;
                  return GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 6,
                      mainAxisSpacing: 6,
                      childAspectRatio: 0.46,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final doc = products[index];
                      final productName = doc['name'] ?? 'Unnamed';
                      final productImage = doc['imageUrl'] ?? '';
                      final productPrice = (doc['price'] as num?)?.toDouble() ?? 0.0;
                      final productCategory = doc['category'] ?? 'Uncategorized';

                      return ProductTile(
                        productName: productName,
                        imageUrl: productImage,
                        price: productPrice,
                        category: productCategory,
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CustomizeItem()),
                  );
                },
                child: Text(
                  'Customize Your Cake',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  textStyle: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('Cart').snapshots(),
        builder: (context, snapshot) {
          int cartItemCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
          return _buildCartButton(context, itemCount: cartItemCount);
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      bottomNavigationBar: BottomAppBar(
        shape: CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Container(height: 50.0),
      ),
    );
  }

  Widget _buildCartButton(BuildContext context, {required int itemCount}) {
    return FloatingActionButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => CartItemsPage()),
        );
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.shopping_cart),
          if (itemCount > 0)
            Positioned(
              right: 0,
              child: CircleAvatar(
                radius: 10,
                backgroundColor: Colors.red,
                child: Text(
                  '$itemCount',
                  style: TextStyle(fontSize: 12, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
      tooltip: 'View Cart',
    );
  }
}

class ProductTile extends StatelessWidget {
  final String productName;
  final String imageUrl;
  final double price;
  final String category;

  ProductTile({
    required this.productName,
    required this.imageUrl,
    required this.price,
    required this.category,
  });

  void _addToCart(BuildContext context) async {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // Show a dialog prompting the user to log in
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Please Log In'),
          content: Text('You need to be logged in to add items to the cart.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Navigate to the login page
                Navigator.pushNamed(context, '/login');
              },
              child: Text('Log In'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
          ],
        ),
      );
    } else {
      // User is logged in, proceed to add the item to the cart
      final cartItem = CartItem(
        userId: user.uid,
        name: productName,
        price: price,
        imageUrl: imageUrl,
        category: category,
        quantity: 1,
      );

      FirebaseFirestore.instance.collection('Cart').add(cartItem.toMap()).then((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$productName added to cart!')),
        );
      }).catchError((error) {
        print('Error adding to cart: $error');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add $productName to cart')),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(6.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network(
              imageUrl,
              height: 100,
              width: 100,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Icon(Icons.error, color: Colors.red),
            ),
            SizedBox(height: 7),
            Text(productName, style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 2),
            Text('Ksh $price'),
            SizedBox(height: 2),
            Text(category, style: TextStyle(color: Colors.blueGrey)),
            SizedBox(height: 6),
            Align(
              alignment: Alignment.bottomCenter,
              child: ElevatedButton(
                onPressed: () => _addToCart(context),
                child: Text(
                  'Buy',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(60, 25),
                  backgroundColor: Colors.blueAccent,
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CartItem {
  final String userId;
  final String name;
  final double price;
  final String imageUrl;
  final String category;
  int quantity;

  CartItem({
    required this.userId,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.category,
    this.quantity = 1,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'price': price,
      'imageUrl': imageUrl,
      'category': category,
      'quantity': quantity,
    };
  }
}
