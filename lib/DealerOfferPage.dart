import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DealerOfferPage extends StatefulWidget {
  final Map<String, dynamic> productData;
  final String productId;

  const DealerOfferPage({
    super.key,
    required this.productData,
    required this.productId,
  });

  @override
  State<DealerOfferPage> createState() => _DealerOfferPageState();
}

class _DealerOfferPageState extends State<DealerOfferPage> {
  final TextEditingController _offerController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submitOffer() async {
    final user = FirebaseAuth.instance.currentUser;
    final offerText = _offerController.text.trim();

    if (user == null || offerText.isEmpty || num.tryParse(offerText) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Please login and enter a valid numeric offer.")),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final dealerId = user.uid;

      // Get dealer name from Firestore users collection
      final dealerDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(dealerId)
          .get();

      final dealerName = dealerDoc.data()?['name'] ?? 'Anonymous Dealer';
      final numericOffer = num.tryParse(offerText) ?? 0;

      // Submit the offer to product's 'offers' subcollection
      await FirebaseFirestore.instance
          .collection('products')
          .doc(widget.productId)
          .collection('offers')
          .add({
        'dealerId': dealerId,
        'dealerName': dealerName,
        'offerPrice': numericOffer,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Offer submitted successfully!")),
      );

      Navigator.pop(context); // Go back to previous screen
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error: $e")),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _offerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.productData;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Make an Offer"),
        backgroundColor: Colors.green.shade700,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product['name'] ?? 'Product',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text("💰 Starting Price: ₹${product['startingPrice'] ?? 'N/A'}"),
                      Text("📦 Quantity: ${product['quantity'] ?? 'N/A'}"),
                      Text("🗂️ Category: ${product['category'] ?? 'N/A'}"),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _offerController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Your Offer Price (₹)",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.price_check),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitOffer,
                  icon: const Icon(Icons.local_offer),
                  label: Text(_isSubmitting ? "Submitting..." : "Submit Offer"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(fontSize: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
