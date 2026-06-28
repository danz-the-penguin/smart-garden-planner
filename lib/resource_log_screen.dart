import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'tree_list_screen.dart'; // Required for UserSession

class ResourceLogScreen extends StatefulWidget {
  const ResourceLogScreen({super.key});

  @override
  State<ResourceLogScreen> createState() => _ResourceLogScreenState();
}

class _ResourceLogScreenState extends State<ResourceLogScreen> {
  final _amountController = TextEditingController();
  String _resourceType = 'Fertilizer';
  int? _selectedTreeId;
  List<Map<String, dynamic>> _myTrees = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTrees();
  }

  // --- Load plots for the dropdown selection ---
  Future<void> _loadTrees() async {
    final int userId = UserSession.currentUser['user_id'] ?? 0;
    final trees = await DatabaseHelper.instance.queryTreesByUser(userId);
    setState(() {
      _myTrees = trees;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Eco-Impact Logger"), 
        backgroundColor: Colors.teal.shade50,
        foregroundColor: Colors.teal.shade900,
        elevation: 0,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Log plot-specific resource consumption to track sustainability metrics.",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 25),

                // --- PLOT SELECTION (Requirement: Per-Plot Logging) ---
                const Text("Select Plot", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: _selectedTreeId,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.park_outlined, color: Colors.teal),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                  ),
                  hint: const Text("Select target plot (Optional)"),
                  items: _myTrees.map((t) => DropdownMenuItem<int>(
                    value: t['tree_id'], 
                    child: Text(t['plot_name'])
                  )).toList(),
                  onChanged: (val) => setState(() => _selectedTreeId = val),
                ),

                const SizedBox(height: 20),

                // --- RESOURCE TYPE ---
                const Text("Resource Category", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _resourceType,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.category_outlined, color: Colors.teal),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                  ),
                  items: ['Fertilizer', 'Water', 'Pesticide', 'Fuel']
                      .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                      .toList(),
                  onChanged: (val) => setState(() {
                    _resourceType = val!;
                    _amountController.clear();
                  }),
                ),

                const SizedBox(height: 20),

                // --- QUANTITY ---
                const Text("Quantity Used", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: _resourceType == 'Fertilizer' ? "Weight in kg" : "Volume in Liters",
                    suffixText: _resourceType == 'Fertilizer' ? "kg" : "L",
                    prefixIcon: const Icon(Icons.scale_outlined, color: Colors.teal),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                  ),
                ),

                const SizedBox(height: 40),

                // --- SAVE BUTTON ---
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal.shade400,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 0,
                    ),
                    onPressed: () async {
                      if (_amountController.text.isNotEmpty) {
                        final int userId = UserSession.currentUser['user_id'] ?? 0;
                        final double qty = double.tryParse(_amountController.text) ?? 0.0;

                        // Using the new eco-impact logging method from DB Version 29
                        await DatabaseHelper.instance.logEcoResource(
                          userId, 
                          _selectedTreeId, 
                          _resourceType, 
                          qty
                        );

                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Resource usage recorded for sustainability report."),
                              backgroundColor: Colors.teal,
                            )
                          );
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Please enter a quantity."))
                        );
                      }
                    },
                    child: const Text(
                      "LOG RESOURCE USAGE", 
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.1)
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }
}
