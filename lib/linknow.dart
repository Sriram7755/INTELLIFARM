import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LinkSensorPage extends StatefulWidget {
  const LinkSensorPage({super.key});

  @override
  State<LinkSensorPage> createState() => _LinkSensorPageState();
}

class _LinkSensorPageState extends State<LinkSensorPage> {
  final TextEditingController _sensorIdController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  String? _moistureLevel;

  @override
  void initState() {
    super.initState();
    _loadLinkedSensor();
  }

  Future<void> _loadLinkedSensor() async {
    final user = _auth.currentUser;
    if (user != null) {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data()!.containsKey('sensorId')) {
        final sensorId = doc['sensorId'];
        _sensorIdController.text = sensorId;
        _fetchMoistureLevel(sensorId); // fetch moisture data
      }
    }
  }

  Future<void> _fetchMoistureLevel(String sensorId) async {
    try {
      final sensorDoc =
          await _firestore.collection('soilmoisture').doc(sensorId).get();
      if (sensorDoc.exists && sensorDoc.data()!.containsKey('moisture')) {
        setState(() {
          _moistureLevel = sensorDoc['moisture'].toString();
        });
      } else {
        setState(() {
          _moistureLevel = "No moisture data found.";
        });
      }
    } catch (e) {
      setState(() {
        _moistureLevel = "Error fetching moisture data.";
      });
    }
  }

  Future<void> _linkSensor() async {
    final user = _auth.currentUser;
    final sensorId = _sensorIdController.text.trim();

    if (sensorId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a sensor ID')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final sensorDoc =
          await _firestore.collection('soilmoisture').doc(sensorId).get();

      if (!sensorDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid sensor ID')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      await _firestore.collection('users').doc(user!.uid).update({
        'sensorId': sensorId,
        'sensorLinked': true,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sensor linked successfully!')),
      );
      
// ✅ Return to FarmerHome and tell it to refresh
Navigator.pop(context, true);

      _fetchMoistureLevel(sensorId); // Fetch moisture after linking

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to link sensor: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _sensorIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Link Your Sensor'),
        backgroundColor: Colors.green[700],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your soil moisture sensor ID to link it to your account:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _sensorIdController,
              decoration: const InputDecoration(
                labelText: 'Sensor ID',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _linkSensor,
                icon: const Icon(Icons.link),
                label: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Link Now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 30),
            const Divider(),
            const Text(
              'Moisture Level:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              _moistureLevel ?? 'Not available',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
