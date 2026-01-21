import 'package:flutter/material.dart';
import 'package:smartparking/user/widgets/bottom_app_bar.dart';

class MyBookingsPage extends StatelessWidget {
  const MyBookingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      bottomNavigationBar: UserBottomAppBar(),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [Text("My Bookings Page")],
        ),
      ),
    );
  }
}
