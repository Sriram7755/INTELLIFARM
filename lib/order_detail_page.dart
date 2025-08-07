import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderDetailPage extends StatefulWidget {
  final Map<String, dynamic> orderData;

  const OrderDetailPage({super.key, required this.orderData});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  Map<String, dynamic>? farmerData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchFarmerDetails();
  }

  Future<void> fetchFarmerDetails() async {
    try {
      final farmerId = widget.orderData['from'];
      final doc = await FirebaseFirestore.instance.collection('users').doc(farmerId).get();
      setState(() {
        farmerData = doc.data();
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching farmer details: $e");
      setState(() => isLoading = false);
    }
  }

  Widget buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green[800]),
      ),
    );
  }

  Widget buildInfoRow({required IconData icon, required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[700], size: 24),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              "$label: $value",
              style: TextStyle(fontSize: 18),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.orderData;

    return Scaffold(
      appBar: AppBar(title: const Text("Order & Farmer Details")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : farmerData == null
              ? Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.warning_amber_rounded, size: 60, color: Colors.orange),
                      SizedBox(height: 16),
                      Text("Oops! We couldn't fetch the farmer's details.",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center),
                      SizedBox(height: 8),
                      Text("This could be due to missing or invalid farmer ID in the order.",
                          textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Farmer Info - FIRST
                      Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 6,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              buildSectionTitle("👨‍🌾 Farmer Information"),
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 45,
                                    backgroundColor: Colors.grey[300],
                                    backgroundImage:
                                        farmerData!['profileImageUrl'] != null
                                            ? NetworkImage(farmerData!['profileImageUrl'])
                                                as ImageProvider
                                            : null,
                                    child: farmerData!['profileImageUrl'] == null
                                        ? Icon(Icons.person, size: 40, color: Colors.grey[700])
                                        : null,
                                  ),
                                  SizedBox(width: 20),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text("Name: ${farmerData!['name'] ?? 'N/A'}",
                                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                                        SizedBox(height: 6),
                                        Text("Email: ${farmerData!['email'] ?? 'N/A'}",
                                            style: TextStyle(fontSize: 18, color: Colors.grey[700])),
                                        SizedBox(height: 4),
                                        Text("Contact: ${farmerData!['contact'] ?? 'N/A'}",
                                            style: TextStyle(fontSize: 18, color: Colors.grey[700])),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 16),
                              Divider(),
                              if (farmerData!['address'] != null)
                                buildInfoRow(
                                    icon: Icons.home,
                                    label: "Address",
                                    value: farmerData!['address']),
                              if (farmerData!['city'] != null)
                                buildInfoRow(
                                    icon: Icons.location_city,
                                    label: "City",
                                    value: farmerData!['city']),
                              if (farmerData!['state'] != null)
                                buildInfoRow(
                                    icon: Icons.map,
                                    label: "State",
                                    value: farmerData!['state']),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 30),

                      // Order Info
                      Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 6,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              buildSectionTitle("📦 Order Details"),
                              buildInfoRow(
                                  icon: Icons.shopping_bag,
                                  label: "Product",
                                  value: order['load'] ?? 'N/A'),
                              buildInfoRow(
                                  icon: Icons.numbers,
                                  label: "Quantity",
                                  value: order['load'] ?? 'N/A'),
                              buildInfoRow(
                                  icon: Icons.place,
                                  label: "Pickup Location",
                                  value: order['pickup'] ?? 'N/A'),
                              buildInfoRow(
                                  icon: Icons.location_on,
                                  label: "Drop Location",
                                  value: order['drop'] ?? 'N/A'),
                              buildInfoRow(
                                  icon: Icons.date_range,
                                  label: "Date",
                                  value: order['date'] ?? 'N/A'),
                              buildInfoRow(
                                  icon: Icons.access_time,
                                  label: "Time",
                                  value: order['time'] ?? 'N/A'),
                              buildInfoRow(
                                  icon: Icons.local_shipping,
                                  label: "Status",
                                  value: order['status'] ?? 'N/A'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
