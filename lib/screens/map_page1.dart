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
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _initLocation();
  }

  Future<void> _initLocation() async {
    final location = await _getCurrentLocation();
    if (location == null) return;

    setState(() => _currentLocation = location);

    if (_mapReady) {
      _mapController.move(_currentLocation!, 16);
    }
  }

  Future<LatLng?> _getCurrentLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      await Geolocator.openLocationSettings();
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    return LatLng(position.latitude, position.longitude);
  }

  void _goToCurrentLocation() {
    if (_currentLocation != null && _mapReady) {
      _mapController.move(_currentLocation!, 16);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Current location not available')),
      );
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
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text("Parking ID: ${parking.id}"),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Navigate to booking page later
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
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: const Text("Nearby Parkings"),
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
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.parkingmanager.app',
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
                            /// Label above marker
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
                                  )
                                ],
                              ),
                              child: Text(
                                parking.name,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 4),

                            /// Marker icon
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

                  /// Current location marker
                  if (_currentLocation != null)
                    Marker(
                      point: _currentLocation!,
                      width: 22,
                      height: 22,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: Colors.white, width: 3),
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
