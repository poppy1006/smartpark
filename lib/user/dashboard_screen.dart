import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

// Location Lists for map pointing
final List<LatLng> locations = [
  LatLng(10.001366, 76.310081), // palarivattom
  LatLng(10.003261, 76.316005), // Aalinchuvadu
  LatLng(9.990172, 76.315793), // Holiday Inn
];

class UserDashboard extends StatefulWidget {
  const UserDashboard({super.key});

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(

    );
  }
}