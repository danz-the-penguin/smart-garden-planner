import 'package:flutter/material.dart';
import 'database_helper.dart'; 
import 'package:sgp/tree_list_screen.dart';
import 'chat_thread_screen.dart';

class MarketplaceScreen extends StatefulWidget {
  final String? initialTitle;
  final String? initialWeight;
  final String? initialGrade; // NEW: Metadata support
  final String? initialHarvestDate; // NEW: Metadata support
  final int? harvestId; 

  const MarketplaceScreen({
    super.key, 
    this.initialTitle, 
    this.initialWeight, 
    this.initialGrade, 
    this.initialHarvestDate, 
    this.harvestId
  });

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  late TextEditingController _titleController;
  late TextEditingController _priceController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _priceController = TextEditingController();
    if (widget.initialTitle != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showAddListingDialog());
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  // --- 1. PURCHASE LOGIC (Preserved from Previous Version) ---
  Future<void> _handlePurchase(Map<String, dynamic> item) async {
    final buyerId = UserSession.currentUser['user_id']; 
    await DatabaseHelper.instance.placeOrder(
      item['listing_id'], 
      (item['price'] as num).toDouble(), 
      buyerId
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Successfully purchased ${item['title']}!")));
      setState(() {}); 
    }
  }

  // --- 2. REPORT DIALOG (Preserved & Consolidated) ---
  void _showReportDialog(Map<String, dynamic> item) {
    final _reportController = TextEditingController();
    String _reportType = 'Fake Listing';
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Report Fraud/Issues"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _reportType,
                items: ['Fake Listing', 'Fraudulent Behavior', 'Inappropriate'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => setDialogState(() => _reportType = v!),
                decoration: const InputDecoration(labelText: "Category"),
              ),
              TextField(
                controller: _reportController, 
                decoration: const InputDecoration(labelText: "Describe the issue"),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                await DatabaseHelper.instance.insertReport(
                  UserSession.currentUser['user_id'], 
                  item['listing_id'], 
                  _reportType, 
                  _reportController.text
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Report sent to Admin review.")));
              }, 
              child: const Text("Submit Report", style: TextStyle(color: Colors.white))
            ),
          ],
        ),
      ),
    );
  }

  // --- 3. LISTING CREATION (Preserved & Meta-Aware) ---
  void _showAddListingDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("List Harvest for Sale"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.initialWeight != null)
              Text("Metadata: Grade ${widget.initialGrade ?? 'A'} | ${widget.initialWeight}kg", 
                style: const TextStyle(fontSize: 11, color: Colors.blueGrey)),
            const SizedBox(height: 10),
            TextField(controller: _titleController, decoration: const InputDecoration(labelText: "Product Title")),
            TextField(controller: _priceController, decoration: const InputDecoration(labelText: "Price (RM)"), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final listingData = {
                'title': _titleController.text, 
                'price': double.tryParse(_priceController.text) ?? 0.0, 
                'weight_kg': double.tryParse(widget.initialWeight ?? '0') ?? 0.0,
                'quality_grade': widget.initialGrade ?? 'A',
                'harvest_date': widget.initialHarvestDate ?? DateTime.now().toString().split(' ')[0],
              };
              if (widget.harvestId != null) {
                await DatabaseHelper.instance.listHarvest(listingData, widget.harvestId!, UserSession.currentUser['user_id']);
              } else {
                await DatabaseHelper.instance.insertListing(listingData, UserSession.currentUser['user_id']);
              }
              Navigator.pop(context);
              setState(() {}); 
            },
            child: const Text("Post to Market"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Sabah Mango Market"), 
        backgroundColor: Colors.orange.shade50,
        foregroundColor: Colors.orange.shade900,
        elevation: 0,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: UserSession.isCustomer 
            ? DatabaseHelper.instance.queryMarketplace() 
            : DatabaseHelper.instance.queryMyListings(UserSession.currentUser['user_id']),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final listings = snapshot.data!;
          if (listings.isEmpty) return const Center(child: Text("No items for sale yet."));

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, 
              childAspectRatio: 0.52 // Adjusted for metadata lines
            ),
            itemCount: listings.length,
            itemBuilder: (context, index) {
              final item = listings[index];
              final bool isSold = item['status'] == 'Sold';
              final String listingDate = item['created_at']?.split(' ')[0] ?? 'Recently';
              
              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: Colors.orange.shade50)
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // REPORT FLAG (Top Right)
                      if (UserSession.isCustomer)
                        Align(
                          alignment: Alignment.topRight,
                          child: InkWell(
                            onTap: () => _showReportDialog(item),
                            child: const Icon(Icons.flag_outlined, size: 16, color: Colors.redAccent),
                          ),
                        ),
                      
                      Center(child: Icon(Icons.shopping_basket, size: 45, color: isSold ? Colors.grey : Colors.orange)),
                      const SizedBox(height: 8),
                      
                      Text(item['title'], 
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), 
                        maxLines: 1, overflow: TextOverflow.ellipsis
                      ),
                      
                      // --- METADATA SECTION (Fixed per Problems List) ---
                      if (UserSession.isCustomer)
                        Text("Seller: ${item['farmer_name'] ?? 'Local Farmer'}", 
                          style: const TextStyle(fontSize: 10, color: Colors.blueGrey, fontStyle: FontStyle.italic)),
                      
                      Text("Grade ${item['quality_grade'] ?? 'A'} • ${item['weight_kg']}kg", 
                        style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w600)),
                      Text("Harvested: ${item['harvest_date'] ?? 'N/A'}", 
                        style: const TextStyle(fontSize: 9, color: Colors.grey)),
                      Text("Listed: $listingDate", 
                        style: const TextStyle(fontSize: 9, color: Colors.teal)),
                      
                      const Spacer(),
                      Text("RM ${item['price'].toStringAsFixed(2)}", 
                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
                      
                      const SizedBox(height: 8),

                      if (UserSession.isCustomer)
                        Row(
                          children: [
                            Expanded(child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isSold ? Colors.grey : Colors.orange, 
                                padding: EdgeInsets.zero, 
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                              ),
                              onPressed: isSold ? null : () => _handlePurchase(item), 
                              child: Text(isSold ? "SOLD" : "BUY", style: const TextStyle(fontSize: 11, color: Colors.white)))),
                            const SizedBox(width: 5),
                            IconButton(
                              constraints: const BoxConstraints(maxWidth: 35, maxHeight: 35),
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.chat_bubble_outline, size: 18, color: Colors.orange), 
                              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ChatThreadScreen(
                                contactId: item['user_id'], 
                                listingId: item['listing_id'], 
                                contactName: item['farmer_name'] ?? 'Farmer', 
                                listingTitle: item['title']
                              )))),
                          ],
                        )
                      else
                        // FARMER INTERFACE FIX: Professional status bar
                        Container(
                          width: double.infinity, 
                          padding: const EdgeInsets.symmetric(vertical: 6), 
                          decoration: BoxDecoration(
                            color: isSold ? Colors.grey.shade100 : Colors.green.shade50, 
                            borderRadius: BorderRadius.circular(8)
                          ), 
                          child: Text(item['status'].toUpperCase(), 
                            textAlign: TextAlign.center, 
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: isSold ? Colors.grey : Colors.green))
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
