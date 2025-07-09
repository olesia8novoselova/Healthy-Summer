import 'package:flutter/material.dart';

class MainShell extends StatelessWidget {
  final Widget child;
  final int currentIndex;
  final void Function(int) onTabTapped;

  const MainShell({
    required this.child,
    required this.currentIndex,
    required this.onTabTapped,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        selectedItemColor: Colors.pink,
        unselectedItemColor: Colors.grey,
        onTap: onTabTapped,
        items: const [
           BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: 'Trainings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
