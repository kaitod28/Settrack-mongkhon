import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  /// 🔥 คำนวณ PR ต่อท่า (MAX WEIGHT)
  Future<Map<String, int>> _calculatePRs(String uid) async {
    final workoutsSnap = await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("workouts")
        .get();

    Map<String, int> prMap = {};

    for (var workout in workoutsSnap.docs) {
      final exSnap = await workout.reference.collection("exercises").get();

      for (var exDoc in exSnap.docs) {
        final data = exDoc.data();
        final String name = data["name"] ?? "Workout";
        final List sets = data["sets"] ?? [];

        int maxWeight = 0;

        for (var s in sets) {
          final w = (s["weight"] ?? 0) as int;
          if (w > maxWeight) maxWeight = w;
        }

        if (maxWeight == 0) continue;

        if (!prMap.containsKey(name) || maxWeight > prMap[name]!) {
          prMap[name] = maxWeight;
        }
      }
    }

    return prMap;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Not logged in")),
      );
    }

    final workoutsStream = FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .collection("workouts")
        .orderBy("createdAt", descending: true)
        .snapshots();

    return Scaffold(
      backgroundColor: const Color(0xFF061A14),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: workoutsStream,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final workouts = snapshot.data!.docs;
            final now = DateTime.now();
            final weekAgo = now.subtract(const Duration(days: 7));
            final monthStart = DateTime(now.year, now.month, 1);

            /// 🔥 TOTAL VOLUME
            int totalVolume = workouts.fold(0, (sum, doc) {
              final data = doc.data() as Map<String, dynamic>;
              return sum + ((data["totalVolume"] ?? 0) as int);
            });

            /// 🔥 WORKOUTS PER WEEK
            int workoutsPerWeek = workouts.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final Timestamp? ts = data["createdAt"];
              if (ts == null) return false;
              return ts.toDate().isAfter(weekAgo);
            }).length;

            /// 🔥 PR THIS MONTH (จำนวน workout เดือนนี้)
            int prThisMonth = workouts.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final Timestamp? ts = data["createdAt"];
              if (ts == null) return false;
              return ts.toDate().isAfter(monthStart);
            }).length;

            /// 🔥 WEEKLY MAP
            Map<int, int> weeklyMap = {
              1: 0,
              2: 0,
              3: 0,
              4: 0,
              5: 0,
              6: 0,
              7: 0,
            };

            for (var doc in workouts) {
              final data = doc.data() as Map<String, dynamic>;
              final Timestamp? ts = data["createdAt"];
              if (ts == null) continue;

              final date = ts.toDate();
              if (date.isBefore(weekAgo)) continue;

              final weekday = date.weekday;
              final vol = (data["totalVolume"] ?? 0) as int;

              weeklyMap[weekday] = weeklyMap[weekday]! + vol;
            }

            /// 🔥 CONSISTENCY
            int activeDays = weeklyMap.values.where((v) => v > 0).length;
            int consistency = ((activeDays / 7) * 100).round();

            // ================= UI =================
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Progress",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),

                  /// 🔥 GRID
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.3,
                    children: [
                      _StatBox("Total Volume", "$totalVolume kg"),
                      _StatBox("PRs This Month", "$prThisMonth"),
                      _StatBox("Consistency", "$consistency%"),
                      _StatBox("Workouts / Week", "$workoutsPerWeek"),
                    ],
                  ),

                  const SizedBox(height: 28),

                  /// 📈 CHART
                  _WeeklyChart(weeklyMap),

                  const SizedBox(height: 28),

                  /// 🏆 PERSONAL RECORDS
                  const Text(
                    "Personal Records 🏆",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  FutureBuilder<Map<String, int>>(
                    future: _calculatePRs(user.uid),
                    builder: (context, prSnap) {
                      if (!prSnap.hasData) {
                        return const SizedBox();
                      }

                      final prList = prSnap.data!.entries.toList()
                        ..sort((a, b) => b.value.compareTo(a.value));

                      final topPRs = prList.take(5);

                      return Column(
                        children: topPRs.map((e) {
                          return _PRCard(
                            name: e.key,
                            weight: "${e.value} kg",
                          );
                        }).toList(),
                      );
                    },
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

//////////////////////////////////////////////////
/// 🔹 STAT BOX
//////////////////////////////////////////////////
class _StatBox extends StatelessWidget {
  final String title;
  final String value;

  const _StatBox(this.title, this.value);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D2A22),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white54)),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

//////////////////////////////////////////////////
/// 🔹 WEEKLY CHART
//////////////////////////////////////////////////
class _WeeklyChart extends StatelessWidget {
  final Map<int, int> weeklyMap;

  const _WeeklyChart(this.weeklyMap);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D2A22),
        borderRadius: BorderRadius.circular(20),
      ),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              isCurved: true,
              color: Colors.greenAccent,
              barWidth: 3,
              spots: [
                for (int i = 1; i <= 7; i++)
                  FlSpot(i.toDouble(), weeklyMap[i]!.toDouble()),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

//////////////////////////////////////////////////
/// 🔹 PR CARD
//////////////////////////////////////////////////
class _PRCard extends StatelessWidget {
  final String name;
  final String weight;

  const _PRCard({
    required this.name,
    required this.weight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D2A22),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Text(name, style: const TextStyle(color: Colors.white)),
          const Spacer(),
          Text(
            weight,
            style: const TextStyle(
              color: Colors.greenAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}