import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'package:sgp/tree_list_screen.dart';

class ChatThreadScreen extends StatefulWidget {
  final int contactId;
  final int listingId;
  final String contactName;
  final String listingTitle;

  const ChatThreadScreen({
    super.key, 
    required this.contactId, 
    required this.listingId, 
    required this.contactName, 
    required this.listingTitle
  });

  @override
  State<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends State<ChatThreadScreen> {
  final _msgController = TextEditingController();
  final int currentUserId = UserSession.currentUser['user_id'];

  // --- UI DIALOG: MUTUAL ACCOUNT REPORTING SYSTEM ---
  void _showReportDialog() {
    final reportController = TextEditingController();
    String reportType = 'Inappropriate Behavior';
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text("Report ${widget.contactName}"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: reportType,
                items: ['Inappropriate Behavior', 'Harassment', 'Fraudulent Attempt', 'Spam']
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setDialogState(() => reportType = v!),
                decoration: const InputDecoration(labelText: "Category"),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: reportController, 
                decoration: const InputDecoration(
                  labelText: "Provide details/evidence",
                  hintText: "Describe the pattern of behavior...",
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                // Inserts the governance report explicitly targeting the other person's contactId
                await DatabaseHelper.instance.insertReport(
                  currentUserId, 
                  widget.contactId, 
                  reportType, 
                  reportController.text.trim()
                );
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("User reported successfully. Admin will review the chat history."),
                      backgroundColor: Colors.redAccent,
                    )
                  );
                }
              }, 
              child: const Text("Submit Report", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.contactName, style: const TextStyle(fontSize: 16)),
            Text(widget.listingTitle, style: const TextStyle(fontSize: 10, color: Colors.black54)),
          ],
        ),
        backgroundColor: Colors.orange.shade50,
        // --- ADDS THE MUTUAL FLAG ACTION VISIBLE TO BOTH ROLES ---
        actions: [
          IconButton(
            icon: const Icon(Icons.flag_outlined, color: Colors.redAccent),
            tooltip: "Report this user",
            onPressed: _showReportDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: DatabaseHelper.instance.queryChatThread(currentUserId, widget.contactId, widget.listingId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final msgs = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: msgs.length,
                  itemBuilder: (context, index) {
                    final m = msgs[index];
                    bool isMe = m['sender_id'] == currentUserId;
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.orange.shade100 : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(m['content']),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(10),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _msgController,
              decoration: const InputDecoration(hintText: "Type a reply...", border: InputBorder.none),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.orange),
            onPressed: () async {
              if (_msgController.text.isEmpty) return;
              await DatabaseHelper.instance.sendMessage(
                currentUserId, widget.contactId, widget.listingId, _msgController.text
              );
              _msgController.clear();
              setState(() {}); // Refresh thread
            },
          ),
        ],
      ),
    );
  }
}
