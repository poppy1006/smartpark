import 'package:flutter/material.dart';
import 'package:smartparking/parkingAdmin/widget/bottom_app_bar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smartparking/authentication/login_page.dart';
import 'package:smartparking/user/widgets/bottom_app_bar.dart';

final supabase = Supabase.instance.client;

class ParkingAdminProfile extends StatefulWidget {
  const ParkingAdminProfile({super.key});

  @override
  State<ParkingAdminProfile> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<ParkingAdminProfile> {
  bool loading = true;
  Map<String, dynamic>? user;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // --------------------------------------------------
  Future<void> _loadProfile() async {
    final uid = supabase.auth.currentUser!.id;

    final res = await supabase
        .from('users')
        .select()
        .eq('id', uid)
        .maybeSingle();

    setState(() {
      user = res;
      loading = false;
    });
  }

  // --------------------------------------------------
  String _initial(String? name) {
    if (name == null || name.isEmpty) return "?";
    return name[0].toUpperCase();
  }

  // --------------------------------------------------
  Future<void> _logout() async {
    await supabase.auth.signOut();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  // --------------------------------------------------
  Future<void> _editProfile() async {
    final nameCtrl = TextEditingController(text: user?['full_name']);
    final phoneCtrl = TextEditingController(text: user?['phone']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Edit Profile",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: "Full Name",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: "Phone",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () async {
                  await supabase.from('users').update({
                    'full_name': nameCtrl.text.trim(),
                    'phone': phoneCtrl.text.trim(),
                  }).eq('id', user!['id']);

                  Navigator.pop(context);
                  _loadProfile();
                },
                child: const Text("Save Changes"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------
  Widget _infoTile(IconData icon, String label, String value) {
    return ListTile(
      leading: Icon(icon, color: Colors.red),
      title: Text(label),
      subtitle: Text(
        value,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }

  // --------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const ParkingAdminAppBar(),
      backgroundColor: Colors.grey.shade100,

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // HEADER
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(top: 60, bottom: 40),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.red, Colors.deepOrange],
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(35),
                      bottomRight: Radius.circular(35),
                    ),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: Colors.white,
                        child: Text(
                          _initial(user!['full_name']),
                          style: const TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      Text(
                        user!['full_name'] ?? '',
                        style: const TextStyle(
                          fontSize: 22,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          user!['role']
                              .toString()
                              .replaceAll('_', ' ')
                              .toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // INFO CARD
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    child: Column(
                      children: [
                        _infoTile(Icons.email, "Email", user!['email']),
                        const Divider(height: 1),
                        _infoTile(Icons.phone, "Phone",
                            user!['phone'] ?? "Not set"),
                        const Divider(height: 1),
                        _infoTile(
                          Icons.badge,
                          "Role",
                          user!['role']
                              .toString()
                              .replaceAll('_', ' ')
                              .toUpperCase(),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // EDIT BUTTON
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _editProfile,
                      icon: const Icon(Icons.edit),
                      label: const Text("Edit Profile"),
                    ),
                  ),
                ),

                const Spacer(),

                // LOGOUT
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.logout),
                      label: const Text("Logout"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _logout,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
