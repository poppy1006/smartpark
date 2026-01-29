// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:latlong2/latlong.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:smartparking/user/widgets/bottom_app_bar.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:smartparking/models/parking_model.dart';
// import 'package:smartparking/user/my_bookings_page.dart';

// final _supabase = Supabase.instance.client;

// class UserDashboardPage extends StatefulWidget {
//   const UserDashboardPage({super.key});

//   @override
//   State<UserDashboardPage> createState() => _MapScreen1State();
// }

// class _MapScreen1State extends State<UserDashboardPage> {
//   late final MapController _mapController;
//   LatLng? _currentLocation;
//   StreamSubscription<Position>? _positionStream;
//   bool _mapReady = false;

//   List<ParkingModel> _parkings = [];
//   List<ParkingModel> _filteredParkings = [];
//   bool _isLoading = true;

//   /// 🔥 QR TIMER
//   DateTime? _qrExpiresAt;
//   Timer? _qrTimer;

//   @override
//   void initState() {
//     super.initState();
//     _mapController = MapController();
//     _startLiveLocation();
//     _fetchParkings();
//     _fetchActiveQr();
//   }

//   @override
//   void dispose() {
//     _positionStream?.cancel();
//     _qrTimer?.cancel();
//     super.dispose();
//   }

//   // FETCH ACTIVE ENTRY QR
//   Future<void> _fetchActiveQr() async {
//     final userId = _supabase.auth.currentUser?.id;
//     if (userId == null) return;

//     final res = await _supabase
//         .from('bookings')
//         .select('qr_expires_at')
//         .eq('user_id', userId)
//         .eq('status', 'pending')
//         .order('created_at', ascending: false)
//         .limit(1)
//         .maybeSingle();

//     if (res != null && res['qr_expires_at'] != null) {
//       _qrExpiresAt = DateTime.parse(res['qr_expires_at']).toLocal();

//       _qrTimer?.cancel();
//       _qrTimer = Timer.periodic(
//         const Duration(seconds: 1),
//         (_) => setState(() {}),
//       );
//     }
//   }

//   // FORMAT COUNTDOWN
//   String _formatCountdown(Duration d) {
//     final m = d.inMinutes;
//     final s = d.inSeconds % 60;
//     return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
//   }

//   // FETCH PARKINGS
//   Future<void> _fetchParkings() async {
//     try {
//       final response = await _supabase
//           .from('parkings')
//           .select('id, name, latitude, longitude')
//           .eq('is_active', true);

//       final data = response as List;
//       final parkings = data.map((e) => ParkingModel.fromMap(e)).toList();

//       setState(() {
//         _parkings = parkings;
//         _filteredParkings = parkings;
//         _isLoading = false;
//       });
//     } catch (e) {
//       setState(() => _isLoading = false);
//     }
//   }

//   // LIVE LOCATION
//   Future<void> _startLiveLocation() async {
//     if (!await Geolocator.isLocationServiceEnabled()) return;

//     LocationPermission permission = await Geolocator.checkPermission();

//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//     }

//     if (permission == LocationPermission.denied ||
//         permission == LocationPermission.deniedForever)
//       return;

//     _positionStream =
//         Geolocator.getPositionStream(
//           locationSettings: const LocationSettings(
//             accuracy: LocationAccuracy.bestForNavigation,
//             distanceFilter: 0,
//           ),
//         ).listen((position) {
//           final latLng = LatLng(position.latitude, position.longitude);

//           setState(() => _currentLocation = latLng);

//           if (_mapReady) {
//             _mapController.move(latLng, _mapController.camera.zoom);
//           }
//         });
//   }

//   void _goToCurrentLocation() {
//     if (_currentLocation != null && _mapReady) {
//       _mapController.move(_currentLocation!, 16);
//     }
//   }

//   // UI
//   @override
//   Widget build(BuildContext context) {
//     final now = DateTime.now();
//     final remaining = _qrExpiresAt != null
//         ? _qrExpiresAt!.difference(now)
//         : null;

//     final showQrTimer = remaining != null && remaining.inSeconds > 0;

