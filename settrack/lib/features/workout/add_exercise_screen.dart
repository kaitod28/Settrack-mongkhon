import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'log_workout_screen.dart';

class AddExerciseScreen extends StatefulWidget {
  const AddExerciseScreen({super.key});

  @override
  State<AddExerciseScreen> createState() => _AddExerciseScreenState();
}

class _AddExerciseScreenState extends State<AddExerciseScreen> {
  String selectedMuscle = "All";
  String searchText = "";
  List<Map<String, dynamic>> selectedExercises = [];

  final List<String> muscleFilters = [
    "All",
    "Chest",
    "Back",
    "Legs",
    "Shoulders",
    "Arms",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF061A14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF061A14),
        elevation: 0,
        title: const Text("Add Exercise"),
      ),
      body: Column(
        children: [

          /// 🔍 Search
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              onChanged: (val) {
                setState(() {
                  searchText = val.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: "Search exercise",
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: const Color(0xFF0D2A22),
                prefixIcon:
                    const Icon(Icons.search, color: Colors.white54),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          /// 🟢 Muscle Filter
          SizedBox(
            height: 45,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: muscleFilters.length,
              itemBuilder: (context, index) {
                final muscle = muscleFilters[index];
                final isSelected = selectedMuscle == muscle;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedMuscle = muscle;
                    });
                  },
                  child: Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 18),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.greenAccent
                          : const Color(0xFF0D2A22),
                      borderRadius:
                          BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        muscle,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.black
                              : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 20),

          /// 📋 Exercise List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("exercises")
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                      child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                final filtered = docs.where((doc) {
                  final data =
                      doc.data() as Map<String, dynamic>;

                  final name =
                      (data["name"] ?? "")
                          .toString()
                          .toLowerCase();

                  final muscle =
                      data["primaryMuscle"] ?? "";

                  final matchSearch =
                      name.contains(searchText);

                  final matchMuscle =
                      selectedMuscle == "All" ||
                          muscle.contains(selectedMuscle);

                  return matchSearch && matchMuscle;
                }).toList();

                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final data =
                        filtered[index].data()
                            as Map<String, dynamic>;
                    final id = filtered[index].id;

                    final isSelected =
                        selectedExercises.any(
                            (element) =>
                                element["id"] == id);

                    return ListTile(
                      leading: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(30),
                        child: Image.network(
                          data["imageUrl"] ?? "",
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (context, error,
                                  stackTrace) {
                            return Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: Colors.grey[800],
                                borderRadius:
                                    BorderRadius.circular(
                                        30),
                              ),
                              child: const Icon(
                                  Icons.fitness_center,
                                  color: Colors.white),
                            );
                          },
                        ),
                      ),
                      title: Text(
                        data["name"] ?? "",
                        style: const TextStyle(
                            color: Colors.white),
                      ),
                      subtitle: Text(
                        data["primaryMuscle"] ?? "",
                        style: const TextStyle(
                            color: Colors.white54),
                      ),
                      trailing: isSelected
                          ? const Icon(
                              Icons.check_circle,
                              color:
                                  Colors.greenAccent)
                          : const Icon(
                              Icons.circle_outlined,
                              color:
                                  Colors.white38),
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            selectedExercises.removeWhere(
                                (element) =>
                                    element["id"] ==
                                    id);
                          } else {
                            selectedExercises.add({
                              "id": id,
                              ...data,
                            });
                          }
                        });
                      },
                    );
                  },
                );
              },
            ),
          ),

          /// 🔥 Bottom Button
          if (selectedExercises.isNotEmpty)
            Container(
              padding:
                  const EdgeInsets.all(16),
              width: double.infinity,
              child: ElevatedButton(
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      Colors.greenAccent,
                  padding:
                      const EdgeInsets.symmetric(
                          vertical: 16),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          LogWorkoutScreen(
                        selectedExercises:
                            selectedExercises,
                      ),
                    ),
                  );
                },
                child: Text(
                  "Add ${selectedExercises.length} exercises",
                  style: const TextStyle(
                      color: Colors.black,
                      fontWeight:
                          FontWeight.bold),
                ),
              ),
            )
        ],
      ),
    );
  }
}
