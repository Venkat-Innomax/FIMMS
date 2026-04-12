import 'package:latlong2/latlong.dart';

class Mandal {
  final String id;
  final String name;
  final LatLng center;

  const Mandal({required this.id, required this.name, required this.center});

  factory Mandal.fromJson(Map<String, dynamic> json) => Mandal(
        id: json['id'] as String,
        name: json['name'] as String,
        center: LatLng(
          (json['lat'] as num).toDouble(),
          (json['lng'] as num).toDouble(),
        ),
      );
}
