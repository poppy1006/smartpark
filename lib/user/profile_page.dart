// import 'package:flutter/material.dart';
// import 'package:smartparking/authentication/login_page.dart';
// import 'package:smartparking/user/widgets/bottom_app_bar.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:smartparking/models/user_profile_model.dart';

// class UserProfilePage extends StatefulWidget {
//   const UserProfilePage({super.key});

//   @override
//   State<UserProfilePage> createState() => _UserProfilePageState();
// }

// class _UserProfilePageState extends State<UserProfilePage> {
//   final _supabase = Supabase.instance.client;

//   UserProfileModel? _profile;
//   bool _loading = true;

//   final _nameController = TextEditingController();
//   final _phoneController = TextEditingController();

//   @override
//   void initState() {
//     super.initState();
//     _fetchProfile();
//   }

//   String _getInitial(String name) => name.isEmpty ? '?' : name[0].toUpperCase();

//   ///  Fetch profile from users table
//   Future<void> _fetchProfile() async {
//     final user = _supabase.auth.currentUser;
//     if (user == null) return;

//     final data = await _supabase
//         .from('users')
//         .select()
//         .eq('id', user.id)
//         .single();

//     setState(() {
//       _profile = UserProfileModel.fromMap(data);
//       _nameController.text = _profile!.fullName;
//       _phoneController.text = _profile!.phone ?? '';
//       _loading = false;
//     });
//   }

//   ///  Update profile
//   Future<void> _updateProfile() async {
//     if (_profile == null) return;

//     await _supabase.from('users').update({
//       'full_name': _nameController.text.trim(),
//       'phone': _phoneController.text.trim(),
//     }).eq('id', _profile!.id);

//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text('Profile updated')),
//     );

//     _fetchProfile();
//   }

//   ///  Logout
//   Future<void> _logout() async {
//     await _supabase.auth.signOut();
//     Navigator.pushAndRemoveUntil(
//       context,
//       MaterialPageRoute(builder: (_) => const LoginPage()),
//       (_) => false,
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_loading) {
//       return const Scaffold(
//         body: Center(child: CircularProgressIndicator()),
//       );
//     }

//     return Scaffold(
//       appBar: AppBar(title: const Text('Profile'), centerTitle: true),
//       bottomNavigationBar: const UserBottomAppBar(),
//       body: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           children: [
//             const SizedBox(height: 20),

//             /// Avatar
//             CircleAvatar(
//               radius: 45,
//               backgroundColor: Colors.red,
//               child: Text(
//                 _getInitial(_profile!.fullName),
//                 style: const TextStyle(
//                   fontSize: 36,
//                   color: Colors.white,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),

//             const SizedBox(height: 20),

//             /// Name
//             Text(
//               _profile!.fullName,
//               style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
//             ),

//             const SizedBox(height: 4),

//             /// Email
//             Text(_profile!.email, style: const TextStyle(color: Colors.grey)),

//             const SizedBox(height: 6),

//             /// Role
//             Chip(
//               label: Text(
//                 _profile!.role.toUpperCase(),
//                 style: const TextStyle(color: Colors.white),
//               ),
//               backgroundColor: Colors.blue,
//             ),

//             const SizedBox(height: 30),

//             /// Editable fields
//             TextField(
//               controller: _nameController,
//               decoration: const InputDecoration(
//                 labelText: 'Full Name',
//                 border: OutlineInputBorder(),
//               ),
//             ),

//             const SizedBox(height: 15),

//             TextField(
//               controller: _phoneController,
//               keyboardType: TextInputType.phone,
//               decoration: const InputDecoration(
//                 labelText: 'Phone',
//                 border: OutlineInputBorder(),
//               ),
//             ),

//             const SizedBox(height: 20),

//             /// Save Button
//             SizedBox(
//               width: double.infinity,
//               height: 48,
//               child: ElevatedButton(
//                 onPressed: _updateProfile,
//                 child: const Text('Save Changes'),
//               ),
//             ),

//             const Spacer(),

//             /// Logout Button 
//             SizedBox(
//               width: double.infinity,
//               height: 50,
//               child: ElevatedButton.icon(
//                 icon: const Icon(Icons.logout),
//                 label: const Text("Logout"),
//                 style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
//                 onPressed: _logout,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }



import 'package:flutter/material.dart';
import 'package:smartparking/authentication/login_page.dart';
import 'package:smartparking/parkingAdmin/widget/bottom_app_bar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserProfilePage extends StatelessWidget {
  const UserProfilePage({super.key});

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

    final name =
        user?.userMetadata?['full_name'] ?? 'Parking Manager';
    final email = user?.email ?? 'No email';
    final role =
        user?.userMetadata?['role'] ?? 'parking_manager';

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      bottomNavigationBar: ParkingAdminAppBar(),

      body: Column(
        children: [

          // ================= HEADER =================
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(
              top: 60,
              bottom: 40,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red, Colors.deepOrange],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [

                // Avatar
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      )
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 45,
                    backgroundColor: Colors.white,
                    child: Text(
                      _getInitial(name),
                      style: const TextStyle(
                        fontSize: 36,
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Name
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 22,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                // Role Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    role.replaceAll('_', ' ').toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // ================= INFO CARD =================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              child: Column(
                children: [

                  _infoTile(
                    icon: Icons.email,
                    label: "Email",
                    value: email,
                  ),

                  const Divider(height: 1),

                  _infoTile(
                    icon: Icons.person,
                    label: "Role",
                    value:
                        role.replaceAll('_', ' ').toUpperCase(),
                  ),
                ],
              ),
            ),
          ),

          const Spacer(),

          // ================= LOGOUT =================
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text(
                  "Logout",
                  style: TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => _logout(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= REUSABLE TILE =================
  Widget _infoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.red),
      title: Text(label),
      subtitle: Text(
        value,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
