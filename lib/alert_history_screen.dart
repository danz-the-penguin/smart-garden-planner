import 'package:flutter/material.dart';
import 'database_helper.dart';

class AlertHistoryScreen extends StatelessWidget {
  const AlertHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Weather Alert History"), backgroundColor: Colors.blue.shade50),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: DatabaseHelper.instance.queryAllAlerts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final alerts = snapshot.data ?? [];

          return alerts.isEmpty
              ? const Center(child: Text("No alerts logged yet."))
              : ListView.builder(
                  itemCount: alerts.length,
                  itemBuilder: (context, index) => Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: Colors.red.shade50,
                    child: ListTile(
                      leading: const Icon(Icons.warning, color: Colors.red),
                      title: Text(alerts[index]['message']),
                      subtitle: Text("Logged on: ${alerts[index]['alert_date'].toString().split('.')[0]}"),
                    ),
                  ),
                );
        },
      ),
    );
  }
}
