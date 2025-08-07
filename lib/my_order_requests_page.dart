import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyOrderRequestsPage extends StatelessWidget {
  const MyOrderRequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text("My Order Requests")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('driver_requests')
            .where('from', isEqualTo: userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No orders placed yet."));
          }

          final orders = snapshot.data!.docs;

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index].data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.all(12),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("📦 Product: ${order['load'] ?? 'N/A'}",
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text("🧮 Quantity: ${order['load'] ?? 'N/A'}"),
                      const SizedBox(height: 8),
                      Text("📍 Pickup: ${order['pickup'] ?? 'N/A'}"),
                      const SizedBox(height: 8),
                      Text("📍 Drop: ${order['drop'] ?? 'N/A'}"),
                      const SizedBox(height: 8),
                      Text("📅 Date: ${order['date'] ?? 'N/A'}"),
                      const SizedBox(height: 8),
                      Text("⏰ Time: ${order['time'] ?? 'N/A'}"),
                      const SizedBox(height: 8),
                      Text("🚚 Status: ${order['status'] ?? 'N/A'}",
                          style: TextStyle(
                            color: order['status'] == 'Accepted' ? Colors.green : Colors.orange,
                            fontWeight: FontWeight.bold,
                          )),
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
}
