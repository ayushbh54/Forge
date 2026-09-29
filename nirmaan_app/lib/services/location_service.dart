import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  Future<bool> checkPermission() async {
    var status = await Permission.location.status;
    if (status.isDenied) {
      status = await Permission.location.request();
    }
    return status.isGranted;
  }

  Future<Position?> getCurrentPosition() async {
    bool hasPermission = await checkPermission();
    if (!hasPermission) {
      throw Exception('Location permission denied');
    }
    
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled');
    }
    
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  double getDistanceToSite(double lat, double lng, double siteLat, double siteLng) {
    return Geolocator.distanceBetween(lat, lng, siteLat, siteLng);
  }

  Map<String, dynamic> isWithinGeofence(
      double currentLat, double currentLng, double siteLat, double siteLng, double radiusMeters) {
    double distance = getDistanceToSite(currentLat, currentLng, siteLat, siteLng);
    return {
      'isWithin': distance <= radiusMeters,
      'distance': distance,
    };
  }
}
