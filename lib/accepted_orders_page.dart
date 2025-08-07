import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AcceptedOrdersPage extends StatelessWidget {
  const AcceptedOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Accepted Orders"),
        centerTitle: true,
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('driver_requests')
            .where('from', isEqualTo: userId)
            .where('status', isEqualTo: 'accepted')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("No accepted orders found.",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
            );
          }

          final orders = snapshot.data!.docs;

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index].data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("📦 ${order['load'] ?? 'Product'}",
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),

                      const SizedBox(height: 12),
                      _buildDetailRow("🧮 Quantity", order['load']),
                      _buildDetailRow("📍 Pickup", order['pickup']),
                      _buildDetailRow("📍 Drop", order['drop']),
                      _buildDetailRow("📅 Date", order['date']),
                      _buildDetailRow("⏰ Time", order['time']),
                      _buildDetailRow("🚚 Status", "Accepted", statusColor: Colors.green),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value, {Color? statusColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Text(
            "$label: ",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: statusColor ?? Colors.black87,
            ),
          ),
          Flexible(
            child: Text(
              value ?? 'N/A',
              style: TextStyle(
                fontSize: 16,
                color: statusColor ?? Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
