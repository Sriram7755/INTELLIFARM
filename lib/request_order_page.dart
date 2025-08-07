import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RequestOrderPage extends StatefulWidget {
  @override
  _RequestOrderPageState createState() => _RequestOrderPageState();
}

class _RequestOrderPageState extends State<RequestOrderPage> {
  final _formKey = GlobalKey<FormState>();
  final dateController = TextEditingController();
  final timeController = TextEditingController();
  final pickupController = TextEditingController();
  final dropController = TextEditingController();
  final loadController = TextEditingController();

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
              _buildInputField(icon: Icons.location_on, controller: pickupController, label: "Pickup Location"),
              _buildInputField(icon: Icons.location_searching, controller: dropController, label: "Drop Location"),
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
                  if (_formKey.currentState!.validate()) {
                    await FirebaseFirestore.instance.collection('driver_requests').add({
                      'from': FirebaseAuth.instance.currentUser!.uid,
                      'to': driver.id,
                      'date': dateController.text,
                      'time': timeController.text,
                      'pickup': pickupController.text,
                      'drop': dropController.text,
                      'load': loadController.text,
                      'status': 'pending',
                      'timestamp': FieldValue.serverTimestamp(),
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Request sent successfully")),
                    );
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Common Input Field
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

  // Date Picker Field
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
          FocusScope.of(context).requestFocus(FocusNode()); // Dismiss keyboard
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
