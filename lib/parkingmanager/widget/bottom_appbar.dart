import 'package:flutter/material.dart';
import 'package:smartparking/parkingmanager/dashboard_screen.dart';
import 'package:smartparking/parkingmanager/profile_page.dart';

class ParkingManagerAppBar extends StatelessWidget {
  const ParkingManagerAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: CircularNotchedRectangle(),
      notchMargin: 5,
      child: SizedBox(
        height: kBottomNavigationBarHeight,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // home button
            IconButton(
              icon: Icon(Icons.home, color: Colors.black),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ParkingManagerDashboard(),
                  ),
                );
              },
            ),
            IconButton(
              //Profile
              icon: Icon(Icons.account_circle_outlined, color: Colors.black),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const ManagerProfilePage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