//     return Scaffold(
//       bottomNavigationBar: const UserBottomAppBar(),
//       appBar: AppBar(
//         backgroundColor: Colors.red,
//         title: const Text("Smart Parking"),
//       ),
//       body: Stack(
//         children: [
//           // MAP
//           FlutterMap(
//             mapController: _mapController,
//             options: MapOptions(
//               initialCenter: const LatLng(9.9312, 76.2673),
//               initialZoom: 10,
//               onMapReady: () {
//                 _mapReady = true;
//                 if (_currentLocation != null) {
//                   _mapController.move(_currentLocation!, 16);
//                 }
//               },
//             ),
//             children: [
//               TileLayer(
//                 urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
//                 userAgentPackageName: 'com.parkingmanager.app',
//               ),

//               if (_currentLocation != null)
//                 CircleLayer(
//                   circles: [
//                     CircleMarker(
//                       point: _currentLocation!,
//                       radius: 60,
//                       useRadiusInMeter: true,
//                       color: Colors.blue.withOpacity(0.15),
//                       borderColor: Colors.blue.withOpacity(0.4),
//                       borderStrokeWidth: 2,
//                     ),
//                   ],
//                 ),

//               MarkerLayer(
//                 markers: [
//                   ..._filteredParkings.map(
//                     (parking) => Marker(
//                       point: parking.latLng,
//                       width: 120,
//                       height: 120,
//                       child: Column(
//                         children: [
//                           Container(
//                             padding: const EdgeInsets.all(6),
//                             decoration: BoxDecoration(
//                               color: Colors.white,
//                               borderRadius: BorderRadius.circular(8),
//                               boxShadow: const [
//                                 BoxShadow(color: Colors.black26, blurRadius: 4),
//                               ],
//                             ),
//                             child: Text(
//                               parking.name,
//                               maxLines: 1,
//                               overflow: TextOverflow.ellipsis,
//                               style: const TextStyle(
//                                 fontSize: 12,
//                                 fontWeight: FontWeight.w600,
//                               ),
//                             ),
//                           ),
//                           const Icon(
//                             Icons.location_pin,
//                             color: Colors.red,
//                             size: 40,
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),

//                   if (_currentLocation != null)
//                     Marker(
//                       point: _currentLocation!,
//                       width: 22,
//                       height: 22,
//                       child: Container(
//                         decoration: BoxDecoration(
//                           color: Colors.blue,
//                           shape: BoxShape.circle,
//                           border: Border.all(color: Colors.white, width: 3),
//                         ),
//                       ),
//                     ),
//                 ],
//               ),
//             ],
//           ),

//           // FLOATING QR TIMER
//           if (showQrTimer)
//             Positioned(
//               top: 12,
//               left: 16,
//               right: 16,
//               child: GestureDetector(
//                 onTap: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(builder: (_) => const MyBookingsPage()),
//                   );
//                 },
//                 child: Container(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 16,
//                     vertical: 12,
//                   ),
//                   decoration: BoxDecoration(
//                     color: Colors.black87,
//                     borderRadius: BorderRadius.circular(30),
//                   ),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       const Text(
//                         "ENTRY QR expires in",
//                         style: TextStyle(color: Colors.white),
//                       ),
//                       Text(
//                         _formatCountdown(remaining),
//                         style: const TextStyle(
//                           color: Colors.greenAccent,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       const Icon(Icons.qr_code, color: Colors.white),
//                     ],
//                   ),
//                 ),
//               ),
//             ),

//           // LOCATE BUTTON
//           Positioned(
//             bottom: 20,
//             right: 20,
//             child: FloatingActionButton(
//               backgroundColor: Colors.white,
//               onPressed: _goToCurrentLocation,
//               child: const Icon(Icons.my_location, color: Colors.blue),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }


import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:smartparking/user/widgets/bottom_app_bar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smartparking/models/parking_model.dart';
import 'package:smartparking/user/my_bookings_page.dart';

final _supabase = Supabase.instance.client;

class UserDashboardPage extends StatefulWidget {
  const UserDashboardPage({super.key});

  @override
  State<UserDashboardPage> createState() => _MapScreen1State();
}

class _MapScreen1State extends State<UserDashboardPage> {
  late final MapController _mapController;
  LatLng? _currentLocation;
  StreamSubscription<Position>? _positionStream;
  bool _mapReady = false;

  List<ParkingModel> _parkings = [];
  List<ParkingModel> _filteredParkings = [];
  bool _isLoading = true;

  /// 🔥 QR TIMER
  DateTime? _qrExpiresAt;
  Timer? _qrTimer;

  /// ✅ AUTO CENTER TIMER
  Timer? _autoCenterTimer;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _startLiveLocation();
    _fetchParkings();
    _fetchActiveQr();

