import 'package:flutter/material.dart';
import 'package:sgp/database_helper.dart';
import 'package:sgp/weather_service.dart'; 
import 'package:sgp/add_tree_screen.dart';
import 'package:sgp/tree_detail_screen.dart';
import 'package:sgp/login_screen.dart';
import 'package:sgp/marketplace_screen.dart';
import 'package:sgp/inbox_screen.dart';
import 'package:sgp/performance_screen.dart';
import 'package:sgp/resource_summary_screen.dart';
import 'package:sgp/resource_log_screen.dart';
import 'package:sgp/task_list_screen.dart';
import 'package:sgp/sick_trees_screen.dart';
import 'package:sgp/fertilizer_guide_screen.dart';
import 'package:sgp/farmer_orders_screen.dart'; // NEW: Added to allow farmers to manage/ship orders
import 'package:sgp/my_orders_screen.dart';     // NEW: Added to allow customers to view order status

// Central Session Configuration for Role Isolation
class UserSession {
  static Map<String, dynamic> currentUser = {};
  static bool get isCustomer => currentUser['role'] == 'Customer';
}

class TreeListScreen extends StatefulWidget {
  const TreeListScreen({super.key}); // Added named super key constructor parameter

  @override
  State<TreeListScreen> createState() => _TreeListScreenState();
}

class _TreeListScreenState extends State<TreeListScreen> {
  Future<Map<String, dynamic>>? _weatherFuture;

  @override
  void initState() {
    super.initState();
    // Initialize the asynchronous API fetch on dashboard mount
    _weatherFuture = WeatherService().fetchWeather();
  }

  // --- UI WIDGET: LIVE WEATHER BANNER CARD ---
  Widget _buildWeatherBanner() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _weatherFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final w = snapshot.data!;
        
        return Card(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          color: Colors.green.shade50,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(color: Colors.green.shade100),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(w['icon'] ?? '☀️', style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${w['temp']}°C • ${w['condition']}",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green.shade800),
                        ),
                        const Text("Location: Kota Kinabalu", style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 20),
                Text(
                  "💡 Advisor: ${w['advice']}",
                  style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.green.shade900),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final String role = UserSession.currentUser['role'] ?? 'Farmer';
    final int userId = UserSession.currentUser['user_id'] ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text("Dashboard ($role)"),
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(UserSession.currentUser['name'] ?? "User Name"),
              accountEmail: Text(UserSession.currentUser['role'] ?? "Role"),
              currentAccountPicture: const CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.person, color: Colors.green)),
              decoration: BoxDecoration(color: Colors.green.shade600),
            ),
            // --- FARMER ONLY DRAWER ACTIONS ---
            if (!UserSession.isCustomer) ...[
              ListTile(leading: const Icon(Icons.grass), title: const Text("My Trees"), onTap: () => Navigator.pop(context)),
              ListTile(leading: const Icon(Icons.add_task), title: const Text("Pending Tasks"), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TaskListScreen()))),
              ListTile(leading: const Icon(Icons.warning_amber), title: const Text("Sick Trees"), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SickTreesScreen()))),
              ListTile(leading: const Icon(Icons.science), title: const Text("Fertilizer Guide"), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const FertilizerGuideScreen()))),
              ListTile(leading: const Icon(Icons.eco), title: const Text("Log Resource Usage"), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ResourceLogScreen()))),
              ListTile(leading: const Icon(Icons.bar_chart), title: const Text("Sustainability Report"), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ResourceSummaryScreen()))),
              ListTile(leading: const Icon(Icons.auto_graph), title: const Text("Efficiency Analytics"), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PerformanceScreen()))),
              ListTile(
                leading: const Icon(Icons.local_shipping_outlined, color: Colors.green), 
                title: const Text("Manage Sales Orders"), 
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const FarmerOrdersScreen()));
                }
              ),
            ],
            // --- GLOBAL MARKETPLACE & INBOX ROUTING ---
            ListTile(leading: const Icon(Icons.storefront), title: const Text("Marketplace"), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MarketplaceScreen()))),
            
            // NEW: Customer specific order tracking portal
            if (UserSession.isCustomer)
              ListTile(
                leading: const Icon(Icons.receipt_long_outlined, color: Colors.orange), 
                title: const Text("My Purchases & Status"), 
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const MyOrdersScreen()));
                }
              ),
              
            ListTile(leading: const Icon(Icons.mail), title: const Text("Inbox Messages"), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const InboxScreen()))),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text("Logout", style: TextStyle(color: Colors.red)),
              onTap: () {
                UserSession.currentUser = {};
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false);
              },
            ),
          ],
        ),
      ),
      body: UserSession.isCustomer
          ? const MarketplaceScreen()
          : FutureBuilder<List<Map<String, dynamic>>>(
              future: DatabaseHelper.instance.queryTreesByUser(userId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final trees = snapshot.data!;
                
                // If there are no trees, still show the weather status at the top
                if (trees.isEmpty) {
                  return Column(
                    children: [
                      _buildWeatherBanner(),
                      const Expanded(
                        child: Center(
                          child: Text("No trees planted yet. Click the FAB to plant one!"),
                        ),
                      ),
                    ],
                  );
                }

                return Column(
                  children: [
                    _buildWeatherBanner(), // Render the weather advisory card at the top of the column layout
                    Expanded(
                      child: ListView.builder(
                        itemCount: trees.length,
                        itemBuilder: (context, index) {
                          final tree = trees[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: ListTile(
                              leading: const Icon(Icons.park, color: Colors.green),
                              title: Text(tree['plot_name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text("Stage: ${tree['status'].toUpperCase()} • Planted: ${tree['planting_date']}"),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TreeDetailScreen(treeId: tree['tree_id'], plotName: tree['plot_name']),
                                ),
                              ).then((_) => setState(() {})),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
      floatingActionButton: UserSession.isCustomer
          ? null
          : FloatingActionButton(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AddTreeScreen())).then((_) => setState(() {})),
            ),
    );
  }
}
