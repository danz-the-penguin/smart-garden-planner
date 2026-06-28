import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class GrowthChart extends StatelessWidget {
  final List<Map<String, dynamic>> logs;

  const GrowthChart({super.key, required this.logs});

  @override
  Widget build(BuildContext context) {
    if (logs.length < 2) {
      return Container(
        height: 150,
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: const Center(
          child: Text("Log at least 2 measurements to see growth trends", 
            style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic)),
        ),
      );
    }

    // 1. Sort logs by date (oldest first) so the line moves forward in time
    final sortedLogs = List<Map<String, dynamic>>.from(logs).reversed.toList();

    // 2. Prepare Data Spots
    List<FlSpot> heightSpots = [];
    List<FlSpot> trunkSpots = [];

    for (int i = 0; i < sortedLogs.length; i++) {
      double x = i.toDouble();
      heightSpots.add(FlSpot(x, (sortedLogs[i]['height_cm'] as num).toDouble()));
      trunkSpots.add(FlSpot(x, (sortedLogs[i]['trunk_diam_cm'] as num).toDouble()));
    }

    return Container(
      height: 260,
      padding: const EdgeInsets.fromLTRB(10, 20, 20, 10),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          const Text("Tree Growth Progress", 
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.green)),
          const SizedBox(height: 20),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: true, drawVerticalLine: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 35,
                      getTitlesWidget: (val, meta) => Text(
                        val.toInt().toString(),
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
                      ),
                    ),
                  ),
                ),
                lineBarsData: [
                  // --- HEIGHT LINE ---
                  LineChartBarData(
                    spots: heightSpots,
                    isCurved: true,
                    color: Colors.green,
                    barWidth: 4,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(show: true, color: Colors.green.withOpacity(0.1)),
                  ),
                  // --- TRUNK DIAMETER LINE ---
                  LineChartBarData(
                    spots: trunkSpots,
                    isCurved: true,
                    color: Colors.orange,
                    barWidth: 3,
                    dashArray: [5, 5], // Dashed to distinguish from height
                    dotData: const FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // --- LEGEND ---
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegend("Height (cm)", Colors.green, isSolid: true),
              const SizedBox(width: 20),
              _buildLegend("Trunk (cm)", Colors.orange, isSolid: false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(String label, Color color, {required bool isSolid}) {
    return Row(
      children: [
        Container(
          width: 12, height: 12, 
          decoration: BoxDecoration(
            color: isSolid ? color : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: isSolid ? null : Center(child: Container(width: 4, height: 4, color: color)),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
