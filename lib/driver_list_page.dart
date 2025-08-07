import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class DriverListPage extends StatelessWidget {
  const DriverListPage({super.key});

  // Function to launch phone dialer
  void _launchDialer(String phoneNumber) async {
    final Uri url = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    final driversRef = FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'Driver')
        .where('driverStatus', isEqualTo: 'approved');

    return Scaffold(
      appBar: AppBar(
        title: const Text("Available Drivers"),
        backgroundColor: Colors.green,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: driversRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading drivers'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final drivers = snapshot.data!.docs;

          if (drivers.isEmpty) {
            return const Center(child: Text("No drivers available."));
          }

          return ListView.builder(
            itemCount: drivers.length,
            itemBuilder: (context, index) {
              final driver = drivers[index];
              final name = driver['name'] ?? '';
              final email = driver['email'] ?? '';
              final profileImage = driver['profileImageUrl'] ?? '';
              final contact = driver['contact'] ?? '';

              final ratePerKm = driver.data().toString().contains('ratePerKm') && driver['ratePerKm'] != null
                  ? driver['ratePerKm'].toString()
                  : 'Not Set';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundImage: profileImage.isNotEmpty
                            ? NetworkImage(profileImage)
                            : null,
                        backgroundColor: Colors.green[100],
                        child: profileImage.isEmpty ? const Icon(Icons.person) : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(email),
                            const SizedBox(height: 4),
                            Text("Rate: ₹$ratePerKm per km", style: const TextStyle(fontWeight: FontWeight.bold)),
                            if (contact.isNotEmpty)
                              Text("Contact: $contact"),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/requestOrder',
                                      arguments: driver,
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                  ),
                                  child: const Text("Request", style: TextStyle(color: Colors.white)),
                                ),
                                const SizedBox(width: 10),
                                IconButton(
                                  icon: const Icon(Icons.phone),
                                  color: Colors.green,
                                  tooltip: 'Call Driver',
                                  onPressed: contact.isNotEmpty
                                      ? () => _launchDialer(contact)
                                      : null,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
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
