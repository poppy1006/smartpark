// import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:latlong2/latlong.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'package:smartparking/models/parking_model.dart';

// final supabase = Supabase.instance.client;

// class NearbyParkingsPage extends StatefulWidget {
//   const NearbyParkingsPage({super.key});

//   @override
//   State<NearbyParkingsPage> createState() => _NearbyParkingsPageState();
// }

// class _NearbyParkingsPageState extends State<NearbyParkingsPage> {
//   LatLng? _currentLocation;
//   bool _loading = true;
//   String? _error;

//   List<ParkingModel> _parkings = [];

//   @override
//   void initState() {
//     super.initState();
//     _init();
//   }

//   Future<void> _init() async {
//     try {
//       await _getCurrentLocation();
//       await _fetchParkings();
//       await _attachAvailableSlots();
//       _sortByDistance();
//     } catch (e) {
//       _error = e.toString();
//     } finally {
//       if (mounted) setState(() => _loading = false);
//     }
//   }

//   /// 📍 LOCATION
//   Future<void> _getCurrentLocation() async {
//     if (!await Geolocator.isLocationServiceEnabled()) {
//       throw Exception('Location services disabled');
//     }

//     LocationPermission permission =
//         await Geolocator.checkPermission();

//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//     }

//     if (permission == LocationPermission.denied ||
//         permission == LocationPermission.deniedForever) {
//       throw Exception('Location permission denied');
//     }

//     final position = await Geolocator.getCurrentPosition(
//       desiredAccuracy: LocationAccuracy.high,
//     );

//     _currentLocation =
//         LatLng(position.latitude, position.longitude);
//   }

//   /// 🅿️ FETCH PARKINGS
//   Future<void> _fetchParkings() async {
//     final res = await supabase
//         .from('parkings')
//         .select(
//           'id, name, latitude, longitude, hourly_price',
//         )
//         .eq('is_active', true);

//     _parkings =
//         (res as List).map((e) => ParkingModel.fromMap(e)).toList();
//   }

//   /// ✅ ATTACH AVAILABLE SLOTS (CORRECT WAY)
//   Future<void> _attachAvailableSlots() async {
//     if (_parkings.isEmpty) return;

//     final parkingIds = _parkings.map((p) => p.id).toList();

//     final slotsRes = await supabase
//         .from('parking_slots')
//         .select('parking_id')
//         .eq('status', 'free')
//         .inFilter('parking_id', parkingIds);

//     final Map<String, int> slotCount = {};

//     for (final s in slotsRes) {
//       final pid = s['parking_id'].toString();
//       slotCount[pid] = (slotCount[pid] ?? 0) + 1;
//     }

//     for (final p in _parkings) {
//       p.availableSlots = slotCount[p.id] ?? 0;
//     }
//   }

//   /// 📏 SORT BY DISTANCE
//   void _sortByDistance() {
//     final distance = const Distance();
//     _parkings.sort((a, b) {
//       final d1 = distance(_currentLocation!, a.latLng);
//       final d2 = distance(_currentLocation!, b.latLng);
//       return d1.compareTo(d2);
//     });
//   }

//   /// 🧭 NAVIGATION
//   Future<void> _navigate(ParkingModel parking) async {
//     final uri = Uri.parse(
//       'https://www.google.com/maps/dir/?api=1&destination=${parking.latitude},${parking.longitude}',
//     );
//     await launchUrl(uri, mode: LaunchMode.externalApplication);
//   }

//   String _distanceText(ParkingModel p) {
//     final m = const Distance()(_currentLocation!, p.latLng);
//     return m < 1000
//         ? '${m.toStringAsFixed(0)} m'
//         : '${(m / 1000).toStringAsFixed(1)} km';
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Nearby Parkings'),
//         backgroundColor: Colors.red,
//       ),
//       body: _loading
//           ? const Center(child: CircularProgressIndicator())
//           : _error != null
//               ? Center(child: Text(_error!))
//               : ListView.builder(
//                   padding: const EdgeInsets.all(16),
//                   itemCount: _parkings.length,
//                   itemBuilder: (context, index) {
//                     final p = _parkings[index];

//                     return Card(
//                       margin: const EdgeInsets.only(bottom: 12),
//                       child: Padding(
//                         padding: const EdgeInsets.all(14),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               p.name,
//                               style: const TextStyle(
//                                 fontSize: 16,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                             const SizedBox(height: 4),
//                             Text(
//                               _distanceText(p),
//                               style: const TextStyle(color: Colors.grey),
//                             ),
//                             const SizedBox(height: 8),
//                             Row(
//                               children: [
//                                 Text('✅ ${p.availableSlots} slots'),
//                                 const SizedBox(width: 16),
//                                 Text('₹${p.hourlyPrice}/hr'),
//                               ],
//                             ),
//                             const SizedBox(height: 10),
//                             SizedBox(
//                               width: double.infinity,
//                               child: ElevatedButton.icon(
//                                 icon: const Icon(Icons.navigation),
//                                 label: const Text('Navigate'),
//                                 onPressed: () => _navigate(p),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:smartparking/user/available_slots_page.dart';
import 'package:smartparking/user/widgets/bottom_app_bar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:smartparking/models/parking_model.dart';

