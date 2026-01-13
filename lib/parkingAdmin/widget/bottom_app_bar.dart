import 'package:flutter/material.dart';
import 'package:smartparking/parkingAdmin/profile_page.dart';

class ParkingAdminAppBar extends StatelessWidget {
  const ParkingAdminAppBar({super.key});

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
            IconButton(
              icon: Icon(Icons.home, color: Colors.black),
              onPressed: () {},
            ),
            FloatingActionButton(onPressed: () {}, child: Icon(Icons.qr_code_scanner)),
            IconButton(
              icon: Icon(Icons.account_circle_outlined, color: Colors.black),
              onPressed: () {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ParkingAdminProfile()));
              },
            ),
          ],
        ),
      ),
    );
  }
}