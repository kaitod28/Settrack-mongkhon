import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:settrack/features/workout/add_exercise_screen.dart';



class WorkoutScreen extends StatelessWidget {
  const WorkoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF061A14),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              const SizedBox(height: 20),

              const Text(
                "Workout",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 25),

              /// 🔥 Start Workout Button
             GestureDetector(
              onTap: () {
               Navigator.push(
                 context,
                 MaterialPageRoute(
                  builder: (_) => const AddExerciseScreen(),
                  ),
              );
            },
            child: Container(
             width: double.infinity,
             height: 55,
             decoration: BoxDecoration(
               color: Colors.greenAccent,
               borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
             child: Text(
               "▶ Start Workout",
               style: TextStyle(
                 fontWeight: FontWeight.bold,
                 color: Colors.black,
              ),
            ),
          ),
        ),
      ),
              const SizedBox(height: 30),

              const Text(
                "My Routines",
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              /// 🔥 Routine List (Realtime)
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection("users")
                      .doc(user!.uid)
                      .collection("routines")
                      .snapshots(),
                  builder: (context, snapshot) {

                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    final routines = snapshot.data!.docs;

                    if (routines.isEmpty) {
                      return const Text(
                        "No routines yet",
                        style: TextStyle(color: Colors.white54),
                      );
                    }

                    return ListView.builder(
                      itemCount: routines.length,
                      itemBuilder: (context, index) {

                        final data = routines[index].data()
                            as Map<String, dynamic>;

                        return _RoutineCard(
                          title: data["title"] ?? "Routine",
                          exercises: data["exercises"] ?? 0,
                          onTap: () async {

                            /// 🔥 Create workout when routine tapped
                            await FirebaseFirestore.instance
                                .collection("users")
                                .doc(user.uid)
                                .collection("workouts")
                                .add({
                              "title": data["title"],
                              "totalWeight": 0,
                              "createdAt": Timestamp.now(),
                            });
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoutineCard extends StatelessWidget {
  final String title;
  final int exercises;
  final VoidCallback onTap;

  const _RoutineCard({
    required this.title,
    required this.exercises,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF0D2A22),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [

            Column(
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
                  "$exercises exercises",
                  style: const TextStyle(
                    color: Colors.white54,
                  ),
                ),
              ],
            ),

            const Icon(Icons.chevron_right, color: Colors.white54)
          ],
        ),
      ),
    );
  }
}
