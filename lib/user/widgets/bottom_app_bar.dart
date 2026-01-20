// import 'package:flutter/material.dart';

// class AppBottomBar extends StatelessWidget {
//   final int currentIndex;
//   final Function(int) onTap;

//   const AppBottomBar({
//     super.key,
//     required this.currentIndex,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return BottomAppBar(
//       shape: const CircularNotchedRectangle(),
//       notchMargin: 5.0,
//       clipBehavior: Clip.antiAlias,
//       child: SizedBox(
//         height: kBottomNavigationBarHeight,
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceAround,
//           children: [
//             _buildIcon(Icons.home, 0),
//             _buildIcon(Icons.search, 1),
//             _buildIcon(Icons.account_circle_outlined, 2),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildIcon(IconData icon, int index) {
//     return IconButton(
//       icon: Icon(
//         icon,
//         color: currentIndex == index ? Colors.blue : Colors.grey,
//       ),
//       onPressed: () => onTap(index),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:smartparking/user/dashboard_screen.dart';
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
                Navigator.pushReplacement(context, 
                MaterialPageRoute(builder: (_) => const UserDashboardPage()));
              },
            ),
            // Serch nav
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                Navigator.pushReplacement(context, 
                MaterialPageRoute(builder: (_) => NearbyParkingsPage())
                );
              },
            ),
            // Profile nav
            IconButton(
              icon: const Icon(Icons.account_circle_outlined),
              onPressed: () {
                Navigator.pushReplacement(context, 
                MaterialPageRoute(builder: (_) => const UserProfilePage())
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
