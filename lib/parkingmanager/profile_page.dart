// import 'package:flutter/material.dart';
// import 'package:smartparking/authentication/login_page.dart';
// import 'package:smartparking/parkingAdmin/widget/bottom_app_bar.dart';
// import 'package:smartparking/user/widgets/bottom_app_bar.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// class ManagerProfilePage extends StatelessWidget {
//   const ManagerProfilePage({super.key});

//   String _getInitial(String? name) {
//     if (name == null || name.isEmpty) return '?';
//     return name[0].toUpperCase();
//   }

//   Future<void> _logout(BuildContext context) async {
//     await Supabase.instance.client.auth.signOut();

//     Navigator.pushAndRemoveUntil(
//       context,
//       MaterialPageRoute(builder: (_) => const LoginPage()),
//       (route) => false,
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final user = Supabase.instance.client.auth.currentUser;

//     final name = user?.userMetadata?['full_name'] ?? 'Parking Manager';
//     final email = user?.email ?? 'No email';
//     final role = user?.userMetadata?['role'] ?? 'Manager';

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Profile'),
//         centerTitle: true,
//       ),
//       bottomNavigationBar: ParkingAdminAppBar(),
//       body: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           children: [
//             const SizedBox(height: 30),

//             // Avatar with first letter
//             CircleAvatar(
//               radius: 45,
//               backgroundColor: Colors.red,
//               child: Text(
//                 _getInitial(name),
//                 style: const TextStyle(
//                   fontSize: 36,
//                   color: Colors.white,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),

//             const SizedBox(height: 20),

//             // Name
//             Text(
//               name,
//               style: const TextStyle(
//                 fontSize: 22,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),

//             const SizedBox(height: 5),

//             // Email
//             Text(
//               email,
//               style: const TextStyle(color: Colors.grey),
//             ),

//             const SizedBox(height: 5),

//             // Role
//             Chip(
//               label: Text(
//                 role.toUpperCase(),
//                 style: const TextStyle(color: Colors.white),
//               ),
//               backgroundColor: Colors.blue,
//             ),

//             const SizedBox(height: 40),

//             // Logout button
//             SizedBox(
//               width: double.infinity,
//               height: 50,
//               child: ElevatedButton.icon(
//                 icon: const Icon(Icons.logout),
//                 label: const Text("Logout"),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.red,
//                 ),
//                 onPressed: () => _logout(context),
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

class ManagerProfilePage extends StatelessWidget {
  const ManagerProfilePage({super.key});

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
