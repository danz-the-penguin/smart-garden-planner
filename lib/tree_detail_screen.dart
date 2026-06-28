import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'pest_report_screen.dart';
import 'growth_chart.dart';
import 'marketplace_screen.dart';
import 'treatment_log_screen.dart'; 
import 'tree_list_screen.dart'; // Required for UserSession
import 'pdf_export_service.dart'; // NEW: Imported to expose background print-spooler document methods

class TreeDetailScreen extends StatefulWidget {
  final int treeId;
  final String plotName;

  const TreeDetailScreen({super.key, required this.treeId, required this.plotName});

  @override
  State<TreeDetailScreen> createState() => _TreeDetailScreenState();
}

class _TreeDetailScreenState extends State<TreeDetailScreen> {
  final _heightController = TextEditingController();
  final _diamController = TextEditingController();
  final _harvestKgController = TextEditingController();
  String _selectedGrade = 'A';

  // --- DIALOG: SMART LOG GROWTH ---
  void _showLogDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Log Growth Measurement"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _heightController, 
              decoration: const InputDecoration(labelText: "Current Height (cm)", hintText: "e.g. 75"), 
              keyboardType: TextInputType.number
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _diamController, 
              decoration: const InputDecoration(labelText: "Trunk Diameter (cm)", hintText: "e.g. 1.2"), 
              keyboardType: TextInputType.number
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              double h = double.tryParse(_heightController.text) ?? 0.0;
              double d = double.tryParse(_diamController.text) ?? 0.0;
              
