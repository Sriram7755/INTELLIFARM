import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FarmerChatListPage extends StatefulWidget {
  const FarmerChatListPage({super.key});

  @override
  State<FarmerChatListPage> createState() => _FarmerChatListPageState();
}

class _FarmerChatListPageState extends State<FarmerChatListPage> {
  User? currentUser;

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser;
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Chats"),
          centerTitle: true,
          backgroundColor: Colors.green.shade700,
        ),
        body: const Center(
          child: Text("User not logged in"),
        ),
      );
    }

    final String farmerId = currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Chats"),
        centerTitle: true,
        backgroundColor: Colors.green.shade700,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('participants', arrayContains: farmerId)
            .snapshots(),
        builder: (context, chatSnapshot) {
          if (chatSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!chatSnapshot.hasData || chatSnapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No chats found"));
          }

          List<QueryDocumentSnapshot> chatDocs = chatSnapshot.data!.docs;

          return ListView.builder(
            itemCount: chatDocs.length,
            itemBuilder: (context, index) {
              var chatDoc = chatDocs[index];
              List participants = chatDoc['participants'];
              String dealerId = participants.firstWhere(
                (id) => id != farmerId,
                orElse: () => '',
              );

              if (dealerId.isEmpty) {
                return const SizedBox();
              }

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(dealerId).get(),
                builder: (context, dealerSnapshot) {
                  if (!dealerSnapshot.hasData || !dealerSnapshot.data!.exists) {
                    return const ListTile(title: Text("Unknown Dealer"));
                  }

                  var dealerData = dealerSnapshot.data!.data() as Map<String, dynamic>;
                  String dealerName = dealerData['name'] ?? 'Dealer';
                  String initials = dealerName.isNotEmpty ? dealerName[0].toUpperCase() : '?';

                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('chats')
                        .doc(chatDoc.id)
                        .collection('messages')
                        .orderBy('timestamp', descending: true)
                        .limit(1)
                        .snapshots(),
                    builder: (context, messageSnapshot) {
                      String lastMessage = "No messages yet";
                      String time = "";

                      if (messageSnapshot.hasData && messageSnapshot.data!.docs.isNotEmpty) {
                        var data = messageSnapshot.data!.docs.first.data() as Map<String, dynamic>;
                        lastMessage = data['text'] ?? "No message";
                        Timestamp? timestamp = data['timestamp'];
                        if (timestamp != null) {
                          time = _formatTimestamp(timestamp);
                        }
                      }

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.green.shade700,
                          child: Text(initials, style: const TextStyle(color: Colors.white)),
                        ),
                        title: Text(dealerName),
                        subtitle: Text(
                          lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Text(
                          time,
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        onTap: () {
                          Navigator.pushNamed(
  context,
  '/chatPage',
  arguments: {
    'otherUserId': dealerId,
    'otherUserName': dealerName,
    'isFarmer': true,
  },
);

                        },
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final dt = timestamp.toDate();
    final hour = dt.hour > 12 ? dt.hour - 12 : dt.hour;
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return "${hour == 0 ? 12 : hour}:${dt.minute.toString().padLeft(2, '0')} $ampm";
  }
}
