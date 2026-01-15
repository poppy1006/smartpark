import 'package:flutter/material.dart';
import 'package:smartparking/parkingAdmin/dashboard_screen.dart';
import 'package:smartparking/parkingAdmin/parking_form_page.dart';
import 'package:smartparking/parkingAdmin/profile_page.dart';
import 'package:smartparking/parkingAdmin/parking_form_page.dart';


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
            // home button
            IconButton(
              icon: Icon(Icons.home, color: Colors.black),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ParkingAdminDashboard(),
                  ),
                );
              },
            ),
            //+ button for adding a parking !
            FloatingActionButton(
              onPressed: () {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ParkingFormPage()));
              },
              child: Icon(Icons.add),
            ),
            IconButton(
              //Profile
              icon: Icon(Icons.account_circle_outlined, color: Colors.black),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ParkingAdminProfile(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
