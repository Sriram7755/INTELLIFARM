import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _contactController = TextEditingController();
  final _licenseController = TextEditingController();
  final _dobController = TextEditingController();

  bool _obscurePassword = true;
  File? _profileImage;
  String _selectedRole = 'Farmer';
  bool _isLoading = false;
  bool _showDriverStatus = false;

  Future<void> pickProfileImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) setState(() => _profileImage = File(pickedFile.path));
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
      print("Image upload error: ${response.body}");
      return null;
    }
  }

  Future<void> registerUser() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final contact = _contactController.text.trim();
    final license = _licenseController.text.trim();
    final dob = _dobController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty || contact.isEmpty || _profileImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please fill all fields and select an image")));
      return;
    }

    if (_selectedRole == 'Driver' && (license.isEmpty || dob.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Driver must provide license and DOB")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final imageUrl = await uploadToFreeImageHost(_profileImage!);
      if (imageUrl == null) throw Exception("Image upload failed");

      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      final userData = {
        'uid': userCredential.user!.uid,
        'name': name,
        'email': email,
        'role': _selectedRole,
        'profileImageUrl': imageUrl,
        'contact': contact,
        'createdAt': FieldValue.serverTimestamp(),
      };

      if (_selectedRole == 'Driver') {
        userData['licenseNumber'] = license;
        userData['dob'] = dob;
        userData['driverStatus'] = 'pending';
      }

      await FirebaseFirestore.instance.collection('users')
          .doc(userCredential.user!.uid).set(userData);

      if (_selectedRole == 'Driver') {
        setState(() => _showDriverStatus = true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Registration successful")));
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      print("❌ Registration error: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget buildDriverStatusPopup() {
    return Positioned(
      bottom: 50,
      left: 20,
      right: 20,
      child: AnimatedOpacity(
        opacity: _showDriverStatus ? 1.0 : 0.0,
        duration: Duration(milliseconds: 500),
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.pending_actions, color: Colors.green[800], size: 36),
                SizedBox(height: 8),
                Text("Your application is under review", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(height: 6),
                Text("You will be notified once your driver profile is approved.",
                    textAlign: TextAlign.center, style: TextStyle(fontSize: 14)),
                SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                  child: Text("Return to Login"),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectDOB() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Register')),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: ListView(
              children: [
                Center(
                  child: GestureDetector(
                    onTap: pickProfileImage,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
                      backgroundColor: Colors.grey[200],
                      child: _profileImage == null
                          ? Icon(Icons.camera_alt, color: Colors.grey[700], size: 32)
                          : null,
                    ),
                  ),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: 'Name', prefixIcon: Icon(Icons.person)),
                ),
                SizedBox(height: 15),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email)),
                ),
                SizedBox(height: 15),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                ),
                SizedBox(height: 15),
                TextField(
                  controller: _contactController,
                  decoration: InputDecoration(labelText: 'Contact Number', prefixIcon: Icon(Icons.phone)),
                  keyboardType: TextInputType.phone,
                ),
                SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  decoration: InputDecoration(labelText: 'Role', prefixIcon: Icon(Icons.person_outline)),
                  items: ['Farmer', 'Dealer', 'Driver']
                      .map((role) => DropdownMenuItem(value: role, child: Text(role)))
                      .toList(),
                  onChanged: (value) => setState(() => _selectedRole = value!),
                ),
                if (_selectedRole == 'Driver') ...[
                  SizedBox(height: 15),
                  TextField(
                    controller: _licenseController,
                    decoration: InputDecoration(labelText: 'License Number', prefixIcon: Icon(Icons.credit_card)),
                  ),
                  SizedBox(height: 15),
                  TextFormField(
                    controller: _dobController,
                    readOnly: true,
                    onTap: _selectDOB,
                    decoration: InputDecoration(labelText: 'Date of Birth', prefixIcon: Icon(Icons.cake)),
                  ),
                ],
                SizedBox(height: 25),
                _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: registerUser,
                        child: Text("Register", style: TextStyle(fontSize: 16)),
                      ),
                TextButton(
                  onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                  child: Text("Already have an account? Login"),
                )
              ],
            ),
          ),
          if (_showDriverStatus) buildDriverStatusPopup(),
        ],
      ),
    );
  }
}
