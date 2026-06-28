import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'tree_list_screen.dart'; // --- IMPORTED to access UserSession ---

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  @override
  Widget build(BuildContext context) {
    // 1. Get the current farmer's ID from the synced session
    final int userId = UserSession.currentUser['user_id'] ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Pending Tasks"), 
        backgroundColor: Colors.orange.shade50,
        elevation: 0,
        foregroundColor: Colors.orange.shade900,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        // 2. UPDATED: Using the user-specific query for data isolation
        future: DatabaseHelper.instance.queryPendingTasksByUser(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return const Center(child: Text("Error loading tasks."));
          }

          final tasks = snapshot.data ?? [];

          if (tasks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.done_all_rounded, size: 64, color: Colors.green.shade200),
                  const SizedBox(height: 16),
                  const Text(
                    "All caught up!", 
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)
                  ),
                  const Text("No tasks for your orchard today.", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: tasks.length,
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemBuilder: (context, index) {
              final task = tasks[index];
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  leading: const CircleAvatar(
                    backgroundColor: Colors.orangeAccent,
                    child: Icon(Icons.alarm, color: Colors.white),
                  ),
                  title: Text(
                    task['title'], 
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      "Scheduled for: ${task['schedule_dt']}",
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.check_circle_outline, color: Colors.green, size: 28),
                    onPressed: () => _handleTaskCompletion(task['task_id'], task['title']),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // --- HELPER METHODS ---

  Future<void> _handleTaskCompletion(int taskId, String title) async {
    // 1. Mark as completed in DB
    await DatabaseHelper.instance.completeTask(taskId);
    
    // 2. Trigger UI Refresh
    setState(() {});

    // 3. Show feedback
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Task '$title' marked as completed!"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
