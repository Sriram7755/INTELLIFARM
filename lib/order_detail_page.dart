import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geocoding/geocoding.dart';

class OrderDetailPage extends StatefulWidget {
  final Map<String, dynamic> orderData;

  const OrderDetailPage({super.key, required this.orderData});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  Map<String, dynamic>? farmerData;
  bool isLoading = true;

  String? pickupAddress;
  String? dropAddress;

  @override
  void initState() {
    super.initState();
    fetchFarmerDetails();
    fetchAddresses();
  }

  Future<void> fetchFarmerDetails() async {
    try {
      final farmerId = widget.orderData['from'];
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(farmerId).get();
      setState(() {
        farmerData = doc.data();
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching farmer details: $e");
      setState(() => isLoading = false);
    }
  }

/*   Future<void> fetchAddresses() async {
    try {
      final pickupLat = widget.orderData['pickup_lat'];
      final pickupLng = widget.orderData['pickup_lng'];
      final dropLat = widget.orderData['drop_lat'];
      final dropLng = widget.orderData['drop_lng'];

      if (pickupLat != null && pickupLng != null) {
        List<Placemark> placemarks = await placemarkFromCoordinates(pickupLat, pickupLng);
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          setState(() {
            pickupAddress =
                "${p.name ?? ''}, ${p.locality ?? ''}, ${p.administrativeArea ?? ''}, ${p.country ?? ''}".replaceAll(RegExp(r'(, )+'), ', ').trim().replaceAll(RegExp(r'^, |, $'), '');
          });
        }
      }

      if (dropLat != null && dropLng != null) {
        List<Placemark> placemarks = await placemarkFromCoordinates(dropLat, dropLng);
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          setState(() {
            dropAddress =
                "${p.name ?? ''}, ${p.locality ?? ''}, ${p.administrativeArea ?? ''}, ${p.country ?? ''}".replaceAll(RegExp(r'(, )+'), ', ').trim().replaceAll(RegExp(r'^, |, $'), '');
          });
        }
      }
    } catch (e) {
      print("Error in reverse geocoding: $e");
    }
  } */

  Future<void> fetchAddresses() async {
  try {
    final pickupLat = widget.orderData['pickup_lat'];
    final pickupLng = widget.orderData['pickup_lng'];
    final dropLat = widget.orderData['drop_lat'];
    final dropLng = widget.orderData['drop_lng'];

    if (pickupLat != null && pickupLng != null) {
      print("Fetching pickup address for: $pickupLat, $pickupLng");
      List<Placemark> placemarks = await placemarkFromCoordinates(pickupLat, pickupLng);
      print("Pickup placemarks: $placemarks");
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        setState(() {
          pickupAddress =
              "${p.name ?? ''}, ${p.locality ?? ''}, ${p.administrativeArea ?? ''}, ${p.country ?? ''}"
                  .replaceAll(RegExp(r'(, )+'), ', ')
                  .trim()
                  .replaceAll(RegExp(r'^, |, $'), '');
        });
      } else {
        // No placemarks found, fallback to coordinates string
        setState(() {
          pickupAddress = "${pickupLat.toStringAsFixed(5)}, ${pickupLng.toStringAsFixed(5)}";
        });
      }
    }

    if (dropLat != null && dropLng != null) {
      print("Fetching drop address for: $dropLat, $dropLng");
      List<Placemark> placemarks = await placemarkFromCoordinates(dropLat, dropLng);
      print("Drop placemarks: $placemarks");
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        setState(() {
          dropAddress =
              "${p.name ?? ''}, ${p.locality ?? ''}, ${p.administrativeArea ?? ''}, ${p.country ?? ''}"
                  .replaceAll(RegExp(r'(, )+'), ', ')
                  .trim()
                  .replaceAll(RegExp(r'^, |, $'), '');
        });
      } else {
        setState(() {
          dropAddress = "${dropLat.toStringAsFixed(5)}, ${dropLng.toStringAsFixed(5)}";
        });
      }
    }
  } catch (e) {
    print("Error in reverse geocoding: $e");
    // On error, fallback to lat/lng display
    final pickupLat = widget.orderData['pickup_lat'];
    final pickupLng = widget.orderData['pickup_lng'];
    final dropLat = widget.orderData['drop_lat'];
    final dropLng = widget.orderData['drop_lng'];
    setState(() {
      pickupAddress = pickupLat != null && pickupLng != null
          ? "${pickupLat.toStringAsFixed(5)}, ${pickupLng.toStringAsFixed(5)}"
          : "Unknown location";
      dropAddress = dropLat != null && dropLng != null
          ? "${dropLat.toStringAsFixed(5)}, ${dropLng.toStringAsFixed(5)}"
          : "Unknown location";
    });
  }
}

  
  Widget buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
            fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green[800]),
      ),
    );
  }

  Widget buildInfoRow(
      {required IconData icon, required String label, required String value}) {
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
              overflow: TextOverflow.visible,
              maxLines: null,
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
                      Icon(Icons.warning_amber_rounded,
                          size: 60, color: Colors.orange),
                      SizedBox(height: 16),
                      Text("Oops! We couldn't fetch the farmer's details.",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center),
                      SizedBox(height: 8),
                      Text(
                          "This could be due to missing or invalid farmer ID in the order.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600])),
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
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
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
                                            ? NetworkImage(
                                                farmerData!['profileImageUrl'])
                                            : null,
                                    child: farmerData!['profileImageUrl'] == null
                                        ? Icon(Icons.person,
                                            size: 40, color: Colors.grey[700])
                                        : null,
                                  ),
                                  SizedBox(width: 20),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text("Name: ${farmerData!['name'] ?? 'N/A'}",
                                            style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.w600)),
                                        SizedBox(height: 6),
                                        Text("Email: ${farmerData!['email'] ?? 'N/A'}",
                                            style: TextStyle(
                                                fontSize: 18,
                                                color: Colors.grey[700])),
                                        SizedBox(height: 4),
                                        Text(
                                            "Contact: ${farmerData!['contact'] ?? 'N/A'}",
                                            style: TextStyle(
                                                fontSize: 18,
                                                color: Colors.grey[700])),
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
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
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
                                  value: order['quantity']?.toString() ?? 'N/A'),
                              buildInfoRow(
                                icon: Icons.place,
                                label: "Pickup Location",
                                value: pickupAddress ??
                                    "${order['pickup'] ?? 'Unknown location'}",
                              ),
                              buildInfoRow(
                                icon: Icons.location_on,
                                label: "Drop Location",
                                value: dropAddress ??
                                    "${order['drop'] ?? 'Unknown location'}",
                              ),
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
                              SizedBox(height: 20),
                              ElevatedButton.icon(
                                icon: Icon(Icons.map),
                                label: Text("View Map"),
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(
                                      vertical: 12, horizontal: 24),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () {
                                  final pickupLat = order['pickup_lat'];
                                  final pickupLng = order['pickup_lng'];
                                  final dropLat = order['drop_lat'];
                                  final dropLng = order['drop_lng'];

                                  if (pickupLat != null &&
                                      pickupLng != null &&
                                      dropLat != null &&
                                      dropLng != null) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => MapPage(
                                          pickupLat: pickupLat,
                                          pickupLng: pickupLng,
                                          dropLat: dropLat,
                                          dropLng: dropLng,
                                        ),
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              "Location coordinates not available.")),
                                    );
                                  }
                                },
                              ),
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

