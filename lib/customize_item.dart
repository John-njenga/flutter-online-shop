import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CustomizeItem extends StatefulWidget {
  @override
  _CustomizeItemState createState() => _CustomizeItemState();
}

class _CustomizeItemState extends State<CustomizeItem> {
  String selectedFlavor = '';
  List<String> selectedToppings = [];
  String selectedTheme = '';
  double cakeSize = 1.0; // In kg
  int quantity = 1;
  double estimatedPrice = 0.0;
  Map<String, double> flavorPrices = {
    'Vanilla': 2200.0,
    'Chocolate': 2300.0,
    'Strawberry': 2300.0,
    'Red Velvet': 2400.0,
    'Lemon': 2200.0,
    'Blueberry': 2500.0,
    'Pinacolada': 2400.0,
    'Bubblegum': 2500.0,
    'Orange': 2500.0,
    'Multiple Flavored': 2700.0,
  }; // Predefined flavor prices
  List<String> flavors = ['Vanilla', 'Chocolate', 'Strawberry', 'Red Velvet', 'Lemon', 'Blueberry', 'Pinacolada', 'Orange', 'Bubblegum', 'Multiple flavored']; // Predefined list of flavors
  String additionalDescription = ''; // Store additional description

  final List<String> themes = ['Birthday', 'Wedding', 'Graduation'];

  // Calculate price based on selected flavor, size, quantity, and toppings
  void calculatePrice() {
    double basePrice = flavorPrices[selectedFlavor] ?? 2500.0; // Default to 2500 if no flavor selected

    // Additional price for toppings
    double toppingPrice = 0.0;
    if (selectedToppings.contains('Fondant')) {
      toppingPrice += 500.0 * cakeSize; // Add 500 per kg for Fondant
    }
    if (selectedToppings.contains('Hard Icing')) {
      toppingPrice += 700.0 * cakeSize; // Add 700 per kg for Hard Icing
    }

    setState(() {
      estimatedPrice = (basePrice * cakeSize * quantity) + toppingPrice; // Total price based on size, quantity, and toppings
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Customize Your Cake'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView( // Scrollable view
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Enter Size (kg):'),
              TextField(
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter cake size in kg',
                ),
                onChanged: (value) {
                  setState(() {
                    cakeSize = double.tryParse(value) ?? 1.0; // Parse the input and default to 1.0 if invalid
                    calculatePrice(); // Update price when size changes
                  });
                },
              ),
              SizedBox(height: 16),
              Text('Quantity: $quantity'),
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.remove),
                    onPressed: () {
                      setState(() {
                        if (quantity > 1) {
                          quantity--;
                          calculatePrice(); // Update price when quantity changes
                        }
                      });
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.add),
                    onPressed: () {
                      setState(() {
                        quantity++;
                        calculatePrice(); // Update price when quantity changes
                      });
                    },
                  ),
                ],
              ),
              Text('Select Flavor:'),
              DropdownButton<String>(
                value: selectedFlavor.isEmpty ? null : selectedFlavor,
                hint: Text('Choose a flavor'),
                items: flavors.map((flavor) {
                  return DropdownMenuItem<String>(
                    value: flavor,
                    child: Text(flavor),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedFlavor = value ?? '';
                    calculatePrice(); // Update price on flavor change
                  });
                },
              ),
              Text('Select Toppings:'),
              Wrap(
                spacing: 8.0,
                children: [
                  for (String topping in ['Fondant', 'Hard Icing'])
                    ChoiceChip(
                      label: Text(topping),
                      selected: selectedToppings.contains(topping),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            selectedToppings.add(topping);
                          } else {
                            selectedToppings.remove(topping);
                          }
                          calculatePrice(); // Update price on topping selection change
                        });
                      },
                    ),
                ],
              ),
              Text('Select Theme:'),
              DropdownButton<String>(
                value: selectedTheme.isEmpty ? null : selectedTheme,
                hint: Text('Choose a theme'),
                items: themes.map((theme) {
                  return DropdownMenuItem<String>(
                    value: theme,
                    child: Text(theme),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedTheme = value ?? '';
                    calculatePrice(); // Update price on theme change
                  });
                },
              ),
              SizedBox(height: 20),
              Text('Additional Description:'),
              TextField(
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter any additional details or instructions here',
                ),
                maxLines: 3,
                onChanged: (value) {
                  setState(() {
                    additionalDescription = value; // Update additional description
                  });
                },
              ),
              SizedBox(height: 20),
              Text('Estimated Price: Ksh ${estimatedPrice.toStringAsFixed(2)}'),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  // Handle customization submission, including additionalDescription
                },
                child: Text('Submit Customization'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
