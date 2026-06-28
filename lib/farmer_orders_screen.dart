import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'tree_list_screen.dart'; // --- IMPORTED to access UserSession ---
import 'pdf_sales_service.dart'; // Exposes the financial report generation triggers
import 'chat_thread_screen.dart'; // NEW: Imported to navigate straight into conversation channels

class FarmerOrdersScreen extends StatefulWidget {
  const FarmerOrdersScreen({super.key});

  @override
  State<FarmerOrdersScreen> createState() => _FarmerOrdersScreenState();
}

class _FarmerOrdersScreenState extends State<FarmerOrdersScreen> {
  late Future<List<Map<String, dynamic>>> _salesFuture;
  List<Map<String, dynamic>> _currentSalesList = []; 

  @override
  void initState() {
    super.initState();
    _loadSales();
  }

  void _loadSales() {
    final int userId = UserSession.currentUser['user_id'] ?? 0;

    setState(() {
      _salesFuture = DatabaseHelper.instance.querySalesByFarmer(userId).then((data) {
        _currentSalesList = data; 
        return data;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final String farmerName = UserSession.currentUser['name'] ?? "Farmer Merchant";

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Manage My Sales"), 
        backgroundColor: Colors.green.shade50,
        elevation: 0,
        foregroundColor: Colors.green.shade900,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: "Export Sales Ledger PDF",
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Compiling sales logs into ledger document..."),
                  duration: Duration(seconds: 1),
                ),
              );
              await PdfSalesService.generateSalesReport(_currentSalesList, farmerName);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadSales(),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _salesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            final sales = snapshot.data ?? [];
            if (sales.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(), 
                children: const [
                  SizedBox(height: 100),
                  Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Center(child: Text("No incoming orders yet.", style: TextStyle(color: Colors.grey))),
                ],
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sales.length,
              itemBuilder: (context, index) {
                final sale = sales[index];
                final String orderStatus = sale['status'] ?? 'Processing';
                final bool isShipped = orderStatus == 'Shipped';
                final bool isCancelled = orderStatus == 'Cancelled';
                final bool isRefunded = orderStatus == 'Refunded'; 
                final String buyerName = sale['buyer_name'] ?? "Guest Buyer";
                final int buyerId = sale['buyer_id'] ?? 0;
                final int listingId = sale['listing_id'] ?? 0;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 2,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: (isCancelled || isRefunded)
                          ? Colors.red.shade50 
                          : (isShipped ? Colors.blue.shade50 : Colors.orange.shade50),
                      child: Icon(
                        (isCancelled || isRefunded)
                            ? Icons.block_outlined 
                            : (isShipped ? Icons.local_shipping : Icons.pending_actions), 
                        color: (isCancelled || isRefunded) ? Colors.red : (isShipped ? Colors.blue : Colors.orange)
                      ),
                    ),
                    title: Text(
                      sale['title'], 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        "Buyer: $buyerName\nStatus: $orderStatus\nPrice: RM ${(sale['total_price'] as num?)?.toStringAsFixed(2)}",
                        style: TextStyle(color: Colors.grey.shade700, height: 1.3),
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // --- NEW: DIRECT MESSAGING LINK WITH THE BUYER ---
                        if (buyerId > 0)
                          IconButton(
                            icon: const Icon(Icons.chat_bubble_outline, color: Colors.orange),
                            tooltip: "Message Customer",
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatThreadScreen(
                                    contactId: buyerId,
                                    listingId: listingId,
                                    contactName: buyerName,
                                    listingTitle: sale['title'] ?? 'Product Batch',
                                  ),
                                ),
                              );
                            },
                          ),
                        const SizedBox(width: 4),
                        
                        // Existing Logistics Action Gates
                        isCancelled
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.red.shade200),
                                ),
                                child: const Text(
                                  "CANCELLED BY ADMIN", 
                                  style: TextStyle(color: Colors.red, fontSize: 9, fontWeight: FontWeight.bold)
                                ),
                              )
                            : isRefunded
                                ? Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.orange.shade300),
                                    ),
                                    child: const Text(
                                      "REFUNDED BY ADMIN", 
                                      style: TextStyle(color: Colors.orange, fontSize: 9, fontWeight: FontWeight.bold)
                                    ),
                                  )
                                : (isShipped 
                                    ? Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade50,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Text(
                                          "SHIPPED", 
                                          style: TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold)
                                        ),
                                      )
                                    : ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green, 
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        onPressed: () async {
                                          await DatabaseHelper.instance.shipOrder(sale['order_id']);
                                          _loadSales(); 
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text("Order marked as Shipped!"), backgroundColor: Colors.green)
                                            );
                                          }
                                        },
                                        child: const Text("SHIP"),
                                      )),
                      ],
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
