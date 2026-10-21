import 'dart:convert';

import 'package:http/http.dart' as http;

import 'local_data.dart';
import 'models.dart';

// ---------------------------------------------------------------------------
// Shared helpers
// ---------------------------------------------------------------------------

/// Small wrapper so every call carries a browser-friendly Origin (CBP and
/// Open-Meteo only emit CORS headers when an Origin is present).
Map<String, String> _headers() => const {
      'Accept': 'application/json',
      'Origin': 'https://dajinbuu.github.io',
    };

int? _parseInt(Object? v) {
  if (v == null) return null;
  if (v is int) return v;
  final t = v.toString().trim();
  if (t.isEmpty || t == 'N/A' || t == 'Update Pending') return null;
  return int.tryParse(RegExp(r'\d+').firstMatch(t)?.group(0) ?? '');
}

double? _parseDouble(Object? v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  final t = v.toString().trim();
  if (t.isEmpty || t == 'N/A') return null;
  return double.tryParse(t);
}

// ---------------------------------------------------------------------------
// Border wait times — CBP Border Wait Times (live)
// ---------------------------------------------------------------------------

/// Live crossing waits from the official CBP Border Wait Times feed
/// (https://bwt.cbp.gov/api/bwtnew). Matches RGV ports by `port_number`.
///
/// If the live feed is unreachable, [currentReadings] falls back to a clearly
/// flagged time-of-day estimate so the UI never goes blank.
class BorderService {
  final http.Client _client;
  BorderService({http.Client? client}) : _client = client ?? http.Client();

  static const _cbpUrl = 'https://bwt.cbp.gov/api/bwtnew';

  Future<List<BridgeReading>> currentReadings({bool commercial = false}) async {
    List<Map<String, dynamic>>? live;
    try {
      final res = await _client
          .get(Uri.parse(_cbpUrl), headers: _headers())
          .timeout(const Duration(seconds: 12));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body is List) {
          live = body.cast<Map<String, dynamic>>();
        } else if (body is Map && body['bridges'] is List) {
          live = (body['bridges'] as List).cast<Map<String, dynamic>>();
        }
      }
    } catch (_) {}

    final now = DateTime.now();
    return kBridges.map((b) {
      final row = live == null ? null : _matchPort(live, b.portNumber);
      if (row == null) {
        final est = predictWait(b, now);
        return BridgeReading(
          bridge: b,
          waitMinutes: est,
          state: stateFor(est),
          updated: now,
          live: false,
        );
      }
      final pax = _laneDelay(row, 'passenger_vehicle_lanes', commercial: false);
      final veh =
          _laneDelay(row, 'commercial_vehicle_lanes', commercial: true);
      final ped = _laneDelay(row, 'pedestrian_lanes', commercial: false);
      final chosen = commercial
          ? (veh ?? pax)
          : (pax ?? veh);
      final wait = chosen ?? predictWait(b, now);
      return BridgeReading(
        bridge: b,
        waitMinutes: wait,
        state: stateFor(wait),
        updated: now,
        live: chosen != null,
        passengerWait: pax,
        commercialWait: veh,
        pedestrianWait: ped,
        laneStatus: _laneStatus(row, commercial),
      );
    }).toList();
  }

  Map<String, dynamic>? _matchPort(
      List<Map<String, dynamic>> live, String portNumber) {
    for (final row in live) {
      if ('${row['port_number']}'.trim() == portNumber) return row;
    }
    return null;
  }

  int? _laneDelay(Map<String, dynamic> row, String laneKey,
      {required bool commercial}) {
    final lanes = row[laneKey];
    if (lanes is! Map) return null;
    final standard = lanes['standard_lanes'];
    if (standard is Map) {
      final v = _parseInt(standard['delay_minutes']);
      if (v != null) return v.clamp(0, 240);
    }
    return null;
  }

  String _laneStatus(Map<String, dynamic> row, bool commercial) {
    final laneKey =
        commercial ? 'commercial_vehicle_lanes' : 'passenger_vehicle_lanes';
    final lanes = row[laneKey];
    if (lanes is Map) {
      final standard = lanes['standard_lanes'];
      if (standard is Map) {
        final status = standard['operational_status'];
        if (status != null && '$status'.isNotEmpty) return '$status';
      }
    }
    return '';
  }

  /// Offline fallback: historical time-of-day model (clearly labeled as an
  /// estimate, never presented as live).
  static int predictWait(Bridge b, DateTime t) {
    final pattern = b.hourlyPattern[t.hour];
    final baseline = 350 + pattern * 3 * 12;
    final jitter = ((t.day + t.hour) % 3 - 1) * 3;
    final seconds = baseline + jitter * 6;
    return (seconds / 60).round().clamp(3, 90);
  }

  static List<BridgeForecast> forecast(Bridge b, DateTime from,
      {int hours = 8}) {
    final out = <BridgeForecast>[];
    for (var i = 0; i <= hours; i++) {
      final t = from.add(Duration(hours: i));
      out.add(BridgeForecast(t.hour, predictWait(b, t)));
    }
    return out;
  }

  static BridgeForecast bestWindow(Bridge b, DateTime from, {int hours = 10}) {
    final f = forecast(b, from, hours: hours);
    return f.reduce((a, c) => c.wait < a.wait ? c : a);
  }

  static BridgeState stateFor(int wait) {
    if (wait >= 35) return BridgeState.heavy;
    if (wait >= 15) return BridgeState.slow;
    return BridgeState.moving;
  }
}

