import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../login/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final user = FirebaseAuth.instance.currentUser;
  final nameController = TextEditingController();

  String? photoUrl;
  int totalWorkouts = 0;
  int totalVolume = 0;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  // ================= LOAD DATA =================
  Future<void> loadUserData() async {
    if (user == null) return;

    // ⭐ โหลด profile จาก Firestore (ตัวจริง)
    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user!.uid)
        .get();

    final data = doc.data();

    nameController.text =
        data?["name"] ?? user!.email?.split("@").first ?? "User";

    photoUrl = data?["photoUrl"];

    // 🔥 โหลด workout stats
    final workoutSnap = await FirebaseFirestore.instance
        .collection("users")
        .doc(user!.uid)
        .collection("workouts")
        .get();

    int volume = 0;

    for (var doc in workoutSnap.docs) {
      volume += (doc.data()["totalVolume"] ?? 0) as int;
    }

    setState(() {
      totalWorkouts = workoutSnap.docs.length;
      totalVolume = volume;
    });
  }

  // ================= EDIT POPUP =================
  void showEditProfilePopup() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0D2A22),
        title: const Text(
          "Edit Profile",
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Name",
                labelStyle: TextStyle(color: Colors.white54),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(onPressed: saveProfile, child: const Text("Save")),
        ],
      ),
    );
  }

  // ================= SAVE PROFILE =================
  Future<void> saveProfile() async {
    if (user == null) return;

    await user!.updateDisplayName(nameController.text.trim());

    await FirebaseFirestore.instance.collection("users").doc(user!.uid).set({
      "name": nameController.text.trim(),
    }, SetOptions(merge: true));

    if (mounted) Navigator.pop(context);
    setState(() {});
  }

  // ================= LOGOUT =================
  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    final displayName = nameController.text.isEmpty
        ? "User"
        : nameController.text;

    final initials = displayName.isNotEmpty
        ? displayName[0].toUpperCase()
        : "U";

    return Scaffold(
      backgroundColor: const Color(0xFF061A14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF061A14),
        elevation: 0,

        // ⭐ บังคับสีไอคอนทั้งหมด
        iconTheme: const IconThemeData(color: Colors.white),

        // ⭐ บังคับสี title (สำคัญมาก)
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),

        title: const Text("Profile"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 🔥 Avatar (กดได้)
            // 🔥 Avatar (กดได้)
            GestureDetector(
              onTap: showEditProfilePopup,
              child: CircleAvatar(
                radius: 45,
                backgroundColor: const Color(0xFF0D2A22),
                child: ClipOval(
                  child: (photoUrl != null && photoUrl!.isNotEmpty)
                      ? Image.network(
                          photoUrl!,
                          width: 90,
                          height: 90,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) {
                            return Center(
                              child: Text(
                                initials,
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.greenAccent,
                                ),
                              ),
                            );
                          },
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            );
                          },
                        )
                      : Center(
                          child: Text(
                            initials,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.greenAccent,
                            ),
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            Text(
              displayName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              "Tap avatar to edit",
              style: TextStyle(color: Colors.white54),
            ),

            const SizedBox(height: 24),

            // 🔥 Stats
            Row(
              children: [
                Expanded(
                  child: _StatCard(title: "Workouts", value: "$totalWorkouts"),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(title: "Volume", value: "$totalVolume kg"),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 🔥 Achievements ONLY
            _menuItem(
              Icons.emoji_events,
              "Achievements",
              subtitle: "$totalWorkouts workouts completed",
            ),

            const SizedBox(height: 30),

            // 🔥 Logout
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: logout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  "Log out",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= MENU =================
  Widget _menuItem(IconData icon, String title, {String? subtitle}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D2A22),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.greenAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white)),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.white54),
        ],
      ),
    );
  }
}

// ================= STAT CARD =================
class _StatCard extends StatelessWidget {
  final String title;
  final String value;

  const _StatCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: const Color(0xFF0D2A22),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 18,
              ),
            ),
            Text(title, style: const TextStyle(color: Colors.white54)),
          ],
        ),
      ),
    );
  }
}
