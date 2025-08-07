import 'package:flutter/material.dart';

class CropDetailsPage extends StatelessWidget {
  final String cropName;
  final List<String> advisorySteps;

  const CropDetailsPage({super.key, required this.cropName, required this.advisorySteps});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("📋 Advisory - $cropName"),
        backgroundColor: Colors.green[700],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                "assets/crops/$cropName.png",
                height: 180,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Icon(Icons.image_not_supported, size: 100),
              ),
            ),
            SizedBox(height: 16),
            Text(
              "🌱 Crop Advisory for $cropName",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: advisorySteps.length,
                itemBuilder: (context, index) {
                  return Card(
                    elevation: 4,
                    margin: EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text("${index + 1}"),
                        backgroundColor: Colors.green[400],
                      ),
                      title: Text("Step ${index + 1}"),
                      subtitle: Text(advisorySteps[index]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
