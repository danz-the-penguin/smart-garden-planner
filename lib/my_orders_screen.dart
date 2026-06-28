import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'package:sgp/tree_list_screen.dart';
class MyOrdersScreen extends StatelessWidget {
  const MyOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Grab the current user ID from the session
    final int? userId = UserSession.currentUser['user_id'];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("My Purchases"), 
        backgroundColor: Colors.orange.shade50,
        elevation: 0,
        foregroundColor: Colors.orange.shade900,
      ),
      body: userId == null 
        ? const Center(child: Text("Session expired. Please log in again."))
        : FutureBuilder<List<Map<String, dynamic>>>(
            // Passing the userId parameter for data isolation
            future: DatabaseHelper.instance.queryMyOrders(userId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (snapshot.hasError) {
                return const Center(child: Text("Error loading order history."));
              }

              final orders = snapshot.data ?? [];

              if (orders.isEmpty) {
                return _buildEmptyState();
              }

              return ListView.builder(
                itemCount: orders.length,
                padding: const EdgeInsets.all(16),
                itemBuilder: (context, index) {
                  final order = orders[index];
                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: Colors.orange.shade100),
                    ),
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.orange.shade100,
                          child: Icon(Icons.shopping_bag, color: Colors.orange.shade800),
                        ),
                        title: Text(
                          order['title'] ?? "Mango Package", 
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 6),
                            // --- NEW: DISPLAY SELLER NAME (Requirement: Module 7) ---
                            Row(
                              children: [
                                Icon(Icons.person_outline, size: 14, color: Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Text(
                                  "Seller: ${order['seller_name'] ?? 'Sabah Farmer'}",
                                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Status: ${order['status']}", 
                              style: TextStyle(
                                color: _getStatusColor(order['status']),
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              )
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Ordered on: ${order['order_date'].toString().split(' ')[0]}", 
                              style: const TextStyle(fontSize: 11, color: Colors.grey)
                            ),
                          ],
                        ),
                        trailing: Text(
                          "RM ${order['total_price'].toStringAsFixed(2)}", 
                          style: const TextStyle(
                            fontWeight: FontWeight.bold, 
                            color: Colors.green, 
                            fontSize: 16
                          )
                        ),
                        isThreeLine: true,
                      ),
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
          Icon(Icons.receipt_long_outlined, size: 80, color: Colors.orange.shade100),
          const SizedBox(height: 16),
          const Text(
            "No purchases found.",
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
          ),
          const Text(
            "Head to the marketplace to find fresh Sabah mangoes!",
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'Delivered': return Colors.green.shade700;
      case 'Shipped': return Colors.blue.shade700;
      case 'Processing': return Colors.orange.shade700;
      default: return Colors.grey.shade600;
    }
  }
}
