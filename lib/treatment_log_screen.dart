import 'package:flutter/material.dart';
import 'database_helper.dart';

class TreatmentLogScreen extends StatefulWidget {
  final int issueId;
  final String symptom;

  const TreatmentLogScreen({super.key, required this.issueId, required this.symptom});

  @override
  State<TreatmentLogScreen> createState() => _TreatmentLogScreenState();
}

class _TreatmentLogScreenState extends State<TreatmentLogScreen> {
  final _treatmentController = TextEditingController();

  void _showAddTreatmentDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Log Treatment"),
        content: TextField(
          controller: _treatmentController,
          decoration: const InputDecoration(labelText: "Action Taken (e.g., Applied Neem Oil)"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (_treatmentController.text.isNotEmpty) {
                await DatabaseHelper.instance.insertTreatment({
                  'issue_id': widget.issueId,
                  'treatment_name': _treatmentController.text,
                });
                _treatmentController.clear();
                Navigator.pop(context);
                setState(() {});
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Treating: ${widget.symptom}"), backgroundColor: Colors.orange.shade50),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: DatabaseHelper.instance.queryTreatmentsForIssue(widget.issueId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final logs = snapshot.data ?? [];

          return logs.isEmpty
              ? const Center(child: Text("No treatments recorded for this issue yet."))
              : ListView.builder(
                  itemCount: logs.length,
                  itemBuilder: (context, index) => ListTile(
                    leading: const Icon(Icons.medication, color: Colors.green),
                    title: Text(logs[index]['treatment_name']),
                    subtitle: Text(logs[index]['date_applied'].toString().split(' ')[0]),
                  ),
                );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTreatmentDialog,
        label: const Text("Add Treatment"),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.orange,
      ),
    );
  }
}
