import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Resolves the device location, returning null when services or permission
/// are unavailable. Calls [onLastKnown] first with the cached position (fast)
/// before waiting on a fresh fix, which can be slow on Android indoors.
Future<LatLng?> getDeviceLocation({void Function(LatLng)? onLastKnown}) async {
  try {
    if (!await Geolocator.isLocationServiceEnabled()) return null;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    LatLng? lastKnown;
    try {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) {
        lastKnown = LatLng(last.latitude, last.longitude);
        onLastKnown?.call(lastKnown);
      }
    } catch (_) {}

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return LatLng(position.latitude, position.longitude);
    } catch (_) {
      return lastKnown;
    }
  } catch (_) {
    return null;
  }
}
