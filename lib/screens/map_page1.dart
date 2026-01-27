//EXAMPLE MAP PAGE !
// ANDROID – Live location update every 5 seconds
// Blue transparent accuracy circle around current location
// flutter_map: ^6.x
// geolocator: ^10.x

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class ParkingLocation {
  final String id;
  final String name;
  final LatLng position;

  ParkingLocation({
    required this.id,
    required this.name,
    required this.position,
  });
}

final List<ParkingLocation> parkingLocations = [
  ParkingLocation(
    id: 'P1',
    name: 'Palarivattom Parking',
    position: LatLng(10.001366, 76.310081),
  ),
  ParkingLocation(
    id: 'P2',
    name: 'Aalinchuvadu Parking',
    position: LatLng(10.003261, 76.316005),
  ),
  ParkingLocation(
    id: 'P3',
    name: 'Holiday Inn Parking',
    position: LatLng(9.990172, 76.315793),
  ),
];

class MapScreen1 extends StatefulWidget {
  const MapScreen1({super.key});

  @override
  State<MapScreen1> createState() => _MapScreen1State();
}

class _MapScreen1State extends State<MapScreen1> {
  late final MapController _mapController;
  LatLng? _currentLocation;
  StreamSubscription<Position>? _positionStream;
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _startLiveLocation();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  ///LIVE LOCATION EVERY 5 SECONDS
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
            timeLimit: null,
          ),
        ).listen((position) {
          final latLng = LatLng(position.latitude, position.longitude);

          setState(() => _currentLocation = latLng);

          if (_mapReady) {
            _mapController.move(latLng, _mapController.camera.zoom);
          }
        });
  }

  void _goToCurrentLocation() {
    if (_currentLocation != null && _mapReady) {
      _mapController.move(_currentLocation!, 16);
    }
  }

  void _onParkingTap(ParkingLocation parking) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              parking.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text("Parking ID: ${parking.id}"),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Book Parking"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 5.0,
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          height: kBottomNavigationBarHeight,
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              IconButton(
                icon: const Icon(Icons.home),
                onPressed: () {
                  setState(() {});
                },
              ),
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  setState(() {});
                },
              ),
              IconButton(
                icon: const Icon(Icons.account_circle_outlined),
                onPressed: () {
                  setState(() {});
                },
              ),
            ],
          ),
        ),
      ),
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
              initialZoom: 15,
              onMapReady: () {
                _mapReady = true;
                if (_currentLocation != null) {
                  _mapController.move(_currentLocation!, 16);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.parkingmanager.app',
              ),

              /// 🔵 BLUE TRANSPARENT CIRCLE (Accuracy)
              if (_currentLocation != null)
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: _currentLocation!,
                      radius: 60, // meters
                      useRadiusInMeter: true,
                      color: Colors.blue.withOpacity(0.15),
                      borderColor: Colors.blue.withOpacity(0.4),
                      borderStrokeWidth: 2,
                    ),
                  ],
                ),

              /// MARKERS
              MarkerLayer(
                markers: [
                  /// Parking markers
                  ...parkingLocations.map(
                    (parking) => Marker(
                      point: parking.position,
                      width: 120,
                      height: 80,
                      child: GestureDetector(
                        onTap: () => _onParkingTap(parking),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: Text(
                                parking.name,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
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
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),

          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              backgroundColor: Colors.white,
              onPressed: _goToCurrentLocation,
              child: const Icon(Icons.my_location, color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }
}
