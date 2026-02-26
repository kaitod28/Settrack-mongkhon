import 'package:flutter/material.dart';
import '../workout/home_screen.dart';
import '../workout/workout_screen.dart';
import '../workout/profile_screen.dart';
import '../progress/progress_screen.dart';

/// 🔥 GLOBAL KEY (ต้องมีอันเดียวทั้งแอพ)
final GlobalKey<_MainNavigationState> mainNavKey =
    GlobalKey<_MainNavigationState>();

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  /// 🔥 ให้หน้าอื่นสั่งเปลี่ยน tab
  void switchToTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  final List<Widget> _pages = const [
    HomeScreen(),
    WorkoutScreen(),
    ProgressScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF061A14),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF0D2A22),
        selectedItemColor: Colors.greenAccent,
        unselectedItemColor: Colors.white54,
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        onTap: switchToTab,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: "Workout",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart),
            label: "Progress",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}