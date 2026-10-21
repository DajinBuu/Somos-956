import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

enum LocStatus { unknown, granted, denied, deniedForever, serviceOff, unsupported }

/// App-wide shared instance so every tab sees the same cached position and we
/// only trigger a single permission prompt.
final LocationService locationService = LocationService();

/// Single, cached source of the user's location plus distance & directions
/// helpers. The position is fetched lazily and shared across tabs so we only
/// prompt the browser/OS once.
class LocationService {
  Position? _cached;
  LocStatus _status = LocStatus.unknown;
  Future<Position?>? _inFlight;

  // A location the user dropped on the map, used in place of (or before) GPS.
  double? _manualLat;
  double? _manualLon;
  String? _manualLabel;

  Position? get position => _cached;
  LocStatus get status => _status;
  bool get hasFix => _cached != null || _manualLat != null;
  bool get isManual => _manualLat != null;
  String? get manualLabel => _manualLabel;

  static const double _valleyLat = 26.2034;
  static const double _valleyLon = -98.2300;

  /// Plaza of the Americas (McAllen) is used as the "Valley" reference when we
  /// have no fix, so distance labels stay meaningful instead of blank.
  static bool isValleyCentered(Position? p) => p == null;

  Future<Position?> ensure() {
    if (_cached != null) return Future<Position?>.value(_cached);
    // A manual pin is a deliberate choice, so don't override it with GPS.
    if (_manualLat != null) return Future<Position?>.value(null);
    // Share a single in-flight request so concurrent tabs only prompt once.
    return _inFlight ??= _resolve();
  }

  /// Sets a user-chosen location from the map picker.
  void setManual(double lat, double lon, {String? label}) {
    _manualLat = lat;
    _manualLon = lon;
    _manualLabel = label;
    _status = LocStatus.granted;
  }

  /// Clears any manual pin so GPS / the Valley default is used again.
  void clearManual() {
    _manualLat = null;
    _manualLon = null;
    _manualLabel = null;
  }

  Future<Position?> _resolve() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _status = LocStatus.serviceOff;
        return null;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied) {
        _status = LocStatus.denied;
        return null;
      }
      if (perm == LocationPermission.deniedForever) {
        _status = LocStatus.deniedForever;
        return null;
      }
      _cached = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 12),
        ),
      );
      _status = LocStatus.granted;
      return _cached;
    } catch (_) {
      // Web browsers without geolocation, or a timeout, land here.
      _status = _status == LocStatus.unknown ? LocStatus.unsupported : _status;
      return null;
    } finally {
      _inFlight = null;
    }
  }

  /// Reference point for distances: manual pin, else user GPS fix, else the
  /// Valley center.
  (double lat, double lon) get reference {
    if (_manualLat != null) return (_manualLat!, _manualLon!);
    if (_cached != null) return (_cached!.latitude, _cached!.longitude);
    return (_valleyLat, _valleyLon);
  }

  /// Origin for directions as a `(lat, lon)` record, or null when the Valley
  /// default would be misleading.
  (double, double)? get origin =>
      hasFix ? reference : null;

  /// Great-circle distance in miles between two coordinates.
  static double miles(double lat1, double lon1, double lat2, double lon2) {
    const r = 3958.8;
    double rad(double d) => d * math.pi / 180;
    final dLat = rad(lat2 - lat1);
    final dLon = rad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(rad(lat1)) *
            math.cos(rad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  /// Distance from the user (or Valley center) to a point, in miles.
  double distanceTo(double lat, double lon) {
    final (rlat, rlon) = reference;
    return miles(rlat, rlon, lat, lon);
  }

  /// Opens turn-by-turn directions to [lat],[lon]. Uses the user's position as
  /// the origin when known so the route is actually from where they are.
  static Future<bool> directions({
    required double lat,
    required double lon,
    String? label,
    (double, double)? origin,
  }) async {
    final dest = '$lat,$lon';
    final originParam =
        origin == null ? '' : '&origin=${origin.$1},${origin.$2}';
    // Universal Google Maps link works in browsers and the mobile apps.
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1$originParam'
      '&destination=$dest&travelmode=driving',
    );
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      try {
        return await launchUrl(uri);
      } catch (_) {
        return false;
      }
    }
  }

  /// Opens a location in Google Maps (no directions).
  static Future<bool> mapTo(double lat, double lon) async {
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lon');
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  /// Opens a phone dialer.
  static Future<bool> call(String phone) async {
    final digits = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (digits.isEmpty) return false;
    try {
      return await launchUrl(Uri.parse('tel:$digits'));
    } catch (_) {
      return false;
    }
  }
}