class MapPage extends StatefulWidget {
  final double pickupLat;
  final double pickupLng;
  final double dropLat;
  final double dropLng;

  const MapPage({
    super.key,
    required this.pickupLat,
    required this.pickupLng,
    required this.dropLat,
    required this.dropLng,
  });

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late GoogleMapController _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  List<LatLng> polylineCoordinates = [];

  double? _distanceKm;

  // Replace this with your actual Google Maps API Key
  static const String googleAPIKey = 'AIzaSyANdxakvvAt99jaHzqJZZaZheUzRw_ZOvU';

  @override
  void initState() {
    super.initState();
    _setMarkers();
    _getPolyline();
  }

  void _setMarkers() {
    _markers.add(Marker(
      markerId: MarkerId('pickup'),
      position: LatLng(widget.pickupLat, widget.pickupLng),
      infoWindow: InfoWindow(title: 'Pickup Location'),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
    ));

    _markers.add(Marker(
      markerId: MarkerId('drop'),
      position: LatLng(widget.dropLat, widget.dropLng),
      infoWindow: InfoWindow(title: 'Drop Location'),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
    ));
  }

  Future<void> _getPolyline() async {
    PolylinePoints polylinePoints = PolylinePoints();

    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      googleAPIKey,
      PointLatLng(widget.pickupLat, widget.pickupLng),
      PointLatLng(widget.dropLat, widget.dropLng),
    );

    if (result.points.isNotEmpty) {
      polylineCoordinates.clear();
      for (var point in result.points) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      }

      // Calculate distance from polyline points
      _calculateDistance(polylineCoordinates);

      setState(() {
        _polylines.clear();
        _polylines.add(Polyline(
          polylineId: PolylineId('route'),
          points: polylineCoordinates,
          color: Colors.blue,
          width: 6,
        ));
      });
    } else {
      print("No route found or error in fetching route");
    }
  }

  void _calculateDistance(List<LatLng> points) {
    double totalDistance = 0;

    for (int i = 0; i < points.length - 1; i++) {
      totalDistance += _coordinateDistance(
        points[i].latitude,
        points[i].longitude,
        points[i + 1].latitude,
        points[i + 1].longitude,
      );
    }

    setState(() {
      _distanceKm = totalDistance;
    });
  }

  // Haversine formula to calculate distance between two lat/lng points in KM
  double _coordinateDistance(lat1, lon1, lat2, lon2) {
    const p = 0.017453292519943295; // pi / 180
    final a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  @override
  Widget build(BuildContext context) {
    final initialCameraPosition = CameraPosition(
      target: LatLng(widget.pickupLat, widget.pickupLng),
      zoom: 12,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Route Map'),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: initialCameraPosition,
            markers: _markers,
            polylines: _polylines,
            onMapCreated: (controller) {
              _mapController = controller;
            },
          ),

          if (_distanceKm != null)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: Colors.white.withOpacity(0.9),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.directions_car, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        "Distance: ${_distanceKm!.toStringAsFixed(2)} km",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
