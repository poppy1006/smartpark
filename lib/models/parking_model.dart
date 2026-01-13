import 'package:latlong2/latlong.dart';

class ParkingModel {
  final String id;
  final String name;
  final double latitude;
  final double longitude;

  ParkingModel({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  /// Convert Supabase row → Dart object
  factory ParkingModel.fromMap(Map<String, dynamic> map) {
    return ParkingModel(
      id: map['id'],
      name: map['name'],
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
    );
  }

  /// Helper for map usage
  LatLng get latLng => LatLng(latitude, longitude);
}
