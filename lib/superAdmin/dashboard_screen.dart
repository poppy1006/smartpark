import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'users_page.dart';

final supabase = Supabase.instance.client;

class SuperAdminDashboard extends StatefulWidget {
  const SuperAdminDashboard({super.key});

  @override
  State<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> {
  int totalUsers = 0;
  int totalBookings = 0;
  int activeParkings = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final users = await supabase.from('users').select('id').count();
    final bookings = await supabase.from('bookings').select('id').count();
    final parkings = await supabase
        .from('parkings')
        .select('id')
        .eq('is_active', true)
        .count();

    setState(() {
      totalUsers = users.count ?? 0;
      totalBookings = bookings.count ?? 0;
      activeParkings = parkings.count ?? 0;
    });
  }

  Widget statCard(String title, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 40),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(title),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Super Admin Dashboard"),
        backgroundColor: Colors.red,
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(12),
        children: [
          statCard("Users", "$totalUsers", Icons.people),
          statCard("Bookings", "$totalBookings", Icons.receipt),
          statCard("Active Parkings", "$activeParkings", Icons.local_parking),

          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const UsersPage()),
            ),
            child: statCard("Manage Users", "OPEN", Icons.manage_accounts),
          ),
        ],
      ),
    );
  }
}