              if (h > 0 && d > 0) {
                await DatabaseHelper.instance.insertGrowthLogWithAutoStage(widget.treeId, h, d);
                
                _heightController.clear(); 
                _diamController.clear();
                
                if (mounted) {
                  Navigator.pop(context);
                  setState(() {}); 
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Measurement saved! Tree stage updated automatically."),
                      backgroundColor: Colors.green,
                    )
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please enter valid numbers"))
                );
              }
            }, 
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteLog(int logId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Entry?"),
        content: const Text("This measurement will be permanently removed from the history and chart."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade50),
            onPressed: () async {
              await DatabaseHelper.instance.deleteGrowthLog(logId);
              Navigator.pop(context);
              setState(() {}); 
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Measurement deleted"), backgroundColor: Colors.redAccent)
              );
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showHarvestDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Log Harvest Yield"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _harvestKgController,
                decoration: const InputDecoration(labelText: "Total Weight (kg)"),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 15),
              DropdownButton<String>(
                isExpanded: true,
                value: _selectedGrade,
                items: ['A', 'B', 'C'].map((g) => DropdownMenuItem(value: g, child: Text("Grade $g"))).toList(),
                onChanged: (val) => setDialogState(() => _selectedGrade = val!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                if (_harvestKgController.text.isNotEmpty) {
                  await DatabaseHelper.instance.insertHarvest({
                    'tree_id': widget.treeId,
                    'quantity_kg': double.tryParse(_harvestKgController.text) ?? 0.0,
                    'quality_grade': _selectedGrade,
                    'status': 'available', 
                  });
                  _harvestKgController.clear();
                  Navigator.pop(context);
                  setState(() {}); 
                }
              }, 
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, 
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.plotName),
          backgroundColor: Colors.green.shade50,
          // --- NEW: ADDS NATIVE PDF GEN PORTAL ACCESSIBLE TO FARMERS ONLY ---
          actions: [
            if (!UserSession.isCustomer)
              IconButton(
                icon: const Icon(Icons.picture_as_pdf_outlined, color: Colors.green),
                tooltip: "Export Growth PDF",
                onPressed: () async {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Assembling biological metrics into PDF..."),
                      duration: Duration(seconds: 1),
                    ),
                  );
                  // Dispatches transaction arrays directly into the layout printer
                  await PdfExportService.generateGrowthReport(widget.treeId, widget.plotName);
                },
              ),
          ],
          bottom: const TabBar(
            labelColor: Colors.green,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.green,
            tabs: [
              Tab(icon: Icon(Icons.show_chart), text: "Growth"),
              Tab(icon: Icon(Icons.bug_report), text: "Health"),
              Tab(icon: Icon(Icons.shopping_basket), text: "Harvest"), 
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildGrowthTab(),
            _buildPestTab(),
            _buildHarvestTab(), 
          ],
        ),
        floatingActionButton: UserSession.isCustomer
            ? null
            : Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  FloatingActionButton.extended(
                    heroTag: "harvestBtn",
                    onPressed: _showHarvestDialog,
                    label: const Text("Log Harvest"),
                    icon: const Icon(Icons.add_shopping_cart),
                    backgroundColor: Colors.blue.shade200,
                  ),
                  const SizedBox(height: 12),
                  FloatingActionButton.extended(
                    heroTag: "pestBtn",
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => PestReportScreen(treeId: widget.treeId)))
                      .then((_) => setState(() {}));
                    },
                    label: const Text("Report Pest"),
                    icon: const Icon(Icons.bug_report),
                    backgroundColor: Colors.orange.shade200,
                  ),
                  const SizedBox(height: 12),
                  FloatingActionButton.extended(
                    heroTag: "growthBtn",
                    onPressed: _showLogDialog,
                    label: const Text("Log Growth"),
                    icon: const Icon(Icons.add_chart),
                    backgroundColor: Colors.green.shade200,
                  ),
                ],
              ),
      ),
    );
  }

  // --- TAB 1: GROWTH (Includes reasoning note for thesis) ---
  Widget _buildGrowthTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: DatabaseHelper.instance.queryLogsForTree(widget.treeId),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        
        final logs = snapshot.data ?? [];
        return Column(
          children: [
            if (logs.isNotEmpty) ...[
              Padding(padding: const EdgeInsets.all(16.0), child: GrowthChart(logs: logs)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  "Note: Visual trends allow for farmer-driven interpretation of optimal growth rates.",
                  style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            const Divider(height: 25),
            Expanded(
              child: logs.isEmpty
                ? const Center(child: Text("No growth logs yet."))
                : ListView.builder(
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(color: Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(10)
                        ),
                        child: ListTile(
                          leading: const Icon(Icons.height, color: Colors.blue),
                          title: Text("H: ${log['height_cm']} cm | ${log['stage']}"),
                          subtitle: Text("Trunk: ${log['trunk_diam_cm']} cm • ${log['log_date'].toString().split('T')[0]}"),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                            onPressed: () => _confirmDeleteLog(log['log_id']),
                          ),
                        ),
                      );
                    },
                  ),
            ),
          ],
        );
      },
    );
  }

  // --- TAB 2: PESTS (Refined with physical descriptions & timestamps) ---
  Widget _buildPestTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: DatabaseHelper.instance.queryPestIssuesForTree(widget.treeId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        
        final issues = snapshot.data ?? [];
        return issues.isEmpty 
          ? const Center(child: Text("No health issues reported."))
          : ListView.builder(
              itemCount: issues.length,
              itemBuilder: (context, index) {
                final issue = issues[index];
                final String description = issue['physical_description'] ?? "No observation recorded";
                final String date = issue['report_date'].toString().split(' ')[0];

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.orange.shade100)),
                  color: Colors.orange.shade50,
                  child: ListTile(
                    leading: const Icon(Icons.biotech_outlined, color: Colors.orange),
                    title: Text(issue['symptom'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("Evidence: $description\nLogged: $date", style: const TextStyle(fontSize: 11)),
                    isThreeLine: true,
                    trailing: const Icon(Icons.chevron_right, size: 16),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => TreatmentLogScreen(issueId: issue['issue_id'], symptom: issue['symptom'])));
                    },
                  ),
                );
              },
            );
      },
    );
  }

  // --- TAB 3: HARVEST ---
  Widget _buildHarvestTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: DatabaseHelper.instance.queryHarvestForTree(widget.treeId),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text("Database Error: ${snapshot.error}"));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

        final logs = snapshot.data ?? [];
        return logs.isEmpty 
          ? const Center(child: Text("No harvest recorded yet."))
          : ListView.builder(
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final log = logs[index];
                final bool isUploaded = log['status'] == 'Listed';

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  color: isUploaded ? Colors.grey.shade100 : Colors.blue.shade50,
                  child: ListTile(
                    leading: Icon(Icons.scale, color: isUploaded ? Colors.grey : Colors.blue),
                    title: Text("${log['quantity_kg']} kg", 
                      style: TextStyle(fontWeight: FontWeight.bold, color: isUploaded ? Colors.grey : Colors.black87)),
                    subtitle: Text("Quality Grade: ${log['quality_grade']}"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(log['harvest_date'].toString().split(' ')[0], style: const TextStyle(fontSize: 10, color: Colors.grey)),
                        const SizedBox(width: 12),
                        
                        if (isUploaded)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              "UPLOADED", 
                              style: TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold),
                            ),
                          )
                        else
                          IconButton(
                            icon: const Icon(Icons.sell, color: Colors.orange, size: 22),
                            tooltip: "Sell this harvest",
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MarketplaceScreen(
                                    initialTitle: "Grade ${log['quality_grade']} - ${widget.plotName}",
                                    initialWeight: log['quantity_kg'].toString(),
                                    harvestId: log['harvest_id'], 
                                  ),
                                ),
                              ).then((_) => setState(() {})); 
                            },
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
}
