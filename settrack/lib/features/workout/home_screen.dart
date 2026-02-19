import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  String _currentDate() {
    return DateFormat('EEEE, MMM d').format(DateTime.now());
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good morning ☀️";
    if (hour < 18) return "Good afternoon 💪";
    return "Good evening 💪";
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF061A14),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection("users")
                .doc(user!.uid)
                .collection("workouts")
                .orderBy("createdAt", descending: true)
                .snapshots(),
            builder: (context, snapshot) {

              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final workouts = snapshot.data!.docs;

              int totalWorkouts = workouts.length;

              int totalWeight = workouts.fold(0, (sum, doc) {
                final data = doc.data() as Map<String, dynamic>;
                return sum + ((data["totalWeight"] ?? 0) as int);
              });

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    const SizedBox(height: 10),

                    Text(
                      _currentDate(),
                      style: const TextStyle(color: Colors.white54),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      _greeting(),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 30),

                    /// 🔥 Real Stats
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _StatCard(
                          title: "$totalWorkouts",
                          subtitle: "Workouts",
                        ),
                        _StatCard(
                          title: "$totalWeight lbs",
                          subtitle: "Total Weight",
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),

                    const Text(
                      "Recent Workouts",
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 20),

                    if (workouts.isEmpty)
                      const Text(
                        "No workouts yet",
                        style: TextStyle(color: Colors.white54),
                      ),

                    ...workouts.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;

                      return _WorkoutCard(
                        title: data["title"] ?? "Workout",
                        subtitle: data["subtitle"] ?? "",
                        weight: "${data["totalWeight"] ?? 0} lbs",
                      );
                    }).toList(),

                    const SizedBox(height: 80),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// ===============================
/// Stat Card
/// ===============================
class _StatCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const _StatCard({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0D2A22),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// ===============================
/// Workout Card
/// ===============================
class _WorkoutCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String weight;

  const _WorkoutCard({
    required this.title,
    required this.subtitle,
    required this.weight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0D2A22),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
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
