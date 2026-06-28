import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'database_helper.dart';
import 'tree_list_screen.dart'; // REQUIRED: Access UserSession for data isolation

class PerformanceScreen extends StatelessWidget {
  const PerformanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Grab the current user ID
    final int userId = UserSession.currentUser['user_id'] ?? 0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Efficiency Analytics"), 
        backgroundColor: Colors.purple.shade50,
        foregroundColor: Colors.purple.shade900,
        elevation: 0,
      ),
      body: FutureBuilder<Map<String, List<double>>>(
        // FIXED: Passing userId to satisfy DatabaseHelper Version 33
        future: DatabaseHelper.instance.queryCorrelationData(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return const Center(child: Text("Error loading analytics data."));
          }

          // 2. FIXED: Removed hardcoded dummy data to prevent "Global Data Leak" appearance
          // Fallback to [0.0, 0.0] if the list is empty so fl_chart doesn't crash.
          var yields = snapshot.data?['yields'] ?? [0.0];
          var fert = snapshot.data?['fert'] ?? [0.0];

          // fl_chart requires at least 2 points to draw a line
          if (yields.length < 2) yields = [0.0, ...yields];
          if (fert.length < 2) fert = [0.0, ...fert];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Orchard Performance Trend", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                const Text("Correlation: Fertilizer vs. Harvest Yield", style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 40),
                
                AspectRatio(
                  aspectRatio: 1.3,
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: true, drawVerticalLine: false),
                      borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey.shade200)),
                      
                      titlesData: FlTitlesData(
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          axisNameWidget: const Text("Recent Logs", style: TextStyle(fontSize: 10)),
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              return Text("${value.toInt() + 1}", style: const TextStyle(fontSize: 10));
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          axisNameWidget: const Text("Weight (kg)", style: TextStyle(fontSize: 10)),
                          sideTitles: const SideTitles(
                            showTitles: true, 
                            reservedSize: 40,
                          ),
                        ),
                      ),

                      lineBarsData: [
                        LineChartBarData( // YIELD (REAL DATA)
                          spots: yields.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                          color: Colors.purple,
                          barWidth: 4,
                          isCurved: true,
                          dotData: const FlDotData(show: true),
                          belowBarData: BarAreaData(show: true, color: Colors.purple.withOpacity(0.1)),
                        ),
                        LineChartBarData( // FERTILIZER (REAL DATA)
                          spots: fert.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                          color: Colors.blue,
                          dashArray: [5, 5],
                          barWidth: 3,
                          isCurved: true,
                          dotData: const FlDotData(show: true),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 30),
                _buildLegendItem("Total Harvest Yield (kg)", Colors.purple, isSolid: true),
                const SizedBox(height: 10),
                _buildLegendItem("Fertilizer Input (kg)", Colors.blue, isSolid: false),
                
                const SizedBox(height: 40),
                _buildEfficiencyInsight(yields, fert),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, {required bool isSolid}) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 4,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
            border: isSolid ? null : Border.all(color: color, width: 1),
          ),
        ),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
      ],
    );
  }

  Widget _buildEfficiencyInsight(List<double> yields, List<double> fert) {
    // Calculate simple efficiency ratio
    double totalYield = yields.fold(0, (p, c) => p + c);
    double totalFert = fert.fold(0, (p, c) => p + c);
    double ratio = totalFert > 0 ? totalYield / totalFert : 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.purple.shade50, 
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.purple.shade100),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.auto_graph, color: Colors.purple),
              const SizedBox(width: 10),
              const Text("Efficiency Ratio", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple)),
              const Spacer(),
              Text("${ratio.toStringAsFixed(2)}x", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.purple)),
            ],
          ),
          const Divider(height: 25),
          Text(
            ratio > 0 
              ? "You are producing ${ratio.toStringAsFixed(1)}kg of mangoes for every 1kg of fertilizer used. Great job!"
              : "Insufficient data to calculate efficiency. Log more harvests and fertilizer use.",
            style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}
