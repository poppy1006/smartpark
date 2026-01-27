import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class ManageParkingManagersPage extends StatefulWidget {
  const ManageParkingManagersPage({super.key});

  @override
  State<ManageParkingManagersPage> createState() =>
      _ManageParkingManagersPageState();
}

class _ManageParkingManagersPageState extends State<ManageParkingManagersPage> {
  bool _loading = true;
  bool _creating = false;

  List<Map<String, dynamic>> _managers = [];

  @override
  void initState() {
    super.initState();
    _loadManagers();
  }

  // FETCH AND LOAD MANAGERS //
  Future<void> _loadManagers() async {
    setState(() => _loading = true);

    final adminId = supabase.auth.currentUser!.id;

    final res = await supabase
        .from('users')
        .select()
        .eq('role', 'parking_manager')
        .eq('parkingadmin_id', adminId)
        .order('created_at', ascending: true);

    setState(() {
      _managers = List<Map<String, dynamic>>.from(res);
      _loading = false;
    });
  }

  // CREATE MANAGER (USING SUPABASE EDGE FUNCTION) //
  void _showAddManagerDialog() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("Create Parking Manager"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: "Full Name"),
              ),
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: "Email"),
              ),
              TextField(
                controller: phoneCtrl,
                decoration: const InputDecoration(labelText: "Phone"),
              ),
              TextField(
                controller: passwordCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Password"),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _creating ? null : () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: _creating
                ? null
                : () async {
                    if (nameCtrl.text.isEmpty ||
                        emailCtrl.text.isEmpty ||
                        passwordCtrl.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Name, Email and Password required"),
                        ),
                      );
                      return;
                    }

                    setState(() => _creating = true);

                    try {
                      final session = supabase.auth.currentSession!;

                      await supabase.functions.invoke(
                        'create_parking_manager',
                        headers: {
                          "Authorization": "Bearer ${session.accessToken}",
                        },
                        body: {
                          "name": nameCtrl.text.trim(),
                          "email": emailCtrl.text.trim(),
                          "phone": phoneCtrl.text.trim(),
                          "password": passwordCtrl.text.trim(),
                        },
                      );

                      if (!mounted) return;

                      Navigator.pop(context);
                      await _loadManagers();

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Manager created successfully"),
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(e.toString())));
                    } finally {
                      setState(() => _creating = false);
                    }
                  },
            child: _creating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text("Create"),
          ),
        ],
      ),
    );
  }

  // EDIT MANAGER //
  void _showEditManagerDialog(Map manager) {
    final nameCtrl = TextEditingController(text: manager['full_name'] ?? '');
    final phoneCtrl = TextEditingController(text: manager['phone'] ?? '');
    bool isActive = manager['is_active'] ?? true;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text("Edit Manager"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: "Full Name"),
              ),
              TextField(
                controller: phoneCtrl,
                decoration: const InputDecoration(labelText: "Phone"),
              ),
              SwitchListTile(
                value: isActive,
                onChanged: (v) => setLocal(() => isActive = v),
                title: const Text("Active"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),

            // DELETE
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _confirmDelete(manager['id']);
              },
              child: const Text("Delete", style: TextStyle(color: Colors.red)),
            ),

            // UPDATE
            ElevatedButton(
              onPressed: () async {
                await supabase
                    .from('users')
                    .update({
                      'full_name': nameCtrl.text.trim(),
                      'phone': phoneCtrl.text.trim(),
                      'is_active': isActive,
                    })
                    .eq('id', manager['id']);

                if (!mounted) return;

                Navigator.pop(context);
                _loadManagers();
              },
              child: const Text("Update"),
            ),
          ],
        ),
      ),
    );
  }

  // DELETE MANAGER (EDGE FUNCTION)
  void _confirmDelete(String managerId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Manager"),
        content: const Text(
          "This will permanently delete the manager account.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                final session = supabase.auth.currentSession!;

                await supabase.functions.invoke(
                  'delete_parking_manager',
                  headers: {"Authorization": "Bearer ${session.accessToken}"},
                  body: {"manager_id": managerId},
                );

                if (!mounted) return;

                Navigator.pop(context);
                _loadManagers();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Manager deleted successfully")),
                );
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(e.toString())));
              }
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  // UI CODE //
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Parking Managers"),
        backgroundColor: Colors.red,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.red,
        onPressed: _showAddManagerDialog,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _managers.isEmpty
          ? const Center(child: Text("No managers found"))
          : ListView.builder(
              itemCount: _managers.length,
              itemBuilder: (context, index) {
                final m = _managers[index];

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.person),
                    title: Text(m['full_name'] ?? ''),
                    subtitle: Text(m['email']),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          m['is_active'] ? Icons.check_circle : Icons.block,
                          color: m['is_active'] ? Colors.green : Colors.red,
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _showEditManagerDialog(m),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
