// import 'package:latlong2/latlong.dart';

// class ParkingModel {
//   final String id;
//   final String name;
//   final double latitude;
//   final double longitude;

//   ParkingModel({
//     required this.id,
//     required this.name,
//     required this.latitude,
//     required this.longitude,
//   });

//   /// Convert Supabase row → Dart object
//   factory ParkingModel.fromMap(Map<String, dynamic> map) {
//     return ParkingModel(
//       id: map['id'],
//       name: map['name'],
//       latitude: (map['latitude'] as num).toDouble(),
//       longitude: (map['longitude'] as num).toDouble(),
//     );
//   }

//   /// Helper for map usage
//   LatLng get latLng => LatLng(latitude, longitude);
// }


import 'package:latlong2/latlong.dart';

class ParkingModel {
  final String id;
  final String name;
  final double latitude;
  final double longitude;

  final int totalSlots;
  final int availableSlots;
  final double hourlyPrice;

  ParkingModel({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.totalSlots,
    required this.availableSlots,
    required this.hourlyPrice,
  });

  factory ParkingModel.fromMap(Map<String, dynamic> map) {
    return ParkingModel(
      id: map['id'].toString(),
      name: map['name'] ?? '',
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      totalSlots: map['total_slots'] ?? 0,
      availableSlots: map['available_slots'] ?? 0,
      hourlyPrice:
          map['hourly_price'] == null
              ? 0
              : (map['hourly_price'] as num).toDouble(),
    );
  }

  LatLng get latLng => LatLng(latitude, longitude);
}
