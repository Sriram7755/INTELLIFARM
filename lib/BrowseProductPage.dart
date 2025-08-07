import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'DealerOfferPage.dart';

class BrowseProductsPage extends StatefulWidget {
  const BrowseProductsPage({super.key});

  @override
  State<BrowseProductsPage> createState() => _BrowseProductsPageState();
}

class _BrowseProductsPageState extends State<BrowseProductsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch highest offer for a negotiable product
  Future<num?> _fetchHighestOffer(String productId) async {
    try {
      final offerSnapshot = await _firestore
          .collection('products')
          .doc(productId)
          .collection('offers')
          .orderBy('offerPrice', descending: true)
          .limit(1)
          .get();

      if (offerSnapshot.docs.isNotEmpty) {
        return num.tryParse(
            offerSnapshot.docs.first.data()['offerPrice'].toString());
      }
    } catch (e) {
      debugPrint("Error fetching highest offer: $e");
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Browse Products"),
        backgroundColor: Colors.green[700],
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/myOrders');
            },
            icon: const Icon(Icons.shopping_bag, color: Colors.white),
            label: const Text("My Orders",
                style: TextStyle(color: Colors.white)),
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('products')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, productSnapshot) {
          if (productSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!productSnapshot.hasData ||
              productSnapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No products found."));
          }

          final products = productSnapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final doc = products[index];
              final product = doc.data() as Map<String, dynamic>;
              final productId = doc.id;

              // 🔥 Add productId to the product map for navigation
              product['productId'] = productId;

              final isNegotiable = product['negotiable'] == true;

              return FutureBuilder<num?>(
                future:
                    isNegotiable ? _fetchHighestOffer(productId) : Future.value(null),
                builder: (context, offerSnapshot) {
                  final highestOffer = offerSnapshot.data;
                  final startingPrice = product['startingPrice'] ?? 'N/A';
                  final fixedPrice = product['price'] ?? 'N/A';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (product['imageUrl'] != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                product['imageUrl'],
                                height: 180,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                          const SizedBox(height: 8),
                          Text(
                            product['name'] ?? 'Unnamed Product',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[800],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            isNegotiable
                                ? "Starting Price: ₹$startingPrice"
                                : "Price: ₹$fixedPrice",
                            style: const TextStyle(fontSize: 16),
                          ),
                          if (isNegotiable && highestOffer != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                "Highest Offer: ₹$highestOffer",
                                style: TextStyle(
                                  color: Colors.orange[800],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          const SizedBox(height: 6),
                          Text("Quantity: ${product['quantity'] ?? 'N/A'}"),
                          Text("Category: ${product['category'] ?? 'N/A'}"),
                          if ((product['farmerName'] ?? '').toString().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                "Farmer: ${product['farmerName']}",
                                style: TextStyle(color: Colors.grey[700]),
                              ),
                            ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                if (isNegotiable) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => DealerOfferPage(
                                        productData: product,
                                        productId: productId,
                                      ),
                                    ),
                                  );
                                } else {
                                  Navigator.pushNamed(
                                    context,
                                    '/productDetails',
                                    arguments: product, // ✅ Includes productId
                                  );
                                }
                              },
                              icon: Icon(
                                isNegotiable
                                    ? Icons.local_offer
                                    : Icons.shopping_cart,
                              ),
                              label:
                                  Text(isNegotiable ? "Make Offer" : "Buy Now"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isNegotiable
                                    ? Colors.orange[800]
                                    : Colors.green[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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
