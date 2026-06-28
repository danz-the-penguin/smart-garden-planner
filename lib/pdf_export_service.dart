import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'database_helper.dart';

class PdfExportService {
  static Future<void> generateGrowthReport(int treeId, String plotName) async {
    final pdf = pw.Document();

    // 1. Fetch real biological logs via our isolated Database Helper method
    final List<Map<String, dynamic>> logs = 
        await DatabaseHelper.instance.queryLogsForTree(treeId);

    // 2. Build out the professional report canvas
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start, // FIXED: Named parameter corrected
              children: [
                // Academic Header Banner
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: const pw.BoxDecoration(color: PdfColors.green800),
                  width: double.infinity,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start, // FIXED: Named parameter corrected
                    children: [
                      pw.Text(
                        "SMART GARDEN PLANNER - BIOLOGICAL GROWTH RECORD",
                        style: pw.TextStyle(color: PdfColors.white, fontSize: 14, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        "Target Plot: $plotName",
                        style: const pw.TextStyle(color: PdfColors.white, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 25),

                pw.Text(
                  "Historical Measurement Audit Log",
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.green900),
                ),
                pw.SizedBox(height: 12),

                // Data Dictionary Aligned Relational Table
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                  children: [
                    // Table Header
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text("Date Stamp", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text("Height (cm)", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text("Trunk Diam. (cm)", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text("Automated Growth Stage", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                      ],
                    ),
                    // Data Rows mapping
                    if (logs.isEmpty)
                      pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(12),
                            child: pw.Text("No growth measurements recorded for this plot yet.", style: const pw.TextStyle(color: PdfColors.grey500)),
                          ),
                          pw.Padding(padding: const pw.EdgeInsets.all(12), child: pw.Text("-")),
                          pw.Padding(padding: const pw.EdgeInsets.all(12), child: pw.Text("-")),
                          pw.Padding(padding: const pw.EdgeInsets.all(12), child: pw.Text("-")),
                        ],
                      )
                    else
                      ...logs.map((log) {
                        final dateStr = log['log_date'].toString().split(' ')[0];
                        return pw.TableRow(
                          children: [
                            pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(dateStr, style: const pw.TextStyle(fontSize: 9))),
                            pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text("${log['height_cm']} cm", style: const pw.TextStyle(fontSize: 9))),
                            pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text("${log['trunk_diam_cm']} cm", style: const pw.TextStyle(fontSize: 9))),
                            pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(log['stage'].toString(), style: const pw.TextStyle(fontSize: 9))),
                          ],
                        );
                      }).toList(),
                  ],
                ),
                
                pw.Spacer(),
                pw.Divider(color: PdfColors.grey300, thickness: 0.5),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("Ecosystem Location Context: Sabah, Malaysia", style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey500)),
                    pw.Text("Generated securely via Mango Monitor System Ecosystem", style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey500)),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    // 3. Spool up native mobile framework print sheets immediately
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Growth_Report_${plotName.replaceAll(' ', '_')}',
    );
  }
}
