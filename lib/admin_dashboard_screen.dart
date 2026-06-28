import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'login_screen.dart';
import 'package:sgp/tree_list_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  // --- 1. USER GOVERNANCE, DELETION & EDITING ---

  // Dialog interface allowing the admin to update name, email, or reset passwords securely
  void _showEditUserDialog(Map<String, dynamic> user) {
    final nameController = TextEditingController(text: user['name']);
    final emailController = TextEditingController(text: user['email']);
    final passController = TextEditingController(); // Left empty intentionally for input safety

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Edit Credentials (ID: #${user['user_id']})"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Full Name"),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: "Email Address"),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passController,
                decoration: const InputDecoration(
                  labelText: "New Password",
                  hintText: "Leave blank to preserve current",
                ),
                obscureText: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey.shade900),
            onPressed: () async {
              final String name = nameController.text.trim();
              final String email = emailController.text.trim();
              final String password = passController.text;

              if (name.isEmpty || email.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Name and email fields cannot be empty."))
                );
                return;
              }

              // Client-side structural validation gate matching core project parameters
              if (!RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(email)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please provide a valid email format structure."), backgroundColor: Colors.orange)
                );
                return;
              }

              // Dispatches changes to database helper layer
              int responseCode = await DatabaseHelper.instance.adminUpdateUserFields(
                user['user_id'],
                name,
                email,
                password,
              );

              if (responseCode == -1) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Collision Error: This email address is already taken by another account."),
                      backgroundColor: Colors.redAccent,
                    )
                  );
                }
              } else {
                if (mounted) {
                  Navigator.pop(context);
                  setState(() {}); // Cleanly update current list snapshot view
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Account fields updated successfully!"), backgroundColor: Colors.green)
                  );
                }
              }
            },
            child: const Text("Save", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showUserGovernanceDialog(int userId, String currentStatus) {
    String selectedStatus = currentStatus;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Account Governance"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Select access level for this user:", style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                value: selectedStatus,
                decoration: const InputDecoration(border: OutlineInputBorder(), labelText: "Account Status"),
                items: ['Active', 'Suspended', 'Banned'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (val) => setDialogState(() => selectedStatus = val!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                await DatabaseHelper.instance.updateUserStatus(userId, selectedStatus);
                Navigator.pop(context);
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("User status updated to $selectedStatus")));
              }, 
              child: const Text("Apply Change")
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteUser(int userId, String userName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete User?"),
        content: Text("Warning: Deleting '$userName' will remove all their trees, listings, and transaction history. This cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await DatabaseHelper.instance.deleteUser(userId);
              Navigator.pop(context);
              setState(() {}); 
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Account $userName removed.")));
            },
            child: const Text("Delete Account", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- 2. LISTING MANAGEMENT ---

  void _confirmDeleteListing(int id, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Listing?"),
        content: Text("Are you sure you want to permanently remove '$title' from the market?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await DatabaseHelper.instance.deleteListing(id);
              Navigator.pop(context);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Listing removed.")));
            },
            child: const Text("Delete Listing", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEditListingDialog(Map<String, dynamic> item) {
    final titleCtrl = TextEditingController(text: item['title']);
    final priceCtrl = TextEditingController(text: item['price'].toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Admin: Manage Listing"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: "Product Title")),
            TextField(controller: priceCtrl, decoration: const InputDecoration(labelText: "Price (RM)"), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              await DatabaseHelper.instance.updateListing(item['listing_id'], titleCtrl.text, double.parse(priceCtrl.text));
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text("Update Listing"),
          ),
        ],
      ),
    );
  }

  // --- 3. SHIPMENT & ORDER MANAGEMENT ---

  void _showEditStatusDialog(int orderId, String currentStatus) {
    String selectedStatus = currentStatus;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Update Order Status"),
          content: DropdownButtonFormField<String>(
            value: selectedStatus,
            isExpanded: true,
            items: ['Processing', 'Shipped', 'Delivered', 'Cancelled', 'Refunded'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
            onChanged: (val) => setDialogState(() => selectedStatus = val!),
            decoration: const InputDecoration(labelText: "Order Lifecycle Stage"),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                await DatabaseHelper.instance.updateOrderStatus(orderId, selectedStatus);
                Navigator.pop(context);
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Order status updated.")));
              }, 
              child: const Text("Update")
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteOrder(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Order Record?"),
        content: const Text("Warning: This removes the history of this transaction from all dashboards. Proceed?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await DatabaseHelper.instance.deleteOrder(id);
              Navigator.pop(context);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Order record deleted.")));
            }, 
            child: const Text("Delete Record", style: TextStyle(color: Colors.white))
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5, 
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Admin Command Center"),
          backgroundColor: Colors.blueGrey.shade900,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                UserSession.currentUser = {};
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false);
              },
            )
          ],
          bottom: const TabBar(
            isScrollable: true,
            indicatorColor: Colors.orange,
            tabs: [
              Tab(icon: Icon(Icons.analytics), text: "Overview"),
              Tab(icon: Icon(Icons.people), text: "Users"),
              Tab(icon: Icon(Icons.shopping_cart), text: "Listings"),
              Tab(icon: Icon(Icons.local_shipping), text: "Shipping"),
              Tab(icon: Icon(Icons.report_problem), text: "Reports"), 
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildOverviewTab(),
            _buildUsersTab(),
            _buildListingsTab(),
            _buildShippingTab(),
            _buildReportsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return FutureBuilder<List<dynamic>>(
      future: Future.wait([DatabaseHelper.instance.queryTotalRevenue(), DatabaseHelper.instance.queryAllUsers()]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final revenue = snapshot.data![0] as double;
        final userCount = snapshot.data![1].length;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildAdminStatCard("Total System Revenue", "RM ${revenue.toStringAsFixed(2)}", Icons.payments, Colors.green),
              const SizedBox(height: 12),
              _buildAdminStatCard("Platform Users", userCount.toString(), Icons.people, Colors.blue),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUsersTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: DatabaseHelper.instance.queryAllUsers(),
      builder: (context, snapshot) {
        final users = snapshot.data ?? [];
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 10),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            final String status = user['status'] ?? 'Active';

            if (user['role'] == 'Admin') return const SizedBox.shrink();

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: user['role'] == 'Farmer' ? Colors.green.shade50 : Colors.orange.shade50,
                  child: Icon(Icons.person, color: user['role'] == 'Farmer' ? Colors.green : Colors.orange),
                ),
                title: Row(
                  children: [
                    Expanded( 
                      child: Text(
                        user['name'], 
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                subtitle: Text("Email: ${user['email']}\nRole: ${user['role']} • Status: $status"),
                isThreeLine: true,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_note, color: Colors.blueAccent),
                      tooltip: "Modify Profile Credentials",
                      onPressed: () => _showEditUserDialog(user),
                    ),
                    const SizedBox(width: 2),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      tooltip: "Remove Account",
                      onPressed: () => _confirmDeleteUser(user['user_id'], user['name']),
                    ),
                    const SizedBox(width: 2),
                    IconButton(
                      icon: const Icon(Icons.shield_outlined, color: Colors.blueGrey),
                      tooltip: "Access Governance",
                      onPressed: () => _showUserGovernanceDialog(user['user_id'], status),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildListingsTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: DatabaseHelper.instance.queryAllListings(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final listings = snapshot.data!;
        if (listings.isEmpty) return const Center(child: Text("No marketplace listings found."));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: listings.length, // FIXED: Now references listings array lengths correctly
          itemBuilder: (context, index) {
            final item = listings[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                title: Text(item['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("Seller: ${item['farmer_name']}\nPrice: RM ${item['price']} • Status: ${item['status']}"),
                isThreeLine: true,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showEditListingDialog(item)),
                    IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () => _confirmDeleteListing(item['listing_id'], item['title'])),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildShippingTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: DatabaseHelper.instance.queryAllSales(),
      builder: (context, snapshot) {
        final sales = snapshot.data ?? [];
        if (sales.isEmpty) return const Center(child: Text("No transaction records."));
        return ListView.builder(
          itemCount: sales.length,
          itemBuilder: (context, index) {
            final s = sales[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: Text("Order #${s['order_id']} - ${s['title']}"),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Farmer: ${s['farmer_name']} | Buyer: ${s['buyer_name']}"),
                    Text("Date: ${s['order_date'].toString().split(' ')[0]}"),
                    Text("Status: ${s['status']}", style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.edit_note, color: Colors.blue), onPressed: () => _showEditStatusDialog(s['order_id'], s['status'])),
                    IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () => _confirmDeleteOrder(s['order_id'])),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildReportsTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: DatabaseHelper.instance.queryAllReports(),
      builder: (context, snapshot) {
        final reports = snapshot.data ?? [];
        if (reports.isEmpty) return const Center(child: Text("No fraud reports submitted."));
        return ListView.builder(
          itemCount: reports.length,
          itemBuilder: (context, index) {
            final r = reports[index];
            return Card(
              color: Colors.red.shade50,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: ListTile(
                leading: const Icon(Icons.report_gmailerrorred, color: Colors.red),
                title: Text(r['report_type']),
                subtitle: Text("By: ${r['reporter_name']}\nReason: ${r['content']}"),
                trailing: Text(r['timestamp'].toString().split(' ')[0], style: const TextStyle(fontSize: 10)),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAdminStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color)),
        title: Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        subtitle: Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
