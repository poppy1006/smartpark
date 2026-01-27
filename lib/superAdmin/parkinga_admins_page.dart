import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'assign_parking_page.dart';

final supabase = Supabase.instance.client;

class ParkingAdminsPage extends StatefulWidget {
  const ParkingAdminsPage({super.key});

  @override
  State<ParkingAdminsPage> createState() => _ParkingAdminsPageState();
}

class _ParkingAdminsPageState extends State<ParkingAdminsPage> {
  List admins = [];

  @override
  void initState() {
    super.initState();
    _loadAdmins();
  }

  Future<void> _loadAdmins() async {
    final res = await supabase
        .from('users')
        .select()
        .eq('role', 'parking_admin');
    setState(() => admins = res);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Parking Admins"),
        backgroundColor: Colors.red,
      ),
      body: ListView.builder(
        itemCount: admins.length,
        itemBuilder: (_, i) {
          final a = admins[i];
          return Card(
            child: ListTile(
              title: Text(a['email']),
              subtitle: Text(a['full_name'] ?? ''),
              trailing: ElevatedButton(
                child: const Text("Assign Parkings"),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AssignParkingPage(adminId: a['id']),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
