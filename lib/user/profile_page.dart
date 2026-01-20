import 'package:flutter/material.dart';
import 'package:smartparking/authentication/login_page.dart';
import 'package:smartparking/user/widgets/bottom_app_bar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smartparking/models/user_profile_model.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final _supabase = Supabase.instance.client;

  UserProfileModel? _profile;
  bool _loading = true;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  String _getInitial(String name) => name.isEmpty ? '?' : name[0].toUpperCase();

  ///  Fetch profile from users table
  Future<void> _fetchProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final data = await _supabase
        .from('users')
        .select()
        .eq('id', user.id)
        .single();

    setState(() {
      _profile = UserProfileModel.fromMap(data);
      _nameController.text = _profile!.fullName;
      _phoneController.text = _profile!.phone ?? '';
      _loading = false;
    });
  }

  ///  Update profile
  Future<void> _updateProfile() async {
    if (_profile == null) return;

    await _supabase.from('users').update({
      'full_name': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
    }).eq('id', _profile!.id);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated')),
    );

    _fetchProfile();
  }

  ///  Logout
  Future<void> _logout() async {
    await _supabase.auth.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profile'), centerTitle: true),
      bottomNavigationBar: const UserBottomAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),

            /// Avatar
            CircleAvatar(
              radius: 45,
              backgroundColor: Colors.red,
              child: Text(
                _getInitial(_profile!.fullName),
                style: const TextStyle(
                  fontSize: 36,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// Name
            Text(
              _profile!.fullName,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 4),

            /// Email
            Text(_profile!.email, style: const TextStyle(color: Colors.grey)),

            const SizedBox(height: 6),

            /// Role
            Chip(
              label: Text(
                _profile!.role.toUpperCase(),
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.blue,
            ),

            const SizedBox(height: 30),

            /// Editable fields
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            /// Save Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _updateProfile,
                child: const Text('Save Changes'),
              ),
            ),

            const Spacer(),

            /// Logout Button 
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text("Logout"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: _logout,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
