// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:latlong2/latlong.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:smartparking/user/widgets/bottom_app_bar.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:smartparking/models/parking_model.dart';

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

//   @override
//   void initState() {
//     super.initState();
//     _mapController = MapController();
//     _startLiveLocation();
//     _fetchParkings();
//   }

//   @override
//   void dispose() {
//     _positionStream?.cancel();
//     super.dispose();
//   }

//   ///  FETCH PARKINGS FROM SUPABASE
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
//       debugPrint('Error fetching parkings: $e');
//       setState(() => _isLoading = false);
//     }
//   }

//   /// LIVE LOCATION
//   Future<void> _startLiveLocation() async {
//     if (!await Geolocator.isLocationServiceEnabled()) {
//       await Geolocator.openLocationSettings();
//       return;
//     }

//     LocationPermission permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//     }

//     if (permission == LocationPermission.denied ||
//         permission == LocationPermission.deniedForever) {
//       return;
//     }

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

//   ///  PARKING TAP
//   void _onParkingTap(ParkingModel parking) {
//     showModalBottomSheet(
//       context: context,
//       builder: (_) => Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               parking.name,
//               style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 12),
//             ElevatedButton(onPressed: () {}, child: const Text("Book Parking")),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       bottomNavigationBar: const UserBottomAppBar(),
//       appBar: AppBar(
//         backgroundColor: Colors.red,
//         title: const Text("Smart Parking"),
//       ),
//       body: Stack(
//         children: [
//           FlutterMap(
//             mapController: _mapController,
//             options: MapOptions(
//               initialCenter: const LatLng(9.9312, 76.2673),
//               initialZoom: 18,
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

//               ///  ACCURACY CIRCLE
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

//               ///  MARKERS
//               MarkerLayer(
//                 markers: [
//                   ..._filteredParkings.map(
//                     (parking) => Marker(
//                       point: parking.latLng,
//                       width: 120,
//                       height: 80,
//                       child: GestureDetector(
//                         onTap: () => _onParkingTap(parking),
//                         child: Column(
//                           children: [
//                             Container(
//                               padding: const EdgeInsets.symmetric(
//                                 horizontal: 6,
//                                 vertical: 2,
//                               ),
//                               decoration: BoxDecoration(
//                                 color: Colors.white,
//                                 borderRadius: BorderRadius.circular(6),
//                                 boxShadow: const [
//                                   BoxShadow(
//                                     color: Colors.black26,
//                                     blurRadius: 4,
//                                   ),
//                                 ],
//                               ),
//                               child: Text(
//                                 parking.name,
//                                 style: const TextStyle(
//                                   fontSize: 11,
//                                   fontWeight: FontWeight.w600,
//                                 ),
//                               ),
//                             ),
//                             const Icon(
//                               Icons.location_pin,
//                               color: Colors.red,
//                               size: 40,
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),

//                   ///  CURRENT LOCATION DOT
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

//           ///  LOCATE BUTTON
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

  /// 🔥 Track expanded marker
  ParkingModel? _expandedParking;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _startLiveLocation();
    _fetchParkings();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  /// FETCH PARKINGS
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
      debugPrint('Error fetching parkings: $e');
      setState(() => _isLoading = false);
    }
  }

  /// LIVE LOCATION
  Future<void> _startLiveLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      await Geolocator.openLocationSettings();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
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

  void _goToCurrentLocation() {
    if (_currentLocation != null && _mapReady) {
      _mapController.move(_currentLocation!, 16);
    }
  }

  /// PARKING TAP → BOTTOM SHEET popup
  void _onParkingTap(ParkingModel parking) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              parking.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {},
                child: const Text("Book Parking"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const UserBottomAppBar(),
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: const Text("Smart Parking"),
      ),
      
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(9.9312, 76.2673),
              initialZoom: 5, // was 18
              onMapReady: () {
                _mapReady = true;
                if (_currentLocation != null) {
                  _mapController.move(_currentLocation!, 16);
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

              /// ACCURACY CIRCLE
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

              /// MARKERS
              MarkerLayer(
                markers: [
                  ..._filteredParkings.map(
                    (parking) => Marker(
                      point: parking.latLng,
                      width: 200,
                      height: 120,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _expandedParking =
                                _expandedParking?.id ==
                                        parking.id
                                    ? null
                                    : parking;
                          });

                          _onParkingTap(parking);
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(
                                  milliseconds: 200),
                              constraints: BoxConstraints(
                                maxWidth:
                                    _expandedParking?.id ==
                                            parking.id
                                        ? 180
                                        : 100,
                              ),
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
                                maxLines:
                                    _expandedParking?.id ==
                                            parking.id
                                        ? 3
                                        : 1,
                                overflow:
                                    TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
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
                  ),

                  /// CURRENT LOCATION DOT
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
                              color: Colors.white, width: 3),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),

          /// LOCATE BUTTON
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
