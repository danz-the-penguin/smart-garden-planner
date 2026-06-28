import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfSalesService {
  static Future<void> generateSalesReport(List<Map<String, dynamic>> sales, String farmerName) async {
    final pdf = pw.Document();

    // Calculate total revenue from active/shipped sales rows
    double totalRevenue = 0.0;
    for (var sale in sales) {
      final String status = sale['status'] ?? 'Processing';
      if (status != 'Cancelled' && status != 'Refunded') {
        totalRevenue += (sale['total_price'] as num?)?.toDouble() ?? 0.0;
      }
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Business Header Banner
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: const pw.BoxDecoration(color: PdfColors.green800),
                  width: double.infinity,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        "SMART GARDEN PLANNER - COMMERCIAL SALES LEDGER",
                        style: pw.TextStyle(color: PdfColors.white, fontSize: 13, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        "Merchant: $farmerName",
                        style: const pw.TextStyle(color: PdfColors.white, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),

                // Financial Overview Cards
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      "Historical Commercial Sales Audit",
                      style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.green900),
                    ),
                    pw.Text(
                      "Total Net Revenue: RM ${totalRevenue.toStringAsFixed(2)}",
                      style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.green800),
                    ),
                  ],
                ),
                pw.SizedBox(height: 12),

                // Relational Ledger Table
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                  children: [
                    // Table Header Row
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("Order ID", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("Listing Item", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("Buyer Name", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("Amount", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("Lifecycle Status", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                      ],
                    ),
                    
                    // Table Data Rows Mapping Block
                    if (sales.isEmpty)
                      pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(12),
                            child: pw.Text("No transaction orders logged for this merchant accounts yet.", style: const pw.TextStyle(color: PdfColors.grey500, fontSize: 9)),
                          ),
                          pw.Padding(padding: const pw.EdgeInsets.all(12), child: pw.Text("-")),
                          pw.Padding(padding: const pw.EdgeInsets.all(12), child: pw.Text("-")),
                          pw.Padding(padding: const pw.EdgeInsets.all(12), child: pw.Text("-")),
                          pw.Padding(padding: const pw.EdgeInsets.all(12), child: pw.Text("-")),
                        ],
                      )
                    else
                      ...sales.map((sale) {
                        final double price = (sale['total_price'] as num?)?.toDouble() ?? 0.0;
                        final String orderStatus = sale['status'] ?? 'Processing';
                        
                        return pw.TableRow(
                          children: [
                            pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("#${sale['order_id']}", style: const pw.TextStyle(fontSize: 8))),
                            pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(sale['title'] ?? 'Mango Batch', style: const pw.TextStyle(fontSize: 8))),
                            pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(sale['buyer_name'] ?? 'Guest Buyer', style: const pw.TextStyle(fontSize: 8))),
                            pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("RM ${price.toStringAsFixed(2)}", style: const pw.TextStyle(fontSize: 8))),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(6), 
                              child: pw.Text(
                                orderStatus.toUpperCase(), 
                                style: pw.TextStyle(
                                  fontSize: 7, 
                                  fontWeight: pw.FontWeight.bold,
                                  color: (orderStatus == 'Cancelled' || orderStatus == 'Refunded') ? PdfColors.red700 : (orderStatus == 'Shipped' ? PdfColors.blue700 : PdfColors.orange700)
                                )
                              )
                            ),
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
                    pw.Text("Orchard Location Context: Sabah, Malaysia", style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey500)),
                    pw.Text("Generated securely via Mango Planner Commerce System", style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey500)),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    // Spool up native mobile framework print preview layers immediately
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Commercial_Sales_Ledger_${farmerName.replaceAll(' ', '_')}',
    );
  }
}
