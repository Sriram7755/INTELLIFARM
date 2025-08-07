import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// Move the manual shop list outside the class
const List<Map<String, String>> manualShops = [
  {
    'name': 'GreenGrow Agro Centre',
    'phone': '+919876543210',
    'place': 'Hosur',
  },
  {
    'name': 'Kisan Agriculture Mart',
    'phone': '+918765432109',
    'place': 'Krishnagiri',
  },
  {
    'name': 'Agro World Supplies',
    'phone': '+917654321098',
    'place': 'Salem',
  },
  {
    'name': 'Farm Fresh Seeds & Tools',
    'phone': '+916543210987',
    'place': 'Dharmapuri',
  },
  {
    'name': 'Rural Roots Agri Store',
    'phone': '+915432109876',
    'place': 'Erode',
  },
];

class NearbyShopsPage extends StatelessWidget {
  const NearbyShopsPage({super.key});

  void _launchCaller(BuildContext context, String phoneNumber) async {
    final Uri phoneUri = Uri.parse("tel:$phoneNumber");
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cannot launch phone dialer")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Agriculture Shops'),
        backgroundColor: Colors.green,
      ),
      body: ListView.builder(
        itemCount: manualShops.length,
        itemBuilder: (context, index) {
          final shop = manualShops[index];
          return Card(
            elevation: 4,
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              leading: const Icon(Icons.store, color: Colors.green, size: 32),
              title: Text(
                shop['name']!,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text('📍 ${shop['place']}'),
                  Text('📞 ${shop['phone']}'),
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Icons.call, color: Colors.green),
                onPressed: () => _launchCaller(context, shop['phone']!),
              ),
            ),
          );
        },
      ),
    );
  }
}
