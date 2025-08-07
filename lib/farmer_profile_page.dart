import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FarmerProfilePage extends StatefulWidget {
  @override
  _FarmerProfilePageState createState() => _FarmerProfilePageState();
}

class _FarmerProfilePageState extends State<FarmerProfilePage> {
  final currentUser = FirebaseAuth.instance.currentUser;
  String name = '';
  String email = '';
  String contact = '';
  String profileImageUrl = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserInfo();
  }

  Future<void> fetchUserInfo() async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).get();
    setState(() {
      name = doc['name'];
      email = doc['email'];
      contact = doc['contact'] ?? ''; // Assuming contact is stored as 'contact' field
      profileImageUrl = doc['profileImageUrl'] ?? '';
      isLoading = false;
    });
  }

  void editName() async {
    final controller = TextEditingController(text: name);
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Edit Name"),
        content: TextField(controller: controller),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(currentUser!.uid)
                  .update({'name': controller.text});
              setState(() => name = controller.text);
              Navigator.pop(context);
            },
            child: Text("Save"),
          )
        ],
      ),
    );
  }

  void editEmail() async {
    final controller = TextEditingController(text: email);
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Edit Email"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(currentUser!.uid)
                  .update({'email': controller.text});
              setState(() => email = controller.text);
              Navigator.pop(context);
            },
            child: Text("Save"),
          )
        ],
      ),
    );
  }

  void editContact() async {
    final controller = TextEditingController(text: contact);
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Edit Contact Number"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(currentUser!.uid)
                  .update({'contact': controller.text});
              setState(() => contact = controller.text);
              Navigator.pop(context);
            },
            child: Text("Save"),
          )
        ],
      ),
    );
  }

  void logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  void deleteAccount() async {
    await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).delete();
    await currentUser!.delete();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('My Profile'),
        elevation: 0,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 50),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 100,
                            backgroundColor: Colors.green.shade100,
                            backgroundImage: profileImageUrl.isNotEmpty
                                ? NetworkImage(profileImageUrl)
                                : null,
                            child: profileImageUrl.isEmpty
                                ? Icon(Icons.person, size: 50, color: theme.primaryColor)
                                : null,
                          ),
                          SizedBox(height: 16),
                          Text(
                            name,
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 6),
                          Text(email, style: TextStyle(color: Colors.grey[700])),
                          SizedBox(height: 6),
                          Text(contact, style: TextStyle(color: Colors.grey[700])),
                          SizedBox(height: 20),
                          OutlinedButton.icon(
                            onPressed: editName,
                            icon: Icon(Icons.edit),
                            label: Text("Edit Name"),
                            style: OutlinedButton.styleFrom(
                              shape: StadiumBorder(),
                              foregroundColor: theme.primaryColor,
                            ),
                          ),
                          SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: editEmail,
                            icon: Icon(Icons.edit),
                            label: Text("Edit Email"),
                            style: OutlinedButton.styleFrom(
                              shape: StadiumBorder(),
                              foregroundColor: theme.primaryColor,
                            ),
                          ),
                          SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: editContact,
                            icon: Icon(Icons.edit),
                            label: Text("Edit Contact Number"),
                            style: OutlinedButton.styleFrom(
                              shape: StadiumBorder(),
                              foregroundColor: theme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 40),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton.icon(
                        onPressed: logout,
                        icon: Icon(Icons.logout),
                        label: Text("Logout"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[700],
                          padding: EdgeInsets.symmetric(vertical: 14),
                          textStyle: TextStyle(fontSize: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: deleteAccount,
                        icon: Icon(Icons.delete_forever),
                        label: Text("Delete Account"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[600],
                          padding: EdgeInsets.symmetric(vertical: 14),
                          textStyle: TextStyle(fontSize: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
