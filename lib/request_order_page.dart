import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'location_picker_page.dart'; // Import your LocationPickerPage

class RequestOrderPage extends StatefulWidget {
  @override
  _RequestOrderPageState createState() => _RequestOrderPageState();
}

class _RequestOrderPageState extends State<RequestOrderPage> {
  final _formKey = GlobalKey<FormState>();
  final dateController = TextEditingController();
  final timeController = TextEditingController();
  final loadController = TextEditingController();

  LatLng? pickupLatLng;
  String pickupAddress = '';
  LatLng? dropLatLng;
  String dropAddress = '';

  @override
  Widget build(BuildContext context) {
    final driver = ModalRoute.of(context)!.settings.arguments as DocumentSnapshot;

    return Scaffold(
      appBar: AppBar(
        title: Text("Order Request to ${driver['name']}"),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildDatePickerField(dateController, "Date", Icons.date_range),
              _buildInputField(icon: Icons.access_time, controller: timeController, label: "Time"),

              // Pickup location picker
              ListTile(
                leading: Icon(Icons.location_on, color: Colors.green),
                title: Text(pickupAddress.isEmpty ? "Select Pickup Location" : pickupAddress),
                trailing: Icon(Icons.map),
                onTap: () => _handleLocationSelect(isPickup: true),
              ),
              SizedBox(height: 10),

              // Drop location picker
              ListTile(
                leading: Icon(Icons.location_searching, color: Colors.blue),
                title: Text(dropAddress.isEmpty ? "Select Drop Location" : dropAddress),
                trailing: Icon(Icons.map),
                onTap: () => _handleLocationSelect(isPickup: false),
              ),
              SizedBox(height: 10),

              _buildInputField(icon: Icons.local_shipping, controller: loadController, label: "Load Details"),
              SizedBox(height: 30),

              ElevatedButton.icon(
                icon: Icon(Icons.send),
                label: Text("Send Request"),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  textStyle: TextStyle(fontSize: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  backgroundColor: Colors.green[700],
                ),
                onPressed: () async {
                  if (_formKey.currentState!.validate() && pickupLatLng != null && dropLatLng != null) {
                    await FirebaseFirestore.instance.collection('driver_requests').add({
                      'from': FirebaseAuth.instance.currentUser!.uid,
                      'to': driver.id,
                      'date': dateController.text,
                      'time': timeController.text,
                      'pickup_address': pickupAddress,
                      'pickup_lat': pickupLatLng!.latitude,
                      'pickup_lng': pickupLatLng!.longitude,
                      'drop_address': dropAddress,
                      'drop_lat': dropLatLng!.latitude,
                      'drop_lng': dropLatLng!.longitude,
                      'load': loadController.text,
                      'status': 'pending',
                      'timestamp': FieldValue.serverTimestamp(),
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Request sent successfully")),
                    );
                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Please select both pickup and drop locations")),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleLocationSelect({required bool isPickup}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickerPage(
          initialLocation: isPickup
              ? pickupLatLng ?? const LatLng(20.5937, 78.9629)
              : dropLatLng ?? const LatLng(20.5937, 78.9629),
        ),
      ),
    );

    if (result != null && result is Map) {
      setState(() {
        if (isPickup) {
          pickupLatLng = LatLng(result['lat'], result['lng']);
          pickupAddress = result['address'] ?? '';
        } else {
          dropLatLng = LatLng(result['lat'], result['lng']);
          dropAddress = result['address'] ?? '';
        }
      });
    }
  }

  Widget _buildInputField({
    required IconData icon,
    required TextEditingController controller,
    required String label,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        validator: _required,
        decoration: InputDecoration(
          prefixIcon: Icon(icon),
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildDatePickerField(TextEditingController controller, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        validator: _required,
        readOnly: true,
        decoration: InputDecoration(
          prefixIcon: Icon(icon),
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        onTap: () async {
          DateTime? pickedDate = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime.now(),
            lastDate: DateTime(2100),
          );
          if (pickedDate != null) {
            controller.text = "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
          }
        },
      ),
    );
  }

  String? _required(String? value) => (value == null || value.isEmpty) ? 'Required field' : null;
}