// ---------------------------------------------------------------------------
// Weather, alerts, air quality — NWS + Open-Meteo (live)
// ---------------------------------------------------------------------------

class WeatherService {
  final http.Client _client;
  WeatherService({http.Client? client}) : _client = client ?? http.Client();

  // Valley center (McAllen) — used for current conditions / AQI.
  static const double lat = 26.2034;
  static const double lon = -98.2300;

  Future<WeatherSnapshot?> current() async {
    try {
      final uri = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon'
        '&current=temperature_2m,apparent_temperature,relative_humidity_2m,'
        'wind_speed_10m,weather_code,precipitation'
        '&hourly=apparent_temperature&temperature_unit=fahrenheit'
        '&wind_speed_unit=mph&timezone=America%2FChicago&forecast_days=1',
      );
      final res =
          await _client.get(uri, headers: _headers()).timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) return null;
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final cur = body['current'] as Map<String, dynamic>?;
      if (cur == null) return null;
      final temp = _parseDouble(cur['temperature_2m']) ?? 0;
      final feels = _parseDouble(cur['apparent_temperature']) ?? temp;
      final heatIndex = _computeHeatIndex(
        temp,
        _parseDouble(cur['relative_humidity_2m']) ?? 50,
      );
      final code = _parseInt(cur['weather_code']) ?? 0;
      return WeatherSnapshot(
        temperatureF: temp,
        feelsLikeF: feels,
        humidity: (_parseDouble(cur['relative_humidity_2m']) ?? 50).round(),
        windMph: _parseDouble(cur['wind_speed_10m']) ?? 0,
        condition: conditionForCode(code),
        weatherCode: code,
        heatIndexF: heatIndex,
        updated: DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }

  Future<AirQuality?> airQuality() async {
    try {
      final uri = Uri.parse(
        'https://air-quality-api.open-meteo.com/v1/air-quality'
        '?latitude=$lat&longitude=$lon&current=us_aqi,pm2_5,pm10'
        '&timezone=America%2FChicago',
      );
      final res =
          await _client.get(uri, headers: _headers()).timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) return null;
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final cur = body['current'] as Map<String, dynamic>?;
      if (cur == null) return null;
      return AirQuality(
        aqi: (_parseDouble(cur['us_aqi']) ?? 0).round(),
        pm25: _parseDouble(cur['pm2_5']) ?? 0,
        pm10: _parseDouble(cur['pm10']) ?? 0,
        updated: DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }

  /// Active NWS alerts for the RGV zone set (Hidalgo/Starr/Cameron/Willacy).
  Future<List<WeatherAlert>> alerts() async {
    const zones = ['TXZ252', 'TXZ253', 'TXZ254', 'TXZ255'];
    final out = <WeatherAlert>[];
    for (final z in zones) {
      try {
        final uri = Uri.parse('https://api.weather.gov/alerts/active?zone=$z');
        final res = await _client
            .get(uri, headers: _headers())
            .timeout(const Duration(seconds: 12));
        if (res.statusCode != 200) continue;
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final features = body['features'] as List? ?? const [];
        for (final f in features) {
          final props = (f as Map)['properties'] as Map<String, dynamic>?;
          if (props == null) continue;
          out.add(WeatherAlert(
            event: '${props['event'] ?? ''}',
            severity: '${props['severity'] ?? 'Unknown'}',
            headline: '${props['headline'] ?? ''}',
            area: '${props['areaDesc'] ?? ''}',
            description: '${props['description'] ?? ''}',
          ));
        }
      } catch (_) {}
    }
    // De-duplicate identical headlines (zones overlap).
    final seen = <String>{};
    return out.where((a) => seen.add(a.headline)).toList();
  }

  static String conditionForCode(int code) {
    if (code == 0) return 'Clear';
    if (code <= 3) return 'Partly cloudy';
    if (code == 45 || code == 48) return 'Fog';
    if (code >= 51 && code <= 57) return 'Drizzle';
    if (code >= 61 && code <= 67) return 'Rain';
    if (code >= 71 && code <= 77) return 'Snow';
    if (code >= 80 && code <= 82) return 'Showers';
    if (code >= 95) return 'Thunderstorm';
    return 'Cloudy';
  }

  /// Rothfusz heat index (NWS), returns null when it doesn't apply (<80F).
  static double? _computeHeatIndex(double tF, double rh) {
    if (tF < 80) return null;
    final t = tF;
    final r = rh;
    final hi = -42.379 +
        2.04901523 * t +
        10.14333127 * r -
        0.22475541 * t * r -
        0.00683783 * t * t -
        0.05481717 * r * r +
        0.00122874 * t * t * r +
        0.00085282 * t * r * r -
        0.00000199 * t * t * r * r;
    return double.parse(hi.toStringAsFixed(1));
  }
}

// ---------------------------------------------------------------------------
// Road conditions — TxDOT DriveTexas (ArcGIS mirror, live closures)
// ---------------------------------------------------------------------------

class RoadService {
  final http.Client _client;
  RoadService({http.Client? client}) : _client = client ?? http.Client();

