import 'package:flutter/material.dart';
import 'package:smartparking/authentication/login_page.dart';
import 'package:smartparking/parkingAdmin/dashboard_screen.dart';
import 'package:smartparking/screens/map_page1.dart';
// import 'package:firebase_core/firebase_core.dart';
import 'package:smartparking/screens/map_page1.dart';
import 'package:smartparking/user/dashboard_screen.dart';
import 'package:smartparking/user/profile_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// import 'firebase_options.dart';

Future<void> main() async {
  await Supabase.initialize(
    url: 'https://ijlaelsdmsddkinfcgrw.supabase.co',
    anonKey: 'sb_publishable_Am1gvkrDtMIgxjYICHM0kA_z_AxmgiD',
    );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: .fromSeed(seedColor: Colors.deepPurple),
      ),
      debugShowCheckedModeBanner: false,
      // home: const LoginPage(),
      // home: const MapScreen1() 
      // home: const UserDashboardPage(),
      // home: ParkingAdminDashboard(),
      home: const UserProfilePage()
    );
  }
}

