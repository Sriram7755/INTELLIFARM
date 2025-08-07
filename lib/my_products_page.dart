import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'EditProductPage.dart';
import 'ViewOffersPage.dart';

class MyProductsPage extends StatelessWidget {
  const MyProductsPage({super.key});

  void _deleteProduct(String productId, BuildContext context) async {
    try {
      await FirebaseFirestore.instance.collection('products').doc(productId).delete();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Product deleted')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _editProduct(BuildContext context, Map<String, dynamic> productData, String productId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditProductPage(productData: productData, productId: productId),
      ),
    );
  }

  Future<String?> _getDealerName(String productId) async {
    final ordersSnapshot = await FirebaseFirestore.instance
        .collection('dealer_orders')
        .where('productId', isEqualTo: productId)
        .where('acceptStatus', isEqualTo: 'accepted')
        .get();

    if (ordersSnapshot.docs.isNotEmpty) {
      final dealerId = ordersSnapshot.docs.first['dealerId'] as String?;
      if (dealerId != null) {
        final dealerDoc = await FirebaseFirestore.instance.collection('users').doc(dealerId).get();
        return dealerDoc.data()?['name'] as String?;
      }
    }
    return null;
  }

  Future<bool> _hasAcceptedOffer(String productId, bool isNegotiable) async {
    if (isNegotiable) {
      final offerSnapshot = await FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .collection('offers')
          .where('status', isEqualTo: 'accepted')
          .get();
      return offerSnapshot.docs.isNotEmpty;
    } else {
      final ordersSnapshot = await FirebaseFirestore.instance
          .collection('dealer_orders')
          .where('productId', isEqualTo: productId)
          .where('acceptStatus', isEqualTo: 'accepted')
          .get();
      return ordersSnapshot.docs.isNotEmpty;
    }
  }

  Future<int> _getOfferCount(String productId, bool isNegotiable) async {
    if (isNegotiable) {
      final offerSnapshot = await FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .collection('offers')
          .get();
      return offerSnapshot.docs.length;
    } else {
      final ordersSnapshot = await FirebaseFirestore.instance
          .collection('dealer_orders')
          .where('productId', isEqualTo: productId)
          .get();
      return ordersSnapshot.docs.length;
    }
  }

  Color _getBorderColor(bool isAccepted, int offerCount) {
    if (isAccepted) {
      return Colors.green;
    } else if (offerCount > 0) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  Widget _buildProductCard(
    BuildContext context,
    Map<String, dynamic> product,
    String productId,
    bool isNegotiable,
    dynamic price,
    String priceLabel,
    String typeLabel,
    int offerCount,
    bool isAccepted, {
    String? buyerName,
  }) {
    final isSold = product['status'] == 'Sold';

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: _getBorderColor(isAccepted, offerCount), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      product['name'] ?? 'Unnamed Product',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[800],
                      ),
                    ),
                    if (isAccepted) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.check_circle, color: Colors.green, size: 20),
                    ]
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isNegotiable ? Colors.orange[100] : Colors.green[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    typeLabel,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isNegotiable ? Colors.orange[800] : Colors.green[800],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text("$priceLabel: ₹${price ?? 'N/A'}"),
            Text("Quantity: ${product['quantity'] ?? 'N/A'}"),
            Text("Category: ${product['category'] ?? 'N/A'}"),

            if (!isNegotiable && isSold && buyerName != null) ...[
              const SizedBox(height: 10),
              Text(
                "Ordered by Dealer: $buyerName",
                style: TextStyle(
                  color: Colors.red[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],

            const SizedBox(height: 10),
            if (offerCount > 0 || isAccepted) ...[
              Text(
                "$offerCount offer(s) received",
                style: TextStyle(
                  color: Colors.orange[800],
                  fontWeight: FontWeight.w600,
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ViewOffersPage(
                          productId: productId,
                          isNegotiable: isNegotiable,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.visibility),
                  label: const Text("View Offers"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[700],
                  ),
                ),
              ),
            ],

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _editProduct(context, product, productId),
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  label: const Text("Edit", style: TextStyle(color: Colors.blue)),
                ),
                TextButton.icon(
                  onPressed: () => _deleteProduct(productId, context),
                  icon: const Icon(Icons.delete, color: Colors.red),
                  label: const Text("Delete", style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("My Products")),
        body: const Center(child: Text("User not logged in")),
      );
    }

    final uid = user.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Products"),
        backgroundColor: Colors.green[700],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('products')
            .where('farmerId', isEqualTo: uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No products uploaded yet."));
          }

          final products = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final productDoc = products[index];
              final product = productDoc.data() as Map<String, dynamic>;
              final productId = productDoc.id;

              final isNegotiable = product.containsKey('startingPrice');
              final price = isNegotiable ? product['startingPrice'] : product['price'];
              final priceLabel = isNegotiable ? "Starting Price" : "Fixed Price";
              final typeLabel = isNegotiable ? "Negotiable" : "Fixed";
              final isSold = product['status'] == 'Sold';

              return FutureBuilder<String?>(
                future: isSold && !isNegotiable ? _getDealerName(productId) : Future.value(null),
                builder: (context, dealerSnapshot) {
                  final buyerName = dealerSnapshot.data;

                  return FutureBuilder<int>(
                    future: _getOfferCount(productId, isNegotiable),
                    builder: (context, offerSnapshot) {
                      final offerCount = offerSnapshot.data ?? 0;

                      return FutureBuilder<bool>(
                        future: _hasAcceptedOffer(productId, isNegotiable),
                        builder: (context, acceptedSnapshot) {
                          final isAccepted = acceptedSnapshot.data ?? false;

                          return _buildProductCard(
                            context,
                            product,
                            productId,
                            isNegotiable,
                            price,
                            priceLabel,
                            typeLabel,
                            offerCount,
                            isAccepted,
                            buyerName: buyerName,
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
