import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WorkoutSessionScreen extends StatefulWidget {
  final List<String> selectedExerciseIds;

  const WorkoutSessionScreen({super.key, required this.selectedExerciseIds});

  @override
  State<WorkoutSessionScreen> createState() => _WorkoutSessionScreenState();
}

class _WorkoutSessionScreenState extends State<WorkoutSessionScreen> {
  Map<String, List<Map<String, dynamic>>> workoutData = {};

  @override
  void initState() {
    super.initState();

    for (var id in widget.selectedExerciseIds) {
      workoutData[id] = [
        {"weight": 0, "reps": 8},
      ];
    }
  }

  void addSet(String id) {
    setState(() {
      workoutData[id]!.add({"weight": 0, "reps": 8});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF061A14),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Log Workout"),
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection("exercises")
            .where(FieldPath.documentId, whereIn: widget.selectedExerciseIds)
            .get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final exercises = snapshot.data!.docs;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: exercises.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final id = doc.id;

              return Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D2A22),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data["name"],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    ...workoutData[id]!.asMap().entries.map((entry) {
                      int index = entry.key;
                      var set = entry.value;

                      return Row(
                        children: [
                          Text(
                            "${index + 1}",
                            style: const TextStyle(color: Colors.white),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: TextFormField(
                              initialValue: set["weight"].toString(),
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                labelText: "KG",
                                labelStyle: TextStyle(color: Colors.white54),
                              ),
                              onChanged: (val) {
                                set["weight"] = int.tryParse(val) ?? 0;
                              },
                            ),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: TextFormField(
                              initialValue: set["reps"].toString(),
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                labelText: "Reps",
                                labelStyle: TextStyle(color: Colors.white54),
                              ),
                              onChanged: (val) {
                                set["reps"] = int.tryParse(val) ?? 0;
                              },
                            ),
                          ),
                        ],
                      );
                    }),

                    const SizedBox(height: 10),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.greenAccent,
                      ),
                      onPressed: () => addSet(id),
                      child: const Text(
                        "Add Set",
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
