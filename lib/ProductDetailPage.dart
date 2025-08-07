import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProductDetailPage extends StatefulWidget {
  const ProductDetailPage({super.key});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  final _quantityController = TextEditingController();
  bool _isPlacingOrder = false;

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> placeOrder(Map<String, dynamic> product) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User not logged in")),
      );
      return;
    }

    if (_quantityController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter quantity")),
      );
      return;
    }

    setState(() => _isPlacingOrder = true);

    try {
      final dealerDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final data = dealerDoc.data();
      final dealerName = data?['name'] ?? data?['ProfileName'] ?? 'Anonymous Dealer';

      final String productId = product['productId'] ?? '';

      if (productId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invalid product ID")),
        );
        return;
      }

      await FirebaseFirestore.instance.collection('dealer_orders').add({
        'productId': productId,
        'productName': product['name'],
        'price': product['price'],
        'category': product['category'],
        'quantity': _quantityController.text,
        'farmerId': product['farmerId'],
        'farmerName': product['farmerName'],
        'dealerId': user.uid,
        'dealerName': dealerName,
        'acceptStatus': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Order placed successfully")),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed: $e")),
      );
    } finally {
      setState(() => _isPlacingOrder = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args == null || args is! Map<String, dynamic>) {
      return Scaffold(
        appBar: AppBar(title: const Text("Product Details")),
        body: const Center(child: Text("Invalid product data.")),
      );
    }

    final Map<String, dynamic> product = args;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Product Details"),
        backgroundColor: Colors.green[700],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text(
              product['name'] ?? 'No Name',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text("Category: ${product['category']}"),
            Text("Price: ₹${product['price']}"),
            Text("Farmer: ${product['farmerName']}"),
            const SizedBox(height: 20),

            TextFormField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Enter Quantity to Buy',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            _isPlacingOrder
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton.icon(
                    onPressed: () => placeOrder(product),
                    icon: const Icon(Icons.check),
                    label: const Text("Confirm Purchase"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 24),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
