import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'crop_details_page.dart';
import 'dart:convert';

class CropAdvisoryPage extends StatefulWidget {
  @override
  _CropAdvisoryPageState createState() => _CropAdvisoryPageState();
}

class _CropAdvisoryPageState extends State<CropAdvisoryPage> {
  final List<String> crops = [
    "Tomato", "Paddy", "Brinjal", "Chilli", "Onion", "Garlic", "Carrot", "Cabbage", "Cauliflower", "Potato",
    "Sweet Potato", "Groundnut", "Cotton", "Maize", "Wheat", "Barley", "Bajra", "Soybean", "Mustard", "Sunflower",
    "Peas", "Beans", "Lettuce", "Spinach", "Radish", "Beetroot", "Turmeric", "Ginger", "Sugarcane", "Papaya",
    "Banana", "Mango", "Guava", "Pomegranate", "Coconut"
  ];

  final String baseUrl = "http://172.22.69.171:5000"; // Replace with your actual Flask IP

  Future<void> fetchAndNavigate(String cropName) async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/get_advisory?crop=$cropName"));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<String> steps = List<String>.from(data["steps"]);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CropDetailsPage(cropName: cropName, advisorySteps: steps),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to fetch data.")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("🌾 Crop Advisory"),
        backgroundColor: Colors.green[800],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: GridView.count(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          children: crops.map((crop) {
            return GestureDetector(
              onTap: () => fetchAndNavigate(crop),
              child: Card(
                elevation: 4,
                child: Column(
                  children: [
                    Expanded(
                      child: Image.asset(
                        "assets/crops/$crop.png",
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(Icons.image_not_supported),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Text(crop, style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
