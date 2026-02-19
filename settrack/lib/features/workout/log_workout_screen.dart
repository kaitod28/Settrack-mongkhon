import 'package:flutter/material.dart';

class WorkoutExercise {
  String name;
  List<WorkoutSet> sets;

  WorkoutExercise({required this.name})
      : sets = [WorkoutSet()];
}

class WorkoutSet {
  int weight;
  int reps;
  bool isDone;

  WorkoutSet({this.weight = 0, this.reps = 0, this.isDone = false});
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

    workoutList = widget.selectedExercises
        .map((e) => WorkoutExercise(name: e["name"]))
        .toList();
  }

  void finishWorkout() {
    Navigator.pushReplacementNamed(context, "/progress");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF061A14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF061A14),
        title: const Text("Log Workout"),
        actions: [
          TextButton(
            onPressed: finishWorkout,
            child: const Text(
              "Finish",
              style: TextStyle(color: Colors.greenAccent),
            ),
          )
        ],
      ),
      body: ListView.builder(
        itemCount: workoutList.length,
        itemBuilder: (context, index) {

          final exercise = workoutList[index];

          return Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0D2A22),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                /// 🔹 Exercise Name
                Text(
                  exercise.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                /// 🔹 Sets
                Column(
                  children: List.generate(exercise.sets.length, (setIndex) {

                    final set = exercise.sets[setIndex];

                    return Row(
                      children: [

                        Text(
                          "${setIndex + 1}",
                          style: const TextStyle(color: Colors.white),
                        ),

                        const SizedBox(width: 10),

                        /// Weight
                        Expanded(
                          child: TextFormField(
                            initialValue: set.weight.toString(),
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              hintText: "kg",
                              hintStyle: TextStyle(color: Colors.white38),
                            ),
                            onChanged: (val) {
                              set.weight = int.tryParse(val) ?? 0;
                            },
                          ),
                        ),

                        const SizedBox(width: 10),

                        /// Reps
                        Expanded(
                          child: TextFormField(
                            initialValue: set.reps.toString(),
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              hintText: "reps",
                              hintStyle: TextStyle(color: Colors.white38),
                            ),
                            onChanged: (val) {
                              set.reps = int.tryParse(val) ?? 0;
                            },
                          ),
                        ),

                        IconButton(
                          icon: Icon(
                            set.isDone
                                ? Icons.check_circle
                                : Icons.circle_outlined,
                            color: set.isDone
                                ? Colors.greenAccent
                                : Colors.white38,
                          ),
                          onPressed: () {
                            setState(() {
                              set.isDone = !set.isDone;
                            });
                          },
                        )
                      ],
                    );
                  }),
                ),

                const SizedBox(height: 10),

                /// 🔹 Add Set Button
                TextButton(
                  onPressed: () {
                    setState(() {
                      exercise.sets.add(WorkoutSet());
                    });
                  },
                  child: const Text(
                    "+ Add Set",
                    style: TextStyle(color: Colors.greenAccent),
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
