import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DealerHome extends StatefulWidget {
  const DealerHome({super.key});

  @override
  State<DealerHome> createState() => _DealerHomeState();
}

class _DealerHomeState extends State<DealerHome> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  String currentLocation = "Fetching...";
  Position? currentPosition;

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

      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        setState(() => currentLocation = "Permission Denied");
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      currentPosition = position;

      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        setState(() {
          currentLocation = "${place.locality ?? 'Unknown'}, ${place.administrativeArea ?? ''}";
        });
      }
    } catch (e) {
      setState(() => currentLocation = "Error fetching location");
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
        title: const Text("Dealer Dashboard"),
        backgroundColor: Colors.blue[800],
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
  await FirebaseAuth.instance.signOut();
  Navigator.pushReplacementNamed(context, '/login');
},

          ),
        ],
      ),

      // ✅ FAB for ChatBot
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.blue[800],
        onPressed: () => Navigator.pushNamed(context, '/chatbot'),
        label: const Text("ChatBot"),
        icon: const Icon(Icons.support_agent),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,

      body: FadeTransition(
        opacity: _fadeController,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ Location Card like Farmer Home
              InkWell(
                onTap: () {
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
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Unable to fetch location")),
                    );
                  }
                },
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.blueGrey, size: 32),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "Location: $currentLocation",
                            style: const TextStyle(fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
              const Text("Quick Access", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              const SizedBox(height: 12),

              // ✅ Row Buttons like Farmer Home
              GridView.count(
  shrinkWrap: true,
  crossAxisCount: 3,
  crossAxisSpacing: 16,
  mainAxisSpacing: 20,
  physics: const NeverScrollableScrollPhysics(),
                children: [
                  ActionIcon(title: "Browse\nProducts", icon: Icons.shopping_cart, onTap: () => Navigator.pushNamed(context, '/browseProducts')),
                  ActionIcon(title: "Chat with\nFarmers", icon: Icons.chat, onTap: () => Navigator.pushNamed(context, '/dealerChat')),
                  ActionIcon(title: "My Orders", icon: Icons.receipt_long, onTap: () => Navigator.pushNamed(context, '/myOrders')),
                  ActionIcon(title: "My\nProfile", icon: Icons.person, onTap: () => Navigator.pushNamed(context, '/dealerProfile')),
                  ActionIcon(title: "Request\nTransport", icon: Icons.local_shipping, onTap: () => Navigator.pushNamed(context, '/drivers')),
                ],
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
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
      child: SizedBox(
        width: 90,
        child: Column(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.blue.shade100,
              child: Icon(icon, size: 30, color: Colors.blue.shade800),
            ),
            const SizedBox(height: 6),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}