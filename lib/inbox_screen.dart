import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'tree_list_screen.dart';
import 'chat_thread_screen.dart'; // REQUIRED for bi-directional chat

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  @override
  Widget build(BuildContext context) {
    final int userId = UserSession.currentUser['user_id'] ?? 0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("My Messages"),
        backgroundColor: Colors.teal.shade50,
        foregroundColor: Colors.teal.shade900,
        elevation: 0,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        // FIXED: Uses queryUserInbox which identifies the correct contact name
        future: DatabaseHelper.instance.queryUserInbox(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final messages = snapshot.data ?? [];

          if (messages.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 10),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final msg = messages[index];
              
              // 'contact_name' is dynamically set in our SQL query
              final String contactName = msg['contact_name'] ?? "User";
              final String listingTitle = msg['listing_title'] ?? "Mango Inquiry";
              
              return Card(
                elevation: 0,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                  side: BorderSide(color: Colors.teal.shade50),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.teal.shade100,
                    child: Text(
                      contactName[0].toUpperCase(), 
                      style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)
                    ),
                  ),
                  title: Text(contactName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Product: $listingTitle", 
                        style: TextStyle(fontSize: 11, color: Colors.teal.shade700, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(msg['content'], maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(msg['timestamp'].toString().split(' ')[0], style: const TextStyle(fontSize: 9, color: Colors.grey)),
                      const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                    ],
                  ),
                  onTap: () {
                    // --- THE FIX: NAVIGATE TO THREAD TO ALLOW REPLIES ---
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatThreadScreen(
                          // Determine the contact's ID dynamically
                          contactId: msg['sender_id'] == userId ? msg['receiver_id'] : msg['sender_id'],
                          listingId: msg['related_listing_id'],
                          contactName: contactName,
                          listingTitle: listingTitle,
                        ),
                      ),
                    ).then((_) => setState(() {})); // Refresh inbox list on return
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 80, color: Colors.teal.shade50),
          const SizedBox(height: 16),
          const Text("No messages yet.", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          const Text("Communication with buyers/farmers will appear here.", style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}
