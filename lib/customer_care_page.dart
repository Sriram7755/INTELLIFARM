import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';


class CustomerCarePage extends StatelessWidget {
  const CustomerCarePage({super.key});

  final List<Map<String, String>> team = const [
    {
      "name": "Agri Tech",
      "phone": "+917806960567",
    },
    {
      "name": "SRM Agri Solutions",
      "phone": "+916383422492",
    },
    {
      "name": "Earth's bounty farm",
      "phone": "+919361314071",
    },
    {
      "name": "Agrigenius growers",
      "phone": "+917654321098",
    },
    {
      "name": "BharatAgri",
      "phone": "+917654321098",
    },
    {
      "name": "SkySquirrel Technologies",
      "phone": "+917654321098",
    },
    {
      "name": "Agrostar",
      "phone": "+917654321098",
    },
  ];

void _launchDialer(BuildContext context, String phoneNumber) async {
  final Uri url = Uri.parse("tel:$phoneNumber");
  print("Trying to launch: $url");

  if (await canLaunchUrl(url)) {
    await launchUrl(url, mode: LaunchMode.externalApplication);
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Could not open dialer")),
    );
  }
}



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Customer Care")),
      body: ListView.builder(
        itemCount: team.length,
        itemBuilder: (context, index) {
          final member = team[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: const Icon(Icons.person, color: Colors.green),
              title: Text(member['name']!, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("📞 ${member['phone']}"),
              trailing: IconButton(
                icon: const Icon(Icons.call, color: Colors.green),
               onPressed: () => _launchDialer(context, member['phone']!),

              ),
            ),
          );
        },
      ),
    );
  }
}
