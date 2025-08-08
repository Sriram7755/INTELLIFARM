import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart'; // For current location

class LocationPickerPage extends StatefulWidget {
  final LatLng? initialLocation;
  const LocationPickerPage({super.key, this.initialLocation});

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  GoogleMapController? _mapController;
  LatLng? _selectedLatLng;
  String _selectedAddress = "Move the map to select location";

  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  List<dynamic> _placePredictions = [];

  final String _googleApiKey = "AIzaSyANdxakvvAt99jaHzqJZZaZheUzRw_ZOvU";

  @override
  void initState() {
    super.initState();
    _initLocationAndPermission();
  }

  Future<void> _initLocationAndPermission() async {
    // Request location permission
    var status = await Permission.location.status;
    if (!status.isGranted) {
      final result = await Permission.location.request();
      if (!result.isGranted) {
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Permission Required'),
            content: const Text(
                'Location permission is required to select location on map.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              )
            ],
          ),
        );
        Navigator.of(context).pop();
        return;
      }
    }

    // Get current position
    Position position;
    try {
      position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
    } catch (e) {
      // If failed, fallback to default location
      position = Position(
          latitude: 20.5937,
          longitude: 78.9629,
          timestamp: DateTime.now(),
          accuracy: 1,
          altitude: 0,
          heading: 0,
          speed: 0, 
          speedAccuracy: 0,
          altitudeAccuracy: 0, 
          headingAccuracy: 0,  
          );
    }

    setState(() {
      _selectedLatLng = widget.initialLocation ??
          LatLng(position.latitude, position.longitude);
    });

    if (_selectedLatLng != null) {
      _updateAddress(_selectedLatLng!);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _updateAddress(LatLng position) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        setState(() {
          _selectedAddress =
              "${place.name ?? ''}, ${place.locality ?? ''}, ${place.administrativeArea ?? ''}, ${place.country ?? ''}"
                  .replaceAll(RegExp(r'(, )+$'), '');
        });
      }
    } catch (e) {
      setState(() {
        _selectedAddress = "Address not found";
      });
    }
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (value.isNotEmpty) {
        _getPlacePredictions(value);
      } else {
        setState(() => _placePredictions.clear());
      }
    });
  }

  Future<void> _getPlacePredictions(String input) async {
    final String url =
        "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&key=$_googleApiKey&components=country:in";
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      if (jsonData['status'] == "OK") {
        setState(() {
          _placePredictions = jsonData['predictions'];
        });
      } else {
        print(
            "Places API error: ${jsonData['status']} - ${jsonData['error_message']}");
        setState(() {
          _placePredictions.clear();
        });
      }
    } else {
      print("HTTP error ${response.statusCode} while fetching place predictions");
    }
  }

  Future<void> _selectPrediction(String placeId) async {
    final String url =
        "https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$_googleApiKey";
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      if (jsonData['status'] == "OK") {
        final location = jsonData['result']['geometry']['location'];
        final double lat = location['lat'];
        final double lng = location['lng'];
        final LatLng newLatLng = LatLng(lat, lng);

        if (_mapController != null) {
          await _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(newLatLng, 14),
          );
        }

        setState(() {
          _selectedLatLng = newLatLng;
          _placePredictions.clear();
          _searchController.clear();
        });

        _updateAddress(newLatLng);
      } else {
        print(
            'Place Details API error: ${jsonData['status']} - ${jsonData['error_message']}');
      }
    } else {
      print('HTTP error ${response.statusCode} while fetching place details');
    }
  }

  // New function triggered by pressing search button
  void _onSearchButtonPressed() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      _getPlacePredictions(query);
      FocusScope.of(context).unfocus(); // Hide keyboard
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedLatLng == null) {
      // Loading while waiting for location and permissions
      return Scaffold(
        appBar: AppBar(title: const Text("Select Location")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Location"),
        backgroundColor: Colors.green,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _selectedLatLng!,
              zoom: 14,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
            },
            onCameraMove: (position) {
              _selectedLatLng = position.target;
            },
            onCameraIdle: () {
              if (_selectedLatLng != null) {
                _updateAddress(_selectedLatLng!);
              }
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
          ),
          const Center(
            child: Icon(Icons.location_pin, color: Colors.red, size: 40),
          ),
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 5)
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: _onSearchChanged,
                          decoration: const InputDecoration(
                            hintText: "Search location",
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(15),
                          ),
                          textInputAction: TextInputAction.search,
                          onSubmitted: (_) => _onSearchButtonPressed(),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.search, color: Colors.green),
                        onPressed: _onSearchButtonPressed,
                      ),
                    ],
                  ),
                ),
                if (_placePredictions.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 5)
                      ],
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _placePredictions.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(_placePredictions[index]['description']),
                          onTap: () {
                            _selectPrediction(
                                _placePredictions[index]['place_id']);
                            FocusScope.of(context).unfocus();
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          Positioned(
            bottom: 120,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(10)),
              child: Text(
                _selectedAddress,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.all(15),
              ),
              onPressed: () {
                Navigator.pop(context, {
                  'address': _selectedAddress,
                  'lat': _selectedLatLng!.latitude,
                  'lng': _selectedLatLng!.longitude,
                });
              },
              child: const Text(
                "Confirm Location",
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          )
        ],
      ),
    );
  }
}
