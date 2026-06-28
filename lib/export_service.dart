import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/material.dart'; 
import 'database_helper.dart';

class ExportService {
  static Future<void> exportHarvestToCSV() async {
    try {
      // 1. Fetch yield data with a relational JOIN
      final db = await DatabaseHelper.instance.database;
      final List<Map<String, dynamic>> data = await db.rawQuery('''
        SELECT t.plot_name, h.quantity_kg, h.quality_grade, h.harvest_date 
        FROM Harvest_Logs h
        JOIN Mango_Trees t ON h.tree_id = t.tree_id
        ORDER BY h.harvest_date DESC
      ''');

      // 2. Prepare the data rows for the report
      List<List<dynamic>> rows = [
        ["Plot Name", "Yield (kg)", "Quality Grade", "Harvest Date"] 
      ];

      for (var row in data) {
        rows.add([
          row['plot_name'],
          row['quantity_kg'],
          row['quality_grade'],
          row['harvest_date']
        ]);
      }

      // 3. Convert to CSV string (v8.0.0+ standard)
      final String csvData = const CsvEncoder().convert(rows);

      // 4. Save to a temporary location with a dynamic filename
      final directory = await getTemporaryDirectory();
      
      // NEW: Added a date timestamp for a professional file name
      final String dateStamp = DateTime.now().toString().split(' ')[0]; // Result: 2026-04-23
      final String path = "${directory.path}/Orchard_Yield_Report_$dateStamp.csv";
      
      final File file = File(path);
      await file.writeAsString(csvData);

      // 5. Open the native Share Sheet with updated text
      await Share.shareXFiles(
        [XFile(path)], 
        subject: 'Orchard Yield Report - $dateStamp',
        text: 'Attached is the generated harvest yield report for the Putatan orchard.'
      );
      
    } catch (e) {
      debugPrint("Export Error: $e");
    }
  }
}
