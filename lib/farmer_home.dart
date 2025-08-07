import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'chatbot.dart';

class FarmerHome extends StatefulWidget {
  const FarmerHome({super.key});
  @override
  State<FarmerHome> createState() => _FarmerHomeState();
}

class _FarmerHomeState extends State<FarmerHome>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  String currentLocation = "Fetching...";
  Position? currentPosition;
  double? temperature;
  int _currentIndex = 0;

  final List<String> routes = [
    '/dashboard',
    '/drivers',
    '/cropAdvisory',
    '/farmer_profile',
  ];

  final List<Map<String, String>> schemes = const [
    {
      "title": "PM-KISAN",
      "image": "assets/images/sc1.jpg",
      "link": "https://pmkisan.gov.in/"
    },
    {
      "title": "Soil Health Card",
      "image": "assets/images/sc2.jpg",
      "link": "https://soilhealth.dac.gov.in/"
    },
    {
      "title": "PMFBY",
      "image": "assets/images/sc3.jpg",
      "link": "https://pmfby.gov.in/"
    },
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..forward();
    _getLocationName();
  }

  Future<void> _getLocationName() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => currentLocation = "Location Services Disabled");
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() => currentLocation = "Permission Denied");
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      currentPosition = position;

      List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        currentLocation =
            "${place.locality ?? 'Unknown'}, ${place.administrativeArea ?? ''}";
      }

      await fetchTemperature(position.latitude, position.longitude);
      setState(() {});
    } catch (e) {
      setState(() => currentLocation = "Error fetching location");
    }
  }

  Future<void> fetchTemperature(double lat, double lon) async {
    const apiKey = "a5a2ef9a34b7c16b0460dc9173e1af32";
    final url = Uri.parse(
        "https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&units=metric&appid=$apiKey");

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          temperature = data['main']['temp'];
        });
      }
    } catch (_) {}
  }

  void _onNavTapped(int index) {
    Navigator.pushNamed(context, routes[index]);
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Could not open link")),
      );
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Farmer Dashboard"),
        backgroundColor: Colors.green,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onNavTapped,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home), label: 'Dashboard'),
          BottomNavigationBarItem(
              icon: Icon(Icons.local_shipping), label: 'Driver'),
          BottomNavigationBarItem(
              icon: Icon(Icons.article), label: 'Crop Advisory'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => ChatbotScreen()));
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.smart_toy),
        tooltip: 'Chatbot',
      ),
      body: dashboardBody(),
    );
  }

  Widget dashboardBody() {
    return FadeTransition(
      opacity: _fadeController,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Welcome to Intellifarm!",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),

            // Location & Temp Card
            InkWell(
              onTap: () async {
                if (currentPosition == null) await _getLocationName();
                if (currentPosition != null) {
                  Navigator.pushNamed(
                    context,
                    '/weather',
                    arguments: {
                      'lat': currentPosition!.latitude,
                      'lon': currentPosition!.longitude,
                      'location': currentLocation,
                    },
                  );
                }
              },
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on,
                          color: Colors.blueGrey, size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Location: $currentLocation",
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis),
                            if (temperature != null)
                              Text(
                                  "🌡 Temperature: ${temperature!.toStringAsFixed(1)}°C",
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
            const Text("Government Schemes",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),

            SizedBox(
              height: 150,
              child: PageView.builder(
                controller: PageController(viewportFraction: 0.9),
                itemCount: schemes.length,
                itemBuilder: (context, index) {
                  final scheme = schemes[index];
                  return GestureDetector(
                    onTap: () => _launchURL(scheme['link']!),
                    child: schemeCard(
                        scheme['title']!, scheme['image']!),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),
            soilMoistureCard(),

            const SizedBox(height: 24),
            const Text("Quick Access",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 12),

            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 3,
              mainAxisSpacing: 15,
              crossAxisSpacing: 15,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                ActionIcon(
                    title: "Upload\nProducts",
                    icon: Icons.upload_file,
                    onTap: () => Navigator.pushNamed(context, '/upload')),
                ActionIcon(
                    title: "Marketplace",
                    icon: Icons.shopping_cart,
                    onTap: () => Navigator.pushNamed(context, '/marketplace')),
                ActionIcon(
                    title: "My Orders",
                    icon: Icons.list_alt,
                    onTap: () => Navigator.pushNamed(context, '/myProducts')),
                ActionIcon(
                    title: "Rain Prediction",
                    icon: Icons.thunderstorm,
                    onTap: () =>
                        Navigator.pushNamed(context, '/rainPrediction')),
                ActionIcon(
                    title: "Customer\nSupport",
                    icon: Icons.support_agent,
                    onTap: () =>
                        Navigator.pushNamed(context, '/nearbyShops')),
                ActionIcon(
                    title: "Chat With \n dealer",
                    icon: Icons.chat_bubble_outline,
                    onTap: () =>
                        Navigator.pushNamed(context, '/farmerchatlist')),
              ],
            ),
          ],
        ),
      ),
    );
  }




  Widget schemeCard(String title, String imagePath) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image:
            DecorationImage(image: AssetImage(imagePath), fit: BoxFit.cover),
      ),
      child: Container(
        alignment: Alignment.bottomLeft,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withOpacity(0.6),
              Colors.transparent
            ],
          ),
        ),
        child: Text(title,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget soilMoistureCard() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox();

    return FutureBuilder<DocumentSnapshot>(
      future:
          FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
          return const Text("Loading user data...");
        }

        final userData =
            userSnapshot.data!.data() as Map<String, dynamic>;
        final sensorId = userData['sensorId'];

        if (sensorId == null || sensorId.toString().isEmpty) {
          return Card(
            color: Colors.red[50],
            elevation: 3,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.sensors_off,
                      size: 40, color: Colors.red),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text("No Sensor Linked",
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text(
                            "Link a soil moisture sensor to view live data."),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final result = await Navigator.pushNamed(
                          context, '/linkSensor');
                      if (result == true) {
                        setState(() {});
                      }
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red),
                    child: const Text("Link Now"),
                  ),
                ],
              ),
            ),
          );
        }

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('soilmoisture')
              .doc(sensorId)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Text('⚠ No soil moisture data found.');
            }

            final data = snapshot.data!.data() as Map<String, dynamic>?;
            final int? moistureValue = data?['moisture'];

            if (moistureValue == null) {
              return const Text('⚠ Moisture field missing.');
            }

            const int minValue = 2700;
            const int maxValue = 3100;
            double percent = ((maxValue - moistureValue) /
                    (maxValue - minValue))
                .clamp(0.0, 1.0);
            int displayPercent = (percent * 100).round();

            String status;
            if (displayPercent >= 70) {
              status = "Wet";
            } else if (displayPercent >= 40) {
              status = "Moderate";
            } else {
              status = "Dry";
            }

            FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .update({'status': status});

            Color statusColor;
            if (status == "Wet") {
              statusColor = Colors.green;
            } else if (status == "Moderate") {
              statusColor = Colors.orange;
            } else {
              statusColor = Colors.red;
            }

            return Card(
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  ),
  elevation: 4,
  color: Colors.lightBlue[50],
  child: Padding(
    padding: const EdgeInsets.all(16.0),
    child: Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircularPercentIndicator(
              radius: 60.0,
              lineWidth: 12.0,
              percent: percent,
              center: Text(
                '$displayPercent%',
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold),
              ),
              progressColor: statusColor,
              backgroundColor: Colors.grey.shade300,
              animation: true,
              animationDuration: 1200,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Soil Moisture Level',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Status: $status',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: statusColor),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 🔴 Disconnect Button
        ElevatedButton.icon(
          onPressed: () async {
            final user = FirebaseAuth.instance.currentUser;
            if (user != null) {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .update({
                'sensorId': null,
              });
              setState(() {}); // refresh UI
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
          ),
          icon: const Icon(Icons.link_off),
          label: const Text("Disconnect Sensor"),
        ),
      ],
    ),
  ),
);

          },
        );
      },
    );
  }
}

class ActionIcon extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const ActionIcon({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.green.shade100,
            child: Icon(icon, size: 30, color: Colors.green.shade800),
          ),
          const SizedBox(height: 6),
          Text(title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
