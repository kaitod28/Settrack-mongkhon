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

    if (user == null) {
      return const Scaffold(body: Center(child: Text("Not logged in")));
    }

    return Scaffold(
      backgroundColor: const Color(0xFF061A14),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),

          // 🔥 โหลดข้อมูล user ก่อน (เอาชื่อ + รูป)
          child: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection("users")
                .doc(user.uid)
                .snapshots(),
            builder: (context, userSnap) {
              if (!userSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final userData = userSnap.data!.data() as Map<String, dynamic>?;

              final userName =
                  userData?["name"] ?? user.email!.split("@").first;

              final photoUrl = userData?["photoUrl"];

              // 🔥 โหลด workouts ต่อ
              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("users")
                    .doc(user.uid)
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
                    return sum + ((data["totalVolume"] ?? 0) as int);
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

                        /// 🔥 Stats
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _StatCard(
                              title: "$totalWorkouts",
                              subtitle: "Workouts",
                            ),
                            _StatCard(
                              title: "$totalWeight kg",
                              subtitle: "Total Volume",
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

                          final Timestamp? ts = data["createdAt"];
                          final date = ts != null
                              ? DateFormat("MMM d").format(ts.toDate())
                              : "";

                          return StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection("users")
                                .doc(user.uid)
                                .collection("workouts")
                                .doc(doc.id)
                                .collection("exercises")
                                .snapshots(),
                            builder: (context, exSnapshot) {
                              if (exSnapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const SizedBox();
                              }

                              if (!exSnapshot.hasData) {
                                return const SizedBox();
                              }

                              return _WorkoutCard(
                                workoutId: doc.id,
                                title: data["title"] ?? "Workout",
                                date: date,
                                volume: (data["totalVolume"] ?? 0) as int,
                                userName: userName,
                                photoUrl: photoUrl,
                                exercises: exSnapshot.data!.docs,
                              );
                            },
                          );
                        }).toList(),

                        const SizedBox(height: 80),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

//////////////////////////////////////////////////
/// 🔹 STAT CARD
//////////////////////////////////////////////////
class _StatCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const _StatCard({required this.title, required this.subtitle});

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
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(color: Colors.white54)),
        ],
      ),
    );
  }
}

//////////////////////////////////////////////////
/// 🔹 WORKOUT CARD
//////////////////////////////////////////////////
class _WorkoutCard extends StatelessWidget {
  final String workoutId;
  final String title;
  final String date;
  final int volume;
  final String userName;
  final String? photoUrl;
  final List<QueryDocumentSnapshot> exercises;

  const _WorkoutCard({
    required this.workoutId,
    required this.title,
    required this.date,
    required this.volume,
    required this.userName,
    required this.photoUrl,
    required this.exercises,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D2A22),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 👤 HEADER พร้อมรูปโปรไฟล์จริง
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: Colors.green,
                backgroundImage: photoUrl != null
                    ? NetworkImage(photoUrl!)
                    : null,
                child: photoUrl == null
                    ? Text(userName[0].toUpperCase())
                    : null,
              ),
              const SizedBox(width: 10),
              Text(userName, style: const TextStyle(color: Colors.white)),
              const Spacer(),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz, color: Colors.white54),
                onSelected: (value) async {
                  if (value != 'delete') return;

                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      backgroundColor: const Color(0xFF0D2A22),
                      title: const Text(
                        "Delete workout?",
                        style: TextStyle(color: Colors.white),
                      ),
                      content: const Text(
                        "This action cannot be undone.",
                        style: TextStyle(color: Colors.white70),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                          ),
                          child: const Text("Cancel"),
                        ),

                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text("Delete"),
                        ),
                      ],
                    ),
                  );

                  if (confirm != true) return;

                  final user = FirebaseAuth.instance.currentUser;
                  if (user == null) return;

                  try {
                    // 🔥 ลบ exercises ก่อน
                    final exSnap = await FirebaseFirestore.instance
                        .collection("users")
                        .doc(user.uid)
                        .collection("workouts")
                        .doc(workoutId)
                        .collection("exercises")
                        .get();

                    for (var doc in exSnap.docs) {
                      await doc.reference.delete();
                    }

                    // 🔥 ลบ workout
                    await FirebaseFirestore.instance
                        .collection("users")
                        .doc(user.uid)
                        .collection("workouts")
                        .doc(workoutId)
                        .delete();

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Workout deleted ✅")),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Delete failed: $e")),
                    );
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'delete', child: Text("Delete")),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            "$date   $volume kg   ${exercises.length} exercises",
            style: const TextStyle(color: Colors.white54),
          ),

          const SizedBox(height: 12),

          // 🔥 รายการท่าออกกำลังกาย (มีรูป)
          Column(
            children: [
              ...exercises.take(3).map((exDoc) {
                final ex = exDoc.data() as Map<String, dynamic>;
                final List sets = (ex["sets"] as List?) ?? [];
                final String? imageUrl = ex["imageUrl"];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.green.withOpacity(0.2),
                        backgroundImage: imageUrl != null
                            ? NetworkImage(imageUrl)
                            : null,
                        child: imageUrl == null
                            ? const Icon(
                                Icons.fitness_center,
                                color: Colors.green,
                              )
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "${sets.length} sets ${ex["name"] ?? ""}",
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                );
              }),

              if (exercises.length > 3)
                Text(
                  "See ${exercises.length - 3} more exercises",
                  style: const TextStyle(color: Colors.white54),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
