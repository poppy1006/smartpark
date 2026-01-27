import 'package:flutter/material.dart';
import 'package:smartparking/authentication/login_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.deepPurple)),
      debugShowCheckedModeBanner: false,
      home: const LoginPage(),
      // home: const MapScreen1()
      // home: const UserDashboardPage(),
      // home: ParkingAdminDashboard(),
      // home: const UserProfilePage()
    );
  }
}
