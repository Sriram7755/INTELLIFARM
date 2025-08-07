import 'package:flutter/material.dart';

class EmployeePage extends StatelessWidget {
  const EmployeePage({super.key});

  final List<Map<String, String>> drivers = const [
    {
      "name": "Ravi Kumar",
      "contact": "+91 98765 43210",
      "image": "https://i.imgur.com/8Km9tLL.jpg",
    },
    {
      "name": "Sathish M",
      "contact": "+91 87654 32109",
      "image": "https://i.imgur.com/uIgDDDd.jpg",
    },
  ];

  final List<Map<String, String>> workers = const [
    {
      "name": "Mani Vel",
      "contact": "+91 91234 56789",
      "image": "https://i.imgur.com/BoN9kdC.png",
    },
    {
      "name": "Anbu Selvan",
      "contact": "+91 99887 77665",
      "image": "https://i.imgur.com/3GvwNBf.jpg",
    },
  ];

  Widget buildProfileCard(Map<String, String> person) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        leading: CircleAvatar(
          radius: 28,
          backgroundImage: NetworkImage(person['image']!),
        ),
        title: Text(person['name']!, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("📞 ${person['contact']}"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Employee Access"),
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              "🚚 Drivers",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
            ),
          ),
          ...drivers.map(buildProfileCard).toList(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              "🧑‍🌾 Workers",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
            ),
          ),
          ...workers.map(buildProfileCard).toList(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
