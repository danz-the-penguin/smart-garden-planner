import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'models/mango_tree.dart';
import 'tree_list_screen.dart'; 

class AddTreeScreen extends StatefulWidget {
  @override
  _AddTreeScreenState createState() => _AddTreeScreenState();
}

class _AddTreeScreenState extends State<AddTreeScreen> {
  final _nameController = TextEditingController();
  bool _isSaving = false;

  void _saveTree() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a plot name")),
      );
      return;
    }

    setState(() => _isSaving = true);

    // 1. Prepare the tree object
    // FIXED: Passing a real DateTime object to satisfy the MangoTree model
    final tree = MangoTree(
      plotName: _nameController.text.trim(),
      plantingDate: DateTime.now(), 
      status: 'seedling',
    );

    // 2. Grab the synced user_id from the session
    final int? currentUserId = UserSession.currentUser['user_id'];

    if (currentUserId != null) {
      // 3. Save to DB 
      // The DatabaseHelper.insertTree method handles the SQL conversion
      await DatabaseHelper.instance.insertTree(tree, currentUserId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Planted ${tree.plotName}! Dashboard updated."),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); 
      }
    } else {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error: User session not found. Please relogin.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Plant New Tree'),
        backgroundColor: Colors.green.shade50,
        elevation: 0,
        foregroundColor: Colors.green.shade800,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Orchard Expansion",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
            ),
            const Text(
              "Register a new plot to start tracking its growth and tasks.",
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 30),
            
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Plot Name / Location',
                hintText: 'e.g. North Section - Row A',
                prefixIcon: const Icon(Icons.map_outlined, color: Colors.green),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: Colors.green, width: 1),
                ),
              ),
            ),
            
            const SizedBox(height: 40),
            
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 2,
                ),
                onPressed: _isSaving ? null : _saveTree,
                child: _isSaving 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : const Text("Confirm Planting", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            
            const SizedBox(height: 20),
            Center(
              child: Text(
                "Farmer: ${UserSession.currentUser['name'] ?? 'Guest'}",
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
