import 'package:flutter/material.dart';
import 'package:smartparking/parkingAdmin/widget/bottom_app_bar.dart';

class ParkingAdminDashboard extends StatefulWidget {
  const ParkingAdminDashboard({super.key});

  @override
  State<ParkingAdminDashboard> createState() => _ParkingAdminDashboardState();
}

class _ParkingAdminDashboardState extends State<ParkingAdminDashboard> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome ! Parking Admin'),
      ),
      bottomNavigationBar: ParkingAdminAppBar(),
      body: const Center(
        child:SingleChildScrollView(
          child: Text('Parking Admin Dashboard Screen'),
        ),
      ),
    );
  }
}