  // DriveTexas public ArcGIS mirror (keyless), RGV envelope.
  static const _base =
      'https://services9.arcgis.com/EzaDBSfUmxFzUwnI/arcgis/rest/services/'
      'DriveTexas_Conditions_Points/FeatureServer/0/query';

  Future<List<RoadEvent>> closures() async {
    try {
      final uri = Uri.parse(
        '$_base?where=1%3D1&geometry=%7B%22xmin%22%3A-99.2%2C%22ymin%22%3A25.8'
        '%2C%22xmax%22%3A-97.1%2C%22ymax%22%3A26.6%2C%22spatialReference%22'
        '%3A%7B%22wkid%22%3A4326%7D%7D&geometryType=esriGeometryEnvelope'
        '&inSR=4326&spatialRel=esriSpatialRelIntersects'
        '&outFields=condition%2Croute_name%2Cfrom_limit%2Cto_limit%2C'
        'description%2Ccounty_num&returnGeometry=false&f=json&resultRecordCount=200',
      );
      final res =
          await _client.get(uri, headers: _headers()).timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) return const [];
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final features = body['features'] as List? ?? const [];
      final out = <RoadEvent>[];
      for (final f in features) {
        final attrs = (f as Map)['attributes'] as Map<String, dynamic>?;
        if (attrs == null) continue;
        final cond = '${attrs['condition'] ?? ''}'.toLowerCase();
        final desc = '${attrs['description'] ?? ''}';
        out.add(RoadEvent(
          id: '$countySafe${out.length}-${attrs['route_name']}',
          title: '${attrs['condition'] ?? 'Condition'}'.trim(),
          description: desc.trim().isEmpty
              ? '${attrs['from_limit'] ?? ''} → ${attrs['to_limit'] ?? ''}'
              : desc.trim(),
          route: '${attrs['route_name'] ?? ''}'.trim(),
          severity: _severityFor(cond),
          lat: 0,
          lon: 0,
        ));
      }
      return out;
    } catch (_) {
      return const [];
    }
  }

  static const countySafe = 'cd';

  static RoadSeverity _severityFor(String condition) {
    if (condition.contains('clos') || condition.contains('closed')) {
      return RoadSeverity.closure;
    }
    if (condition.contains('construction') ||
        condition.contains('road work') ||
        condition.contains('maintenance')) {
      return RoadSeverity.major;
    }
    if (condition.contains('ice') ||
        condition.contains('flood') ||
        condition.contains('water')) {
      return RoadSeverity.minor;
    }
    return RoadSeverity.info;
  }
}

// ---------------------------------------------------------------------------
// Medical term decoder
// ---------------------------------------------------------------------------

class TermDecoder {
  final String? apiKey;
  TermDecoder({this.apiKey});

  MedicalTerm? lookup(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return null;
    for (final t in kMedicalTerms) {
      if (t.term.toLowerCase() == q) return t;
    }
    for (final t in kMedicalTerms) {
      if (t.term.toLowerCase().contains(q) ||
          q.contains(t.term.toLowerCase())) {
        return t;
      }
    }
    return null;
  }

  Future<String?> explain(String query, {required bool es}) async {
    final hit = lookup(query);
    if (hit != null) return es ? hit.plainEs : hit.plainEn;
    return null;
  }
}