final supabase = Supabase.instance.client;

class NearbyParkingsPage extends StatefulWidget {
  const NearbyParkingsPage({super.key});

  @override
  State<NearbyParkingsPage> createState() => _NearbyParkingsPageState();
}

class _NearbyParkingsPageState extends State<NearbyParkingsPage> {
  LatLng? _currentLocation;
  bool _loading = true;
  String? _error;

  final TextEditingController _searchController = TextEditingController();

  List<ParkingModel> _parkings = [];
  List<ParkingModel> _filteredParkings = [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  ///  MAIN INIT
  Future<void> _init() async {
    try {
      await _getCurrentLocation();
      await _fetchParkings();
      await _attachAvailableSlots();
      _sortByDistance();

      if (mounted) {
        setState(() {
          _filteredParkings = List.from(_parkings);
        });
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  ///  GET LOCATION
  Future<void> _getCurrentLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw Exception('Location services disabled');
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception('Location permission denied');
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    _currentLocation = LatLng(position.latitude, position.longitude);
  }

  ///  FETCH PARKINGS
  Future<void> _fetchParkings() async {
    final res = await supabase
        .from('parkings')
        .select('id, name, latitude, longitude, hourly_price')
        .eq('is_active', true);

    _parkings = (res as List).map((e) => ParkingModel.fromMap(e)).toList();
  }

  /// COUNT FREE SLOTS
  Future<void> _attachAvailableSlots() async {
    if (_parkings.isEmpty) return;

    final parkingIds = _parkings.map((p) => p.id).toList();

    final slotsRes = await supabase
        .from('parking_slots')
        .select('parking_id')
        .eq('status', 'free')
        .inFilter('parking_id', parkingIds);

    final Map<String, int> slotCount = {};

    for (final s in slotsRes) {
      final pid = s['parking_id'].toString();
      slotCount[pid] = (slotCount[pid] ?? 0) + 1;
    }

    for (final p in _parkings) {
      p.availableSlots = slotCount[p.id] ?? 0;
    }
  }

  /// SORT BY DISTANCE
  void _sortByDistance() {
    final distance = const Distance();
    _parkings.sort((a, b) {
      final d1 = distance(_currentLocation!, a.latLng);
      final d2 = distance(_currentLocation!, b.latLng);
      return d1.compareTo(d2);
    });
  }

  /// SEARCH FILTER
  void _filterParkings(String query) {
    if (_parkings.isEmpty) return;

    if (query.isEmpty) {
      setState(() => _filteredParkings = _parkings);
      return;
    }

    setState(() {
      _filteredParkings = _parkings
          .where((p) => p.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  ///  NAVIGATION
  Future<void> _navigate(ParkingModel parking) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${parking.latitude},${parking.longitude}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  String _distanceText(ParkingModel p) {
    final m = const Distance()(_currentLocation!, p.latLng);
    return m < 1000
        ? '${m.toStringAsFixed(0)} m'
        : '${(m / 1000).toStringAsFixed(1)} km';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Parkings'),
        backgroundColor: Colors.red,
      ),
      bottomNavigationBar: UserBottomAppBar(),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : Column(
              children: [
                /// SEARCH BAR
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _filterParkings,
                    decoration: InputDecoration(
                      hintText: 'Search parking...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                  _filteredParkings = _parkings;
                                });
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),

                ///  PARKING LIST
                Expanded(
                  child: _filteredParkings.isEmpty
                      ? const Center(child: Text('No parkings found'))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: _filteredParkings.length,
                          itemBuilder: (context, index) {
                            final p = _filteredParkings[index];

                            return GestureDetector(
                              child: Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        p.name,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _distanceText(p),
                                        style: const TextStyle(
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Text('✅ ${p.availableSlots} slots'),
                                          const SizedBox(width: 16),
                                          Text('₹${p.hourlyPrice}/hr'),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          icon: const Icon(Icons.navigation),
                                          label: const Text('Navigate'),
                                          onPressed: () => _navigate(p),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // Implement ontap function in gesture to click this card
                              // onTap: () {
                              //   Navigator.push(
                              //     context,
                              //     MaterialPageRoute(
                              //       builder: (_) => AvailableSlotsPage(
                              //         parkingId: p.id,
                              //         parkingName: p.name,
                              //         hourlyPrice: p.hourlyPrice,
                              //       ),
                              //     ),
                              //   );
                              // },
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AvailableSlotsPage(
                                      parkingId: p.id,
                                      parkingName: p.name,
                                      hourlyPrice: p.hourlyPrice,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
