import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MyOrdersPage extends StatefulWidget {
  const MyOrdersPage({super.key});

  @override
  State<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  Future<List<Map<String, dynamic>>> _fetchDealerOrders() async {
    final List<Map<String, dynamic>> myOrders = [];

    // Fixed price orders from dealer_orders
    final fixedSnapshot = await _firestore
        .collection('dealer_orders')
        .where('dealerId', isEqualTo: currentUserId)
        .get();

    for (var doc in fixedSnapshot.docs) {
      final data = doc.data();
      myOrders.add({
        'productName': data['productName'] ?? 'Unknown',
        'offerPrice': data['price'] ?? 'N/A',
        'quantity': data['quantity'] ?? 'N/A',
        'status': data['acceptStatus'] ?? 'Pending',
        'farmerId': data['farmerId'],
        'farmerName': data['farmerName'] ?? 'Farmer',
      });
    }

    // Negotiable offers from products → offers
    final productSnapshot = await _firestore.collection('products').get();

    for (var productDoc in productSnapshot.docs) {
      final productData = productDoc.data();
      final productId = productDoc.id;
      final isNegotiable = productData['negotiable'] ?? false;

      if (!isNegotiable) continue;

      final acceptedOffer = productData['acceptedOffer'];
      final farmerId = productData['farmerId'];
      final productName = productData['name'] ?? 'Negotiable Product';

      final offerSnapshot = await _firestore
          .collection('products')
          .doc(productId)
          .collection('offers')
          .where('dealerId', isEqualTo: currentUserId)
          .get();

      if (offerSnapshot.docs.isNotEmpty) {
        final offerData = offerSnapshot.docs.first.data();
        final bool isAccepted = acceptedOffer != null &&
            acceptedOffer['dealerId'] == currentUserId;

        myOrders.add({
          'productName': productName,
          'offerPrice': offerData['offerPrice'] ?? 'N/A',
          'quantity': offerData['quantity'] ?? productData['quantity'] ?? 'N/A',
          'status': isAccepted ? 'Accepted' : 'Pending',
          'farmerId': farmerId,
          'farmerName': productData['farmerName'] ?? 'Farmer',
        });
      }
    }

    return myOrders;
  }

  Future<Map<String, dynamic>?> _getFarmerDetails(String farmerId) async {
    try {
      final doc = await _firestore.collection('users').doc(farmerId).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      print("Error fetching farmer details: $e");
      return null;
    }
  }

  void _showFarmerDetails(
      BuildContext context, String farmerId, String fallbackName) async {
    final farmer = await _getFarmerDetails(farmerId);

    final name = farmer?['name'] ?? fallbackName;
    final phone = farmer?['mobile']?.toString() ??
        farmer?['contact']?.toString() ??
        farmer?['phone']?.toString() ??
        'Not Available';
    final email = farmer?['email'] ?? 'Not Available';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Farmer Details"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Name: $name"),
            Text("Phone: $phone"),
            Text("Email: $email"),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: phone != 'Not Available'
                      ? () => _callFarmer(phone)
                      : null,
                  icon: const Icon(Icons.call),
                  label: const Text("Call"),
                ),
                ElevatedButton.icon(
                  onPressed: () => _startChat(context, farmerId, name),
                  icon: const Icon(Icons.chat),
                  label: const Text("Chat"),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  void _callFarmer(String phoneNumber) async {
    final uri = Uri.parse("tel:$phoneNumber");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not launch dialer.")),
      );
    }
  }

  void _startChat(BuildContext context, String farmerId, String farmerName) {
Navigator.pushNamed(
  context,
  '/chatPage',
  arguments: {
    'otherUserId': farmerId,
    'otherUserName': farmerName,
    'isFarmer': false,
  },
);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        backgroundColor: Colors.blue[800],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchDealerOrders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No orders found.'));
          }

          final orders = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              final isAccepted =
                  order['status'].toString().toLowerCase() == 'accepted';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isAccepted ? Colors.green : Colors.grey.shade400,
                    width: 2,
                  ),
                ),
                child: ListTile(
                  title: Text(order['productName']),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Your Offer: ₹${order['offerPrice']}"),
                      Text("Quantity: ${order['quantity'] ?? 'N/A'}"),
                    ],
                  ),
                  trailing: Chip(
                    label: Text(
                      order['status'].toString().toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor:
                        isAccepted ? Colors.green[700] : Colors.orange[700],
                  ),
                  onTap: () {
                    _showFarmerDetails(
                        context, order['farmerId'], order['farmerName']);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
