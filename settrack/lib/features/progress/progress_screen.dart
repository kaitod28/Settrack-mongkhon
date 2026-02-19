import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF061A14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF061A14),
        elevation: 0,
        title: const Text("Progress"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            /// 🔹 Top Stats
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: const [
                StatCard(title: "Total Volume", value: "43,500 kg", sub: "+12%"),
                StatCard(title: "PRs This Month", value: "3", sub: "+1"),
                StatCard(title: "Consistency", value: "86%", sub: "+5%"),
                StatCard(title: "Avg Duration", value: "49 min", sub: "-3 min"),
              ],
            ),

            const SizedBox(height: 24),

            /// 🔹 Line Chart
            Container(
              padding: const EdgeInsets.all(16),
              decoration: boxStyle(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Weekly Volume",
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                  const SizedBox(height: 200, child: WeeklyLineChart()),
                ],
              ),
            ),

            const SizedBox(height: 24),

            /// 🔹 Bar Chart
            Container(
              padding: const EdgeInsets.all(16),
              decoration: boxStyle(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text("Workouts Per Week",
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                  SizedBox(height: 200, child: WeeklyBarChart()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static BoxDecoration boxStyle() {
    return BoxDecoration(
      color: const Color(0xFF0D2A22),
      borderRadius: BorderRadius.circular(18),
    );
  }
}

/// ==================
/// 🔹 Stat Card
/// ==================
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String sub;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: ProgressScreen.boxStyle(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(color: Colors.white54, fontSize: 13)),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(sub,
              style: const TextStyle(
                  color: Colors.greenAccent,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

/// ==================
/// 🔹 Line Chart
/// ==================
class WeeklyLineChart extends StatelessWidget {
  const WeeklyLineChart({super.key});

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: const [
              FlSpot(0, 5),
              FlSpot(1, 4.8),
              FlSpot(2, 5.2),
              FlSpot(3, 2),
              FlSpot(4, 5),
              FlSpot(5, 5.5),
              FlSpot(6, 2),
            ],
            isCurved: true,
            color: Colors.greenAccent,
            barWidth: 3,
            dotData: const FlDotData(show: false),
          )
        ],
      ),
    );
  }
}

/// ==================
/// 🔹 Bar Chart
/// ==================
class WeeklyBarChart extends StatelessWidget {
  const WeeklyBarChart({super.key});

  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: [
          makeGroup(0, 2),
          makeGroup(1, 3),
          makeGroup(2, 1.5),
          makeGroup(3, 3.5),
          makeGroup(4, 4),
          makeGroup(5, 2.5),
        ],
      ),
    );
  }

  BarChartGroupData makeGroup(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: Colors.greenAccent,
          width: 18,
          borderRadius: BorderRadius.circular(6),
        )
      ],
    );
  }
}
