import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class ViewOffersPage extends StatefulWidget {
  final String productId;
  final bool isNegotiable;

  const ViewOffersPage({
    super.key,
    required this.productId,
    required this.isNegotiable,
  });

  @override
  State<ViewOffersPage> createState() => _ViewOffersPageState();
}

class _ViewOffersPageState extends State<ViewOffersPage> {
  Map<String, dynamic>? productData;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _fetchProduct();
  }

  Future<void> _fetchProduct() async {
    try {
      final doc = await _firestore.collection('products').doc(widget.productId).get();
      if (doc.exists) {
        setState(() {
          productData = doc.data();
        });
      }
    } catch (e) {
      print("Error fetching product: $e");
    }
  }

  Future<void> _acceptOffer(String offerId, Map<String, dynamic> offerData) async {
    try {
      final updatedOffer = {...offerData, 'acceptedOfferId': offerId};
      await _firestore.collection('products').doc(widget.productId).update({
        'acceptedOffer': updatedOffer,
        'status': 'Accepted',
        'acceptedOfferId': offerId,
      });
      await _fetchProduct();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Offer accepted.")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> _cancelAcceptedOffer() async {
    try {
      await _firestore.collection('products').doc(widget.productId).update({
        'acceptedOffer': FieldValue.delete(),
        'status': 'Pending',
        'acceptedOfferId': FieldValue.delete(),
      });
      await _fetchProduct();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Acceptance cancelled.")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<Map<String, String?>> _getDealerDetails(String dealerId) async {
    try {
      final doc = await _firestore.collection('users').doc(dealerId).get();
      final data = doc.data();
      return {
        'name': data?['name'] ?? 'Unknown',
        'contact': data?['contact']?.toString() ?? '',
      };
    } catch (e) {
      return {'name': 'Unknown', 'contact': ''};
    }
  }

  void _callDealer(String phone) async {
    final uri = Uri.parse("tel:$phone");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cannot launch dialer.")));
    }
  }

  void _startChat(String dealerId, String dealerName) {
    Navigator.pushNamed(
      context,
      '/chatPage',
      arguments: {
        'otherUserId': dealerId,
        'otherUserName': dealerName,
        'isFarmer': true,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final offerStream = widget.isNegotiable
        ? _firestore.collection('products').doc(widget.productId).collection('offers').orderBy('timestamp', descending: true).snapshots()
        : _firestore.collection('dealer_orders').where('productId', isEqualTo: widget.productId).snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Offers for Product"),
        backgroundColor: Colors.green[700],
      ),
      body: productData == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
              stream: offerStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("No offers placed yet."));

                final offers = snapshot.data!.docs;
                final acceptedOffer = productData?['acceptedOffer'];

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: offers.length,
                  itemBuilder: (context, index) {
                    final doc = offers[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final offerId = doc.id;
                    final dealerId = data['dealerId'] ?? '';
                    final offerPrice = widget.isNegotiable ? data['offerPrice'] : data['price'];
                    final isAccepted = acceptedOffer != null && acceptedOffer['acceptedOfferId'] == offerId;

                    return FutureBuilder<Map<String, String?>>(
                      future: _getDealerDetails(dealerId),
                      builder: (context, snapshot) {
                        final dealerName = snapshot.data?['name'] ?? 'Unknown';
                        final phone = snapshot.data?['contact'] ?? '';

                        return Card(
                          color: isAccepted ? Colors.green[50] : null,
                          elevation: 4,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: isAccepted ? BorderSide(color: Colors.green, width: 2) : BorderSide.none,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text("Dealer: $dealerName", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    if (isAccepted)
                                      Padding(
                                        padding: const EdgeInsets.only(left: 8),
                                        child: Chip(
                                          label: const Text("ACCEPTED", style: TextStyle(color: Colors.white)),
                                          backgroundColor: Colors.green,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text("Price: ₹$offerPrice"),
                                if (data['message'] != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text("Message: ${data['message']}", style: TextStyle(color: Colors.grey[700])),
                                  ),
                                const SizedBox(height: 10),
                                if (!isAccepted)
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: ElevatedButton.icon(
                                      onPressed: () => _acceptOffer(offerId, data),
                                      icon: const Icon(Icons.check_circle_outline),
                                      label: Text(acceptedOffer == null ? "Accept Offer" : "Change Acceptance"),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: acceptedOffer == null ? Colors.green[700] : Colors.orange[700],
                                      ),
                                    ),
                                  ),
                                if (isAccepted) ...[
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      ElevatedButton.icon(
                                        onPressed: phone.isNotEmpty ? () => _callDealer(phone) : null,
                                        icon: const Icon(Icons.call),
                                        label: const Text("Call Dealer"),
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green[800]),
                                      ),
                                      ElevatedButton.icon(
                                        onPressed: () => _startChat(dealerId, dealerName),
                                        icon: const Icon(Icons.chat),
                                        label: const Text("Chat"),
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[700]),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  ElevatedButton.icon(
                                    onPressed: _cancelAcceptedOffer,
                                    icon: const Icon(Icons.cancel),
                                    label: const Text("Cancel Acceptance"),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700]),
                                  ),
                                ]
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
