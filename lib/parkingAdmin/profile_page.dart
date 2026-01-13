import 'package:flutter/material.dart';
import 'package:smartparking/authentication/login_page.dart';
import 'package:smartparking/user/widgets/bottom_app_bar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ParkingAdminProfile extends StatelessWidget {
  const ParkingAdminProfile({super.key});

  String _getInitial(String? name) {
    if (name == null || name.isEmpty) return '?';
    return name[0].toUpperCase();
  }

  Future<void> _logout(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    final name = user?.userMetadata?['full_name'] ?? 'User';
    final email = user?.email ?? 'No email';
    final role = user?.userMetadata?['role'] ?? 'user';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
      ),
      bottomNavigationBar: UserBottomAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 30),

            // Avatar with first letter
            CircleAvatar(
              radius: 45,
              backgroundColor: Colors.red,
              child: Text(
                _getInitial(name),
                style: const TextStyle(
                  fontSize: 36,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Name
            Text(
              name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 5),

            // Email
            Text(
              email,
              style: const TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 5),

            // Role
            Chip(
              label: Text(
                role.toUpperCase(),
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.blue,
            ),

            const SizedBox(height: 40),

            // Logout button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text("Logout"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                onPressed: () => _logout(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
