import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProductUploadPage extends StatefulWidget {
  @override
  _ProductUploadPageState createState() => _ProductUploadPageState();
}

class _ProductUploadPageState extends State<ProductUploadPage> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final categoryController = TextEditingController();
  final quantityController = TextEditingController();
  final fixedPriceController = TextEditingController();
  final startingPriceController = TextEditingController();

  File? _image;
  bool _isUploading = false;
  String _pricingType = 'Fixed'; // Fixed or Negotiable

  Future<void> pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) setState(() => _image = File(pickedFile.path));
  }

  Future<String?> uploadToFreeImageHost(File imageFile) async {
    final base64Image = base64Encode(await imageFile.readAsBytes());
    final response = await http.post(
      Uri.parse("https://freeimage.host/api/1/upload?key=6d207e02198a847aa98d0a2a901485a5"),
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: {
        "source": base64Image,
        "format": "json",
      },
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['image']['url'];
    } else {
      print("❌ FreeImage upload failed: ${response.body}");
      return null;
    }
  }

  Future<void> uploadProduct() async {
    if (!_formKey.currentState!.validate() || _image == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("⚠️ Fill all fields and pick an image")));
      return;
    }

    setState(() => _isUploading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("User not signed in")));
        return;
      }

      final imageUrl = await uploadToFreeImageHost(_image!);
      if (imageUrl == null) throw Exception("Image upload failed");

      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final farmerName = userDoc.data()?['name'] ?? 'Unknown';

      final data = {
        'name': nameController.text.trim(),
        'quantity': quantityController.text.trim(),
        'category': categoryController.text.trim(),
        'negotiable': _pricingType == 'Negotiable',
        'farmerId': user.uid,
        'farmerName': farmerName,
        'imageUrl': imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
      };

      if (_pricingType == 'Fixed') {
        data['price'] = fixedPriceController.text.trim();
      } else {
        data['startingPrice'] = startingPriceController.text.trim();
      }

      await FirebaseFirestore.instance.collection('products').add(data);

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("✅ Product uploaded successfully")));

      nameController.clear();
      categoryController.clear();
      quantityController.clear();
      fixedPriceController.clear();
      startingPriceController.clear();
      setState(() {
        _image = null;
        _pricingType = 'Fixed';
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("❌ Upload failed: $e")));
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool isNumber = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      validator: (value) => value == null || value.isEmpty ? "Please enter $label" : null,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    categoryController.dispose();
    quantityController.dispose();
    fixedPriceController.dispose();
    startingPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Upload Product"), backgroundColor: Colors.green[700]),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _image != null
                  ? Image.file(_image!, height: 180, fit: BoxFit.cover)
                  : Container(
                      height: 180,
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        border: Border.all(color: Colors.green.shade200),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(child: Text("No image selected", style: TextStyle(color: Colors.grey[600]))),
                    ),
              SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: pickImage,
                icon: Icon(Icons.photo),
                label: Text("Pick Image"),
              ),
              SizedBox(height: 16),
              _buildTextField(nameController, "Product Name"),
              SizedBox(height: 12),
              _buildTextField(quantityController, "Quantity (e.g. 50kg)"),
              SizedBox(height: 12),
              _buildTextField(categoryController, "Category"),
              SizedBox(height: 20),

              // Pricing dropdown
              DropdownButtonFormField<String>(
                value: _pricingType,
                decoration: InputDecoration(
                  labelText: "Pricing Type",
                  border: OutlineInputBorder(),
                ),
                items: ['Fixed', 'Negotiable']
                    .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _pricingType = value);
                },
              ),
              SizedBox(height: 16),

              // Conditional price fields
              if (_pricingType == 'Fixed')
                _buildTextField(fixedPriceController, "Fixed Price (₹)", isNumber: true),
              if (_pricingType == 'Negotiable')
                _buildTextField(startingPriceController, "Starting Price (₹)", isNumber: true),

              SizedBox(height: 24),
              _isUploading
                  ? Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      onPressed: uploadProduct,
                      icon: Icon(Icons.cloud_upload),
                      label: Text("Upload Product"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[800],
                        padding: EdgeInsets.symmetric(vertical: 14),
                        textStyle: TextStyle(fontSize: 16),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
