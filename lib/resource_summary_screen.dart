import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'tree_list_screen.dart'; // Required for UserSession

class ResourceSummaryScreen extends StatelessWidget {
  const ResourceSummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Get current user ID for data isolation
    final int userId = UserSession.currentUser['user_id'] ?? 0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Eco-Impact Report"), 
        backgroundColor: Colors.teal.shade50,
        foregroundColor: Colors.teal.shade900,
        elevation: 0,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        // FIXED: Passing userId to ensure data isolation
        future: DatabaseHelper.instance.queryResourceSummary(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text("Error loading eco-metrics."));
          }

          final summary = snapshot.data ?? [];
          if (summary.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: summary.length,
            itemBuilder: (context, index) {
              final item = summary[index];
              final String type = item['resource_type'];
              final double total = (item['total'] as num).toDouble();
              
              // Call the Sustainability Advisor logic from Version 33
              final List<String> tips = DatabaseHelper.instance.generateEcoTips(type, total);

              return _buildEcoImpactCard(type, total, tips);
            },
          );
        },
      ),
    );
  }

  Widget _buildEcoImpactCard(String type, double total, List<String> tips) {
    bool isWater = type == 'Water';
    
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.teal.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: isWater ? Colors.blue.shade50 : Colors.green.shade50,
                  child: Icon(
                    isWater ? Icons.water_drop : Icons.science, 
                    color: isWater ? Colors.blue : Colors.green
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    type, 
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                  ),
                ),
                Text(
                  "$total ${isWater ? 'L' : 'kg'}",
                  style: TextStyle(
                    fontSize: 20, 
                    fontWeight: FontWeight.bold, 
                    color: isWater ? Colors.blue.shade700 : Colors.green.shade700
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Divider(),
            ),
            Row(
              children: [
                Icon(Icons.auto_awesome, size: 16, color: Colors.teal.shade400),
                const SizedBox(width: 8),
                const Text(
                  "SUSTAINABILITY ADVISORY",
                  style: TextStyle(
                    fontSize: 11, 
                    fontWeight: FontWeight.bold, 
                    letterSpacing: 1.1, 
                    color: Colors.teal
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...tips.map((tip) => Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Text(
                "• $tip",
                style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.black87),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.eco_outlined, size: 80, color: Colors.teal.shade100),
          const SizedBox(height: 16),
          const Text(
            "No resource data recorded yet.",
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
          ),
          const Text(
            "Log your water and fertilizer use to see impact tips.",
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
