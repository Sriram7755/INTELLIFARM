import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class DealerChatList extends StatelessWidget {
  const DealerChatList({super.key});

  String _getChatId(String dealerId, String farmerId) {
    return dealerId.hashCode <= farmerId.hashCode
        ? '${dealerId}_$farmerId'
        : '${farmerId}_$dealerId';
  }

  @override
  Widget build(BuildContext context) {
    final dealerUser = FirebaseAuth.instance.currentUser!;
    final dealerId = dealerUser.uid;
    final dealerName = dealerUser.displayName ?? "Dealer";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Chat with Farmers"),
        backgroundColor: Colors.green[700],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'Farmer')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final farmers = snapshot.data!.docs;

          if (farmers.isEmpty) {
            return const Center(child: Text("No farmers available"));
          }

          return ListView.builder(
            itemCount: farmers.length,
            itemBuilder: (context, index) {
              final farmer = farmers[index];
              final farmerId = farmer.id;
              final farmerName = farmer['name'] ?? 'Farmer';
              final farmerPhone = farmer['contact'] ?? '';
              final profileImageUrl = farmer['profileImageUrl'] ?? '';
              final chatId = _getChatId(dealerId, farmerId);

              return FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance
                    .collection('chats')
                    .doc(chatId)
                    .collection('messages')
                    .orderBy('timestamp', descending: true)
                    .limit(1)
                    .get(),
                builder: (context, lastMessageSnapshot) {
                  String lastMessage = '';
                  String timeAgo = '';

                  if (lastMessageSnapshot.hasData &&
                      lastMessageSnapshot.data!.docs.isNotEmpty) {
                    final msgDoc = lastMessageSnapshot.data!.docs.first;
                    lastMessage = msgDoc['text'] ?? '';
                    final timestamp = (msgDoc['timestamp'] as Timestamp?)?.toDate();
                    if (timestamp != null) {
                      final now = DateTime.now();
                      final difference = now.difference(timestamp);
                      if (difference.inMinutes < 1) {
                        timeAgo = "Just now";
                      } else if (difference.inMinutes < 60) {
                        timeAgo = "${difference.inMinutes} min ago";
                      } else if (difference.inHours < 24) {
                        timeAgo = "${difference.inHours} hr ago";
                      } else {
                        timeAgo = "${timestamp.day}/${timestamp.month}/${timestamp.year}";
                      }
                    }
                  }

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 3,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      leading: CircleAvatar(
                        radius: 25,
                        backgroundColor: Colors.green.shade100,
                        backgroundImage: profileImageUrl.isNotEmpty
                            ? NetworkImage(profileImageUrl)
                            : null,
                        child: profileImageUrl.isEmpty
                            ? Text(
                                farmerName[0].toUpperCase(),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.black87),
                              )
                            : null,
                      ),
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              farmerName,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 16),
                            ),
                          ),
                          if (timeAgo.isNotEmpty)
                            Text(
                              timeAgo,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.black54),
                            ),
                        ],
                      ),
                      subtitle: Text(
                        lastMessage.isNotEmpty ? lastMessage : "No messages yet",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.call, color: Colors.green),
                            onPressed: () async {
                              final uri = Uri.parse("tel:$farmerPhone");
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Could not launch phone dialer")),
                                );
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.chat_bubble_outline, color: Colors.green),
                            tooltip: "Chat",
                            onPressed: () {
                            Navigator.pushNamed(
  context,
  '/chatPage',
  arguments: {
    'otherUserId': farmerId,
    'otherUserName': farmerName,
    'isFarmer': false,
  },
);

                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
