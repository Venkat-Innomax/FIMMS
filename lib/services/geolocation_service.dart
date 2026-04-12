import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class GpsFix {
  final LatLng position;
  final double accuracyMeters;
  final bool simulated;

  const GpsFix({
    required this.position,
    required this.accuracyMeters,
    this.simulated = false,
  });
}

/// Thin wrapper around `geolocator` with a graceful simulated fallback.
/// Callers can assume a non-null fix so the form flow is not blocked when
/// permissions are denied or the web browser has no geolocation.
class GeolocationService {
  Future<GpsFix> currentFix({LatLng? fallback}) async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final request = await Geolocator.requestPermission();
        if (request == LocationPermission.denied ||
            request == LocationPermission.deniedForever) {
          return _simulated(fallback);
        }
      } else if (permission == LocationPermission.deniedForever) {
        return _simulated(fallback);
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );
      return GpsFix(
        position: LatLng(pos.latitude, pos.longitude),
        accuracyMeters: pos.accuracy,
      );
    } catch (_) {
      return _simulated(fallback);
    }
  }

  GpsFix _simulated(LatLng? fallback) {
    final base = fallback ?? const LatLng(17.5124, 78.8886);
    return GpsFix(
      position: base,
      accuracyMeters: 12.0,
      simulated: true,
    );
  }

  /// Haversine great-circle distance between two lat/lng points, in metres.
  /// Small enough that we don't need to pull in a dependency.
  double distanceMeters(LatLng a, LatLng b) {
    const distance = Distance();
    return distance.as(LengthUnit.Meter, a, b);
  }
}

final geolocationServiceProvider =
    Provider<GeolocationService>((ref) => GeolocationService());
