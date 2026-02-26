import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_exercise_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../navigation/main_navigation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:io';

class WorkoutExercise {
  String name;
  String imageUrl;
  List<WorkoutSet> sets;

  WorkoutExercise({required this.name, required this.imageUrl})
    : sets = [WorkoutSet(index: 1)];
}

class WorkoutSet {
  int index;
  int weight;
  int reps;
  bool isDone;

  WorkoutSet({
    required this.index,
    this.weight = 0,
    this.reps = 0,
    this.isDone = false,
  });
}

class LogWorkoutScreen extends StatefulWidget {
  final List<Map<String, dynamic>> selectedExercises;

  const LogWorkoutScreen({super.key, required this.selectedExercises});

  @override
  State<LogWorkoutScreen> createState() => _LogWorkoutScreenState();
}

class _LogWorkoutScreenState extends State<LogWorkoutScreen> {
  late List<WorkoutExercise> workoutList;

  @override
  void initState() {
    super.initState();

    workoutList = widget.selectedExercises.map((e) {
      return WorkoutExercise(name: e["name"], imageUrl: e["imageUrl"] ?? "");
    }).toList();
  }

  bool _validateWorkout() {
    for (var exercise in workoutList) {
      for (var set in exercise.sets) {
        if (!set.isDone) {
          _showError("Please complete all sets");
          return false;
        }

        if (set.weight <= 0) {
          _showError("Weight must be greater than 0");
          return false;
        }

        if (set.reps <= 0) {
          _showError("Reps must be greater than 0");
          return false;
        }
      }
    }
    return true;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // ================= Internet=================

Future<bool> hasInternet() async {
  try {
    final result = await InternetAddress.lookup('google.com');
    return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
  } catch (_) {
    return false;
  }
}

  // ================= ADD EXERCISE (FIXED) =================
  Future<void> openAddExercise() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddExerciseScreen()),
    );

    if (result == null) return;

    final List<Map<String, dynamic>> newExercises =
        List<Map<String, dynamic>>.from(result);

    setState(() {
      for (var data in newExercises) {
        final exists = workoutList.any((e) => e.name == data["name"]);

        if (!exists) {
          workoutList.add(
            WorkoutExercise(
              name: data["name"],
              imageUrl: data["imageUrl"] ?? "",
            ),
          );
        }
      }
    });
  }

  // ================= SAVE =================
  Future<void> saveWorkout() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    print("🔥 SAVING TO FIRESTORE UID: ${user.uid}");

    // 1️⃣ สร้าง workout หลัก
    final workoutRef = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .collection("workouts")
        .add({
          "createdAt": Timestamp.now(),
          "totalVolume": calculateTotalVolume(),
          "exerciseCount": workoutList.length,
        });

    // 2️⃣ บันทึกแต่ละท่า
    for (var exercise in workoutList) {
      await workoutRef.collection("exercises").add({
        "name": exercise.name,
        "imageUrl": exercise.imageUrl,
        "sets": exercise.sets.map((set) {
          return {"weight": set.weight, "reps": set.reps};
        }).toList(),
      });
    }

    print("✅ WORKOUT SAVED SUCCESS");
  }

  // ================= CALC =================
  int calculateTotalVolume() {
    int total = 0;
    for (var exercise in workoutList) {
      for (var set in exercise.sets) {
        total += set.weight * set.reps;
      }
    }
    return total;
  }

  void finishWorkout() async {
    if (!_validateWorkout()) return;

    final isOnline = await hasInternet();

    // 🔴 ถ้าไม่มีเน็ต → แจ้งเตือนก่อน
    if (!isOnline && mounted) {
      await showDialog(
        // ✅ ต้อง await
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF0D2A22),
          title: const Text(
            "No Internet",
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            "Workout will be saved offline and synced when internet is back.",
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    // ✅ ค่อยบันทึก
    await saveWorkout();

    if (!mounted) return;

    Navigator.pop(context);
    mainNavKey.currentState?.switchToTab(2);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF061A14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF061A14),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("Log Workout", style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: finishWorkout,
            child: const Text(
              "Finish",
              style: TextStyle(color: Colors.greenAccent),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: workoutList.length,
              itemBuilder: (context, index) {
                return buildExerciseCard(workoutList[index]);
              },
            ),
          ),

          /// ✅ ปุ่ม Add Exercise
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 52),
                ),
                onPressed: openAddExercise,
                icon: const Icon(Icons.add),
                label: const Text("Add Exercise"),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= EXERCISE CARD =================
  Widget buildExerciseCard(WorkoutExercise exercise) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D2A22),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: Image.network(
                  exercise.imageUrl,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.fitness_center, color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  exercise.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.redAccent),
                onPressed: () {
                  setState(() {
                    workoutList.remove(exercise);
                  });
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          ...exercise.sets.map((set) => buildSetRow(exercise, set)).toList(),

          const SizedBox(height: 12),

          GestureDetector(
            onTap: () {
              setState(() {
                exercise.sets.add(WorkoutSet(index: exercise.sets.length + 1));
              });
            },
            child: const Text(
              "+ Add Set",
              style: TextStyle(
                color: Colors.greenAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= SET ROW =================
  Widget buildSetRow(WorkoutExercise exercise, WorkoutSet set) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF12352B),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              "${set.index}",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: TextField(
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[1-9][0-9]*')),
              ],
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "KG", // หรือ REPS
                hintStyle: TextStyle(color: Colors.white38),
                border: InputBorder.none,
              ),
              onChanged: (val) {
                setState(() {
                  set.weight =
                      int.tryParse(val) ?? 0; // reps ก็เปลี่ยนเป็น set.reps
                });
              },
            ),
          ),
          Expanded(
            child: TextField(
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[1-9][0-9]*')),
              ],
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "REPS",
                hintStyle: TextStyle(color: Colors.white38),
                border: InputBorder.none,
              ),
              onChanged: (val) {
                setState(() {
                  set.reps = int.tryParse(val) ?? 0;
                });
              },
            ),
          ),
          Checkbox(
            value: set.isDone,
            activeColor: Colors.greenAccent,
            onChanged: (val) {
              setState(() {
                set.isDone = val ?? false;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.redAccent, size: 18),
            onPressed: () {
              setState(() {
                exercise.sets.remove(set);
                for (int i = 0; i < exercise.sets.length; i++) {
                  exercise.sets[i].index = i + 1;
                }
              });
            },
          ),
        ],
      ),
    );
  }
}
