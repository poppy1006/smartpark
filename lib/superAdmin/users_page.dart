import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  List<Map<String, dynamic>> users = [];
  String roleFilter = 'all';
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  // LOAD USERS
  Future<void> _loadUsers() async {
    setState(() => loading = true);

    try {
      var query = supabase.from('users').select();

      if (roleFilter != 'all') {
        query = query.eq('role', roleFilter);
      }

      final res = await query.order('created_at', ascending: false);

      setState(() {
        users = List<Map<String, dynamic>>.from(res);
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      _show("Load error: $e");
    }
  }

  // TOGGLE ACTIVE
  Future<void> _toggleActive(String id, bool active) async {
    try {
      await supabase.from('users').update({'is_active': !active}).eq('id', id);

      _loadUsers();
    } catch (e) {
      _show("Update failed: $e");
    }
  }

  // CHANGE ROLE
  Future<void> _changeRole(String id, String role) async {
    try {
      await supabase.from('users').update({'role': role}).eq('id', id);
      _loadUsers();
    } catch (e) {
      _show("Role change failed: $e");
    }
  }

  // DELETE USER
  Future<void> _deleteUser(String id) async {
    try {
      await supabase.from('users').delete().eq('id', id);
      _loadUsers();
    } catch (e) {
      _show("Delete failed: $e");
    }
  }

  void _show(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("All Users"),
        backgroundColor: Colors.red,
      ),

      body: Column(
        children: [
          // FILTER
          Padding(
            padding: const EdgeInsets.all(12),
            child: DropdownButtonFormField(
              value: roleFilter,
              decoration: const InputDecoration(
                labelText: "Filter by role",
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'all', child: Text("All")),
                DropdownMenuItem(value: 'user', child: Text("User")),
                DropdownMenuItem(
                  value: 'parking_admin',
                  child: Text("Parking Admin"),
                ),
                DropdownMenuItem(
                  value: 'parking_manager',
                  child: Text("Parking Manager"),
                ),
                DropdownMenuItem(
                  value: 'super_admin',
                  child: Text("Super Admin"),
                ),
              ],
              onChanged: (v) {
                setState(() => roleFilter = v!);
                _loadUsers();
              },
            ),
          ),

          // LIST
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : users.isEmpty
                ? const Center(child: Text("No users found"))
                : ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (_, i) {
                      final u = users[i];

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        child: ListTile(
                          leading: const Icon(Icons.person),
                          title: Text(u['email']),
                          subtitle: Text("Role: ${u['role']}"),

                          // ACTIONS
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // ACTIVE SWITCH
                              Switch(
                                value: u['is_active'] ?? true,
                                onChanged: (_) =>
                                    _toggleActive(u['id'], u['is_active']),
                              ),

                              // MENU
                              PopupMenuButton<String>(
                                onSelected: (v) {
                                  if (v == 'delete') {
                                    _deleteUser(u['id']);
                                  } else {
                                    _changeRole(u['id'], v);
                                  }
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                    value: 'user',
                                    child: Text("Set User"),
                                  ),
                                  PopupMenuItem(
                                    value: 'parking_admin',
                                    child: Text("Set Parking Admin"),
                                  ),
                                  PopupMenuItem(
                                    value: 'parking_manager',
                                    child: Text("Set Parking Manager"),
                                  ),
                                  PopupMenuItem(
                                    value: 'super_admin',
                                    child: Text("Set Super Admin"),
                                  ),
                                  PopupMenuDivider(),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Text(
                                      "Delete User",
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
