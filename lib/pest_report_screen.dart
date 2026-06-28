import 'package:flutter/material.dart';
import 'database_helper.dart';

class PestReportScreen extends StatefulWidget {
  final int treeId;
  const PestReportScreen({super.key, required this.treeId});

  @override
  State<PestReportScreen> createState() => _PestReportScreenState();
}

class _PestReportScreenState extends State<PestReportScreen> {
  final _symptomController = TextEditingController();
  
  // NEW: Objective Physical Descriptions for Harumanis (Sabah context)
  final List<String> physicalDescriptions = [
    "Chlorosis (Yellowing) on >50% of leaf",
    "Sticky 'Sooty Mold' residue on surface",
    "Dark sunken necrotic lesions on fruit/leaf",
    "Visible 2mm exit holes on stem/fruit",
    "Curled/Distorted new leaf growth",
    "White powdery coating on flower panicles"
  ];

  String? _selectedDescription;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Report Pest/Disease"),
        backgroundColor: Colors.orange.shade50,
        foregroundColor: Colors.orange.shade900,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("What do you see?", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(
              controller: _symptomController,
              decoration: InputDecoration(
                labelText: "Primary Symptom",
                hintText: "e.g. Leaf fall, Stem browning",
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 25),
            
            const Text("Physical Observation (Objective)", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _selectedDescription,
              isExpanded: true,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
              hint: const Text("Select visual evidence"),
              items: physicalDescriptions.map((desc) => DropdownMenuItem(
                value: desc, 
                child: Text(desc, style: const TextStyle(fontSize: 12))
              )).toList(),
              onChanged: (value) => setState(() => _selectedDescription = value),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                onPressed: () async {
                  if (_symptomController.text.isEmpty || _selectedDescription == null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please complete all fields.")));
                    return;
                  }

                  // NEW: Includes physical_description and auto-timestamp
                  await DatabaseHelper.instance.insertPestIssue({
                    'tree_id': widget.treeId,
                    'symptom': _symptomController.text.trim(),
                    'physical_description': _selectedDescription,
                    'report_date': DateTime.now().toIso8601String(), // Requirement: Timestamp
                  });
                  
                  if (mounted) Navigator.pop(context);
                },
                child: const Text("SUBMIT HEALTH REPORT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
