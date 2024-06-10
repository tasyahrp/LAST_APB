import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

class CustomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTabChange;

  const CustomNavBar({required this.selectedIndex, required this.onTabChange,super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, -2), // changes position of shadow
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15.0),
        child: GNav(
          backgroundColor: Colors.white,
          color: const Color.fromARGB(255, 72, 70, 70),
          activeColor: const Color(0xFF4A1C6F),
          gap: 8,
          padding: const EdgeInsets.all(18),
          onTabChange: onTabChange,
          selectedIndex: selectedIndex, // Make sure to show the selected tab
          tabs: [
            GButton(
              icon: Icons.home,
              text: 'Home',
              iconSize: 28, // Set icon size
              textStyle: TextStyle(
                fontSize: 16,
                color: selectedIndex == 0 ? const Color(0xFF4A1C6F) : Colors.black,
                fontWeight: selectedIndex == 0 ? FontWeight.bold : FontWeight.normal, // Bold and purple when active
              ),
            ),
            GButton(
              icon: Icons.library_books,
              text: 'Courses',
              iconSize: 28, // Set icon size
              textStyle: TextStyle(
                fontSize: 16,
                color: selectedIndex == 1 ? const Color(0xFF4A1C6F) : Colors.black,
                fontWeight: selectedIndex == 1 ? FontWeight.bold : FontWeight.normal, // Bold and purple when active
              ),
            ),
            GButton(
              icon: Icons.person,
              text: 'Profile',
              iconSize: 28, // Set icon size
              textStyle: TextStyle(
                fontSize: 16,
                color: selectedIndex == 2 ? const Color(0xFF4A1C6F) : Colors.black,
                fontWeight: selectedIndex == 2 ? FontWeight.bold : FontWeight.normal, // Bold and purple when active
              ),
            ),
          ],
        ),
      ),
    );
  }
}
