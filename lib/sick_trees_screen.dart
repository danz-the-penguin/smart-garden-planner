import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'tree_detail_screen.dart';

class SickTreesScreen extends StatelessWidget {
  const SickTreesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Trees Needing Attention"),
        backgroundColor: Colors.red.shade50,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: DatabaseHelper.instance.querySickTrees(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final sickTrees = snapshot.data!;
          if (sickTrees.isEmpty) return const Center(child: Text("All trees are healthy!"));

          return ListView.builder(
            itemCount: sickTrees.length,
            itemBuilder: (context, index) {
              final tree = sickTrees[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.warning, color: Colors.red),
                  title: Text(tree['plot_name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("Latest Issue: ${tree['symptom']}"),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TreeDetailScreen(
                          treeId: tree['tree_id'],
                          plotName: tree['plot_name'],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
