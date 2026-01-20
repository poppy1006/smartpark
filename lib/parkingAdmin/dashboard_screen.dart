import 'package:flutter/material.dart';
import 'package:smartparking/parkingAdmin/parking_form_page.dart';
import 'package:smartparking/parkingAdmin/parking_slots_page.dart';
// import 'package:smartparking/parkingAdmin/parking_slots_page.dart';
import 'package:smartparking/parkingAdmin/slot_form_page.dart';
import 'package:smartparking/parkingAdmin/widget/bottom_app_bar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class ParkingAdminDashboard extends StatefulWidget {
  const ParkingAdminDashboard({super.key});

  @override
  State<ParkingAdminDashboard> createState() => _ParkingAdminDashboardState();
}

class _ParkingAdminDashboardState extends State<ParkingAdminDashboard> {
  bool _loading = true;

  int totalParkings = 0;
  int totalSlots = 0;
  int availableSlots = 0;

  List<Map<String, dynamic>> parkings = [];
  List<Map<String, dynamic>> filteredParkings = [];

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    try {
      final userId = supabase.auth.currentUser!.id;

      /// Fetch parkings
      final parkingRes = await supabase
          .from('parkings')
          .select('*')
          .eq('owner_id', userId);

      parkings = List<Map<String, dynamic>>.from(parkingRes);
      filteredParkings = parkings; // initially same
      totalParkings = parkings.length;

      final parkingIds = parkings.map((e) => e['id']).toList();

      if (parkingIds.isNotEmpty) {
        final slotsRes = await supabase
            .from('slots')
            .select('status')
            .inFilter('parking_id', parkingIds);

        totalSlots = slotsRes.length;
        availableSlots = slotsRes.where((s) => s['status'] == 'free').length;
      }

      setState(() => _loading = false);
    } catch (e) {
      debugPrint('Dashboard error: $e');
      setState(() => _loading = false);
    }
  }

  /// SEARCH FILTER
  void _filterParkings(String query) {
    if (query.isEmpty) {
      filteredParkings = parkings;
    } else {
      filteredParkings = parkings
          .where(
            (p) => p['name'].toString().toLowerCase().contains(
              query.toLowerCase(),
            ),
          )
          .toList();
    }
    setState(() {});
  }

  Widget _statCard(String title, int value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value.toString(),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildDrawer(context),
      appBar: AppBar(
        title: const Text('Parking Admin Dashboard'),
        backgroundColor: Colors.red,
      ),
      bottomNavigationBar: const ParkingAdminAppBar(),

      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// STATS
                  Row(
                    children: [
                      _statCard(
                        'Total Parkings',
                        totalParkings,
                        Icons.local_parking,
                        Colors.blue,
                      ),
                      const SizedBox(width: 12),
                      _statCard(
                        'Total Slots',
                        totalSlots,
                        Icons.apps,
                        Colors.orange,
                      ),
                      const SizedBox(width: 12),
                      _statCard(
                        'Available',
                        availableSlots,
                        Icons.check_circle,
                        Colors.green,
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  /// SEARCH BAR
                  TextField(
                    controller: _searchController,
                    onChanged: _filterParkings,
                    decoration: InputDecoration(
                      hintText: 'Search parking...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// PARKING LIST
                  const Text(
                    'Your Parkings',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 12),

                  Expanded(
                    child: filteredParkings.isEmpty
                        ? const Center(child: Text('No parkings found'))
                        : ListView.separated(
                            itemCount: filteredParkings.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final parking = filteredParkings[index];

                              return Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  leading: const Icon(
                                    Icons.local_parking,
                                    color: Colors.red,
                                  ),
                                  title: Text(parking['name']),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => ParkingFormPage(
                                                parking: parking,
                                              ),
                                            ),
                                          );
                                        },
                                        icon: Icon(Icons.edit),
                                      ),
                                      // Icon(Icons.arrow_forward_ios, size: 16),
                                    ],
                                  ),
                                  onTap: () {
                                    // Implement slots here
                                    Navigator.push(context, 
                                    MaterialPageRoute(builder: (_) => ParkingSlotsPage(parkingId: parking['id'], parkingName: parking['name'])
                                    ));
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}


//--------------Drawer----------------//

Widget _buildDrawer(BuildContext context) {
  final user = supabase.auth.currentUser;

  return Drawer(
    child: Column(
      children: [
        UserAccountsDrawerHeader(
          decoration: const BoxDecoration(color: Colors.red),
          accountName: const Text('Parking Admin'),
          accountEmail: Text(user?.email ?? ''),
          currentAccountPicture: const CircleAvatar(
            backgroundColor: Colors.white,
            child: Icon(Icons.person, color: Colors.red),
          ),
        ),

        ListTile(
          leading: const Icon(Icons.dashboard),
          title: const Text('Dashboard'),
          onTap: () {
            Navigator.pop(context);
          },
        ),

        ListTile(
          leading: const Icon(Icons.add_location_alt),
          title: const Text('Create Parking'),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ParkingFormPage(),
              ),
            );
          },
        ),

        ListTile(
          leading: const Icon(Icons.price_change),
          title: Text("Bookings"),
          onTap: () {},
        ),

        const Divider(),

        ListTile(
          leading: const Icon(Icons.logout, color: Colors.red),
          title: const Text('Logout'),
          onTap: () async {
            await supabase.auth.signOut();
            if (context.mounted) {
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/login',
                (route) => false,
              );
            }
          },
        ),
      ],
    ),
  );
}



// Todo //
// # Implement slots View/edit/delete //




