import 'package:flutter/material.dart';
import 'package:smartparking/user/dashboard_screen.dart';
import 'package:smartparking/user/my_bookings_page.dart';
import 'package:smartparking/user/nearby_parking_page.dart';
import 'package:smartparking/user/profile_page.dart';

class UserBottomAppBar extends StatelessWidget {
  const UserBottomAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 5,
      child: SizedBox(
        height: kBottomNavigationBarHeight,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // User dash nav
            IconButton(
              icon: const Icon(Icons.home),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const UserDashboardPage()),
                );
              },
            ),
            // Serch nav
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => NearbyParkingsPage()),
                );
              },
            ),
            // My Bookings
            IconButton(
              icon: const Icon(Icons.card_travel),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const MyBookingsPage()),
                );
              },
            ),
            // Profile nav
            IconButton(
              icon: const Icon(Icons.account_circle_outlined),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const UserProfilePage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