    // ✅ AUTO MOVE TO CURRENT LOCATION EVERY 3 SECONDS
    _autoCenterTimer =
        Timer.periodic(const Duration(seconds: 3), (_) {
      _goToCurrentLocation();
    });
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _qrTimer?.cancel();
    _autoCenterTimer?.cancel();
    super.dispose();
  }

  // FETCH ACTIVE ENTRY QR
  Future<void> _fetchActiveQr() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    final res = await _supabase
        .from('bookings')
        .select('qr_expires_at')
        .eq('user_id', userId)
        .eq('status', 'pending')
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (res != null && res['qr_expires_at'] != null) {
      _qrExpiresAt =
          DateTime.parse(res['qr_expires_at']).toLocal();

      _qrTimer?.cancel();
      _qrTimer = Timer.periodic(
        const Duration(seconds: 1),
        (_) => setState(() {}),
      );
    }
  }

  // FORMAT COUNTDOWN
  String _formatCountdown(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  // FETCH PARKINGS
  Future<void> _fetchParkings() async {
    try {
      final response = await _supabase
          .from('parkings')
          .select('id, name, latitude, longitude')
          .eq('is_active', true);

      final data = response as List;
      final parkings =
          data.map((e) => ParkingModel.fromMap(e)).toList();

      setState(() {
        _parkings = parkings;
        _filteredParkings = parkings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // LIVE LOCATION
  Future<void> _startLiveLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) return;

    LocationPermission permission =
        await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    _positionStream =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.bestForNavigation,
            distanceFilter: 0,
          ),
        ).listen((position) {
          final latLng =
              LatLng(position.latitude, position.longitude);

          setState(() => _currentLocation = latLng);

          if (_mapReady) {
            _mapController.move(
              latLng,
              _mapController.camera.zoom,
            );
          }
        });
  }

  // MOVE MAP VIEW
  void _goToCurrentLocation() {
    if (_currentLocation != null && _mapReady) {
      _mapController.move(_currentLocation!, 16);
    }
  }

  // UI

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final remaining = _qrExpiresAt != null
        ? _qrExpiresAt!.difference(now)
        : null;

    final showQrTimer =
        remaining != null && remaining.inSeconds > 0;

    return Scaffold(
      bottomNavigationBar: const UserBottomAppBar(),
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: const Text("Smart Parking"),
      ),
      body: Stack(
        children: [
          // ---------------- MAP ----------------
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter:
                  const LatLng(9.9312, 76.2673),
              initialZoom: 10,
              onMapReady: () {
                _mapReady = true;
                if (_currentLocation != null) {
                  _mapController.move(
                      _currentLocation!, 16);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName:
                    'com.parkingmanager.app',
              ),

              if (_currentLocation != null)
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: _currentLocation!,
                      radius: 60,
                      useRadiusInMeter: true,
                      color: Colors.blue.withOpacity(0.15),
                      borderColor:
                          Colors.blue.withOpacity(0.4),
                      borderStrokeWidth: 2,
                    ),
                  ],
                ),

              MarkerLayer(
                markers: [
                  ..._filteredParkings.map(
                    (parking) => Marker(
                      point: parking.latLng,
                      width: 120,
                      height: 120,
                      child: Column(
                        children: [
                          Container(
                            padding:
                                const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                                  BorderRadius.circular(8),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: Text(
                              parking.name,
                              maxLines: 1,
                              overflow:
                                  TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight:
                                    FontWeight.w600,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.location_pin,
                            color: Colors.red,
                            size: 40,
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (_currentLocation != null)
                    Marker(
                      point: _currentLocation!,
                      width: 22,
                      height: 22,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white,
                              width: 3),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),

          // QR TIMER 
          if (showQrTimer)
            Positioned(
              top: 12,
              left: 16,
              right: 16,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            const MyBookingsPage()),
                  );
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius:
                        BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "ENTRY QR expires in",
                        style:
                            TextStyle(color: Colors.white),
                      ),
                      Text(
                        _formatCountdown(remaining),
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Icon(Icons.qr_code,
                          color: Colors.white),
                    ],
                  ),
                ),
              ),
            ),

          // LOCATE BUTTON 
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              backgroundColor: Colors.white,
              onPressed: _goToCurrentLocation,
              child: const Icon(Icons.my_location,
                  color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }
}
