import 'package:flutter/material.dart';
import 'package:smartparking/parkingAdmin/widget/bottom_app_bar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class ManageParkingManagersPage extends StatefulWidget {
  const ManageParkingManagersPage({super.key});

  @override
  State<ManageParkingManagersPage> createState() =>
      _ManageParkingManagersPageState();
}

class _ManageParkingManagersPageState
    extends State<ManageParkingManagersPage> {
  bool _loading = true;
  List<Map<String, dynamic>> _managers = [];

  @override
  void initState() {
    super.initState();
    _loadManagers();
  }

  // ----------------------------------------------------
  // FETCH PARKING MANAGERS
  // ----------------------------------------------------
  Future<void> _loadManagers() async {
    final res = await supabase
        .from('users')
        .select()
        .eq('role', 'parking_manager')
        .order('created_at', ascending: false);

    setState(() {
      _managers = List<Map<String, dynamic>>.from(res);
      _loading = false;
    });
  }

  // ----------------------------------------------------
  // CREATE / EDIT DIALOG
  // ----------------------------------------------------
  void _openForm({Map<String, dynamic>? manager}) {
    final nameCtrl =
        TextEditingController(text: manager?['full_name'] ?? '');
    final emailCtrl =
        TextEditingController(text: manager?['email'] ?? '');
    final phoneCtrl =
        TextEditingController(text: manager?['phone'] ?? '');

    final isEdit = manager != null;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isEdit ? "Edit Manager" : "Create Manager"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: "Full Name"),
            ),
            TextField(
              controller: emailCtrl,
              enabled: !isEdit,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            TextField(
              controller: phoneCtrl,
              decoration: const InputDecoration(labelText: "Phone"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                if (isEdit) {
                  await supabase.from('users').update({
                    'full_name': nameCtrl.text.trim(),
                    'phone': phoneCtrl.text.trim(),
                  }).eq('id', manager!['id']);
                } else {
                  await supabase.from('users').insert({
                    'full_name': nameCtrl.text.trim(),
                    'email': emailCtrl.text.trim(),
                    'role': 'parking_manager',
                    'phone': phoneCtrl.text.trim(),
                    'is_active': true,
                  });
                }

                Navigator.pop(context);
                _loadManagers();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(e.toString())),
                );
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // DELETE MANAGER
  // ----------------------------------------------------
  Future<void> _deleteManager(String id) async {
    await supabase.from('users').delete().eq('id', id);
    _loadManagers();
  }

  // ----------------------------------------------------
  // UI
  // ----------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Parking Managers"),
        backgroundColor: Colors.red,
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.red,
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: ParkingAdminAppBar(),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _managers.isEmpty
              ? const Center(child: Text("No parking managers"))
              : ListView.builder(
                  itemCount: _managers.length,
                  itemBuilder: (context, index) {
                    final m = _managers[index];

                    return ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.person),
                      ),
                      title: Text(m['full_name'] ?? ''),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(m['email']),
                          Text(m['phone'] ?? ''),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _openForm(manager: m),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteManager(m['id']),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
