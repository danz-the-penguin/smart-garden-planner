import 'package:flutter/material.dart';

class FertilizerGuideScreen extends StatefulWidget {
  const FertilizerGuideScreen({super.key});

  @override
  State<FertilizerGuideScreen> createState() => _FertilizerGuideScreenState();
}

class _FertilizerGuideScreenState extends State<FertilizerGuideScreen> {
  String? _selectedStage;
  String? _selectedSymptom;

  // Data based on standard Mango cultivation (Harumanis context)
  final Map<String, Map<String, String>> _recommendations = {
    'Seedling': {
      'npk': '15-15-15 (Equal Balance)',
      'dosage': '50g - 100g per tree',
      'freq': 'Every 3 months',
      'tip': 'Focus on root establishment. Apply after rain.'
    },
    'Vegetative': {
      'npk': '15-15-15 or Organic Compost',
      'dosage': '200g - 500g per tree',
      'freq': 'Every 4 months',
      'tip': 'High nitrogen supports leaf and branch growth.'
    },
    'Flowering': {
      'npk': '12-12-17-2 (High Potassium)',
      'dosage': '500g per tree',
      'freq': 'Once at first bud sign',
      'tip': 'Potassium triggers fruit set. Reduce irrigation slightly.'
    },
    'Fruiting': {
      'npk': '12-12-17-2 + Trace Elements',
      'dosage': '1kg per tree',
      'freq': 'Every 2 months until harvest',
      'tip': 'Helps fruit size and sweetness (Brix level).'
    },
    'Post-Harvest': {
      'npk': '15-15-15 + Organic Mulch',
      'dosage': '1kg - 2kg per tree',
      'freq': 'Immediately after pruning',
      'tip': 'Replenish lost nutrients for the next season.'
    },
  };

  final Map<String, String> _symptomFixes = {
    'Yellow Leaves (Old)': 'Nitrogen Deficiency: Apply NPK 15-15-15 immediately.',
    'Burnt Leaf Edges': 'Potassium Deficiency: Apply MOP or 12-12-17-2.',
    'Small/Pale New Leaves': 'Zinc/Iron Deficiency: Use a micronutrient foliar spray.',
    'Slow Growth': 'General Malnutrition: Check soil pH and apply balanced organic fertilizer.'
  };

  @override
  Widget build(BuildContext context) {
    final recommendation = _selectedStage != null ? _recommendations[_selectedStage] : null;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("Fertilizer Advisor"),
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 25),
            
            const Text("Tree Growth Stage", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildDropdown(
              hint: "Select current stage",
              value: _selectedStage,
              items: _recommendations.keys.toList(),
              onChanged: (val) => setState(() { _selectedStage = val; _selectedSymptom = null; }),
              icon: Icons.stadium_outlined,
            ),

            const SizedBox(height: 20),

            const Text("Or Observed Symptom", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildDropdown(
              hint: "Select a visible issue",
              value: _selectedSymptom,
              items: _symptomFixes.keys.toList(),
              onChanged: (val) => setState(() { _selectedSymptom = val; _selectedStage = null; }),
              icon: Icons.visibility_outlined, // FIXED: Lowercase 'v'
            ),

            const SizedBox(height: 30),

            if (recommendation != null) _buildResultCard(recommendation),
            if (_selectedSymptom != null) _buildSymptomCard(_symptomFixes[_selectedSymptom!]!),
            
            if (_selectedStage == null && _selectedSymptom == null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Column(
                    children: [
                      Icon(Icons.info_outline, size: 50, color: Colors.grey.shade300),
                      const SizedBox(height: 10),
                      Text("Select a stage or symptom to see\nspecific NPK recommendations", 
                        textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade500)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(15)),
      child: Row(
        children: [
          Icon(Icons.science_outlined, color: Colors.green, size: 30), // FIXED: Lowercase 's'
          const SizedBox(width: 15),
          const Expanded(
            child: Text(
              "Get expert recommendations for nutrient management based on your orchard's status.",
              style: TextStyle(fontSize: 13, color: Colors.green),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildDropdown({required String hint, required String? value, required List<String> items, required Function(String?) onChanged, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          hint: Text(hint),
          value: value,
          icon: Icon(icon, color: Colors.green),
          items: items.map((String item) {
            return DropdownMenuItem<String>(value: item, child: Text(item));
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildResultCard(Map<String, String> data) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(color: Colors.green.shade600, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
            width: double.infinity,
            child: Text("Recommended Plan: $_selectedStage", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildInfoRow(Icons.biotech, "NPK Ratio", data['npk']!),
                const Divider(),
                _buildInfoRow(Icons.scale, "Dosage", data['dosage']!), // FIXED: Lowercase 's'
                const Divider(),
                _buildInfoRow(Icons.event_repeat, "Frequency", data['freq']!), // FIXED: Lowercase 'e'
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(10)),
                  child: Text("💡 ${data['tip']}", style: TextStyle(fontSize: 12, color: Colors.orange.shade900)),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSymptomCard(String fix) {
    return Card(
      color: Colors.red.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.red.shade100)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 30), // FIXED: Lowercase 'w'
            const SizedBox(height: 10),
            Text(fix, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(color: Colors.grey)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
