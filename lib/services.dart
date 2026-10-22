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

      final asOf = _asOf(row) ?? now;
      final laneKey = commercial
          ? 'commercial_vehicle_lanes'
          : 'passenger_vehicle_lanes';

      // Headline wait = the standard (general) lane most travelers queue in, so
      // bridges reflect their real differences. The fastest opt-in lane
      // (Ready / NEXUS / FAST) is surfaced separately as a quick alternative.
      final pax = _standardDelay(row, 'passenger_vehicle_lanes') ??
          _bestLaneDelay(row, 'passenger_vehicle_lanes');
      final veh = _standardDelay(row, 'commercial_vehicle_lanes') ??
          _bestLaneDelay(row, 'commercial_vehicle_lanes');
      final ped = _standardDelay(row, 'pedestrian_lanes') ??
          _bestLaneDelay(row, 'pedestrian_lanes');
      final chosen = commercial ? (veh ?? pax) : (pax ?? veh);
      final closed = _isClosed(row, laneKey);
      // The fastest lane a traveler can opt into (Ready / NEXUS / SENTRI).
      final fastKey = commercial
          ? 'commercial_vehicle_lanes'
          : 'passenger_vehicle_lanes';
      final fastest = _fastLaneDelay(row, fastKey);

      final wait = chosen ?? predictWait(b, now);
      return BridgeReading(
        bridge: b,
        waitMinutes: wait,
        state: stateFor(wait),
        updated: asOf,
        live: chosen != null,
        passengerWait: pax,
        commercialWait: veh,
        pedestrianWait: ped,
        laneStatus: _laneStatus(row, laneKey),
        lanesClosed: closed && chosen == null,
        fastestLaneWait: fastest,
      );
    }).toList();
  }

  /// The standard (general purpose) lane delay for a category, or null.
  int? _standardDelay(Map<String, dynamic> row, String laneKey) {
    final lanes = row[laneKey];
    if (lanes is! Map) return null;
    final standard = lanes['standard_lanes'];
    if (standard is! Map) return null;
    final v = _parseInt(standard['delay_minutes']);
    return v?.clamp(0, 300);
  }

  /// The minimum delay across the opt-in fast lane groups (Ready / NEXUS /
  /// SENTRI / FAST), or null when none report a number.
  int? _fastLaneDelay(Map<String, dynamic> row, String laneKey) {
    final lanes = row[laneKey];
    if (lanes is! Map) return null;
    int? best;
    for (final entry in lanes.entries) {
      final key = '${entry.key}'.toLowerCase();
      if (!(key.contains('nexus') ||
          key.contains('sentri') ||
          key.contains('ready') ||
          key.contains('fast'))) {
        continue;
      }
      final group = entry.value;
      if (group is! Map) continue;
      final v = _parseInt(group['delay_minutes']);
      if (v == null) continue;
      if (best == null || v < best) best = v;
    }
    return best?.clamp(0, 300);
  }

  Map<String, dynamic>? _matchPort(
      List<Map<String, dynamic>> live, String portNumber) {
    for (final row in live) {
      if ('${row['port_number']}'.trim() == portNumber) return row;
    }
    return null;
  }

  /// Real "as-of" time reported by CBP (top-level `date` + `time`).
  DateTime? _asOf(Map<String, dynamic> row) {
    final d = '${row['date'] ?? ''}'.trim();
    final t = '${row['time'] ?? ''}'.trim();
    if (d.isEmpty) return null;
    try {
      final parts = d.split('/');
      if (parts.length != 3) return null;
      final tp = t.split(':');
      return DateTime(
        int.parse(parts[2]),
        int.parse(parts[0]),
        int.parse(parts[1]),
        tp.isNotEmpty ? int.tryParse(tp[0]) ?? 0 : 0,
        tp.length > 1 ? int.tryParse(tp[1]) ?? 0 : 0,
      );
    } catch (_) {
      return null;
    }
  }

  /// The minimum non-null delay across standard/ready/NEXUS/FAST lane groups
  /// for the given lane category. Returns null when the feed has no number.
  int? _bestLaneDelay(Map<String, dynamic> row, String laneKey) {
    final lanes = row[laneKey];
    if (lanes is! Map) return null;
    int? best;
    for (final group in lanes.values) {
      if (group is! Map) continue;
      final v = _parseInt(group['delay_minutes']);
      if (v == null) continue;
      if (best == null || v < best) best = v;
    }
    return best?.clamp(0, 300);
  }

  bool _isClosed(Map<String, dynamic> row, String laneKey) {
    final status = '${row['port_status'] ?? ''}'.toLowerCase();
    if (status.contains('closed')) return true;
    final lanes = row[laneKey];
    if (lanes is Map) {
      for (final group in lanes.values) {
        if (group is Map) {
          final os = '${group['operational_status'] ?? ''}'.toLowerCase();
          if (os.contains('closed')) return true;
        }
      }
    }
    return false;
  }

  String _laneStatus(Map<String, dynamic> row, String laneKey) {
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

  /// Offline fallback: realistic time-of-day model. [Bridge.hourlyPattern] holds
  /// typical *minutes* of wait per hour of day (northbound into the U.S.).
  /// Falls back clearly labeled as an estimate, never presented as live.
  ///
  /// Historical northbound crossing volume varies by day of week: weekday
  /// commuters and shoppers drive the heaviest queues (Mon & Fri peak), while
  /// weekend crossings dip — except Sunday afternoons, when families return
  /// north and waits climb again. These relative factors model that pattern.
  static const List<double> dayFactor = [
    0.92, // Sun — return traffic lifts the usual weekend lull
    1.12, // Mon — start-of-week commuter surge
    1.00, // Tue
    1.00, // Wed
    1.04, // Thu — builds toward the weekend
    1.15, // Fri — heaviest outbound/return mix
    0.85, // Sat — lightest crossing day
  ];

  /// Multiplier (with a small deterministic wobble) for a given weekday.
  static double factorForDay(int weekday, int hour) {
    return dayFactor[weekday % 7];
  }

  /// Estimated wait for a specific day-of-week (DateTime.monday..sunday) and
  /// hour, using the historical day factors. Deterministic, so the same inputs
  /// always yield the same answer.
  static int predictWaitForDay(Bridge b, int weekday, int hour) {
    final base = b.hourlyPattern[hour.clamp(0, 23)];
    final factor = factorForDay(weekday, hour);
    // Deterministic per-(day,hour) variation keeps the table from looking flat.
    final wobble = ((weekday * 5 + hour * 3) % 7) - 3;
    return ((base * factor * b.peakScale) + wobble).round().clamp(2, 120);
  }

  static int predictWait(Bridge b, DateTime t) {
    final base = b.hourlyPattern[t.hour];
    final factor = factorForDay(t.weekday, t.hour);
    // Small deterministic variation by day so consecutive days aren't identical.
    final wobble = ((t.day * 7 + t.hour * 3) % 7) - 3;
    return ((base * factor * b.peakScale) + wobble).round().clamp(2, 120);
  }

  /// The hardest (highest-wait) hour of a given weekday, plus its wait.
  static (int hour, int wait) peakHourForDay(Bridge b, int weekday) {
    var bestHour = 0;
    var bestWait = -1;
    for (var h = 0; h < 24; h++) {
      final w = predictWaitForDay(b, weekday, h);
      if (w > bestWait) {
        bestWait = w;
        bestHour = h;
      }
    }
    return (bestHour, bestWait);
  }

  /// Averages each weekday's full-day wait so users can see which days run
  /// heavier overall (0 = Sunday .. 6 = Saturday).
  static List<int> dailyAverages(Bridge b) {
    return List<int>.generate(7, (d) {
      var sum = 0;
      for (var h = 0; h < 24; h++) {
        sum += predictWaitForDay(b, d, h);
      }
      return (sum / 24).round();
    });
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

  static BridgeForecast bestWindow(Bridge b, DateTime from, {int hours = 24}) {
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

  // Valley center (McAllen) — fallback when no user location is available.
  static const double lat = 26.2034;
  static const double lon = -98.2300;

  Future<WeatherSnapshot?> current({double? atLat, double? atLon}) async {
    final la = atLat ?? lat;
    final lo = atLon ?? lon;
    try {
      final uri = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$la&longitude=$lo'
        '&current=temperature_2m,apparent_temperature,relative_humidity_2m,'
        'wind_speed_10m,weather_code,precipitation'
        '&temperature_unit=fahrenheit'
        '&wind_speed_unit=mph&timezone=America%2FChicago&forecast_days=1',
      );
      final res =
          await _client.get(uri, headers: _headers()).timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) return null;
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final cur = body['current'] as Map<String, dynamic>?;
      if (cur == null) return null;
      final temp = _parseDouble(cur['temperature_2m']) ?? 0;
      final rh = _parseDouble(cur['relative_humidity_2m']) ?? 50;
      final feels = _parseDouble(cur['apparent_temperature']) ?? temp;
      final heatIndex = _computeHeatIndex(temp, rh);
      final code = _parseInt(cur['weather_code']) ?? 0;
      return WeatherSnapshot(
        temperatureF: temp,
        feelsLikeF: feels,
        humidity: rh.round(),
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

  Future<AirQuality?> airQuality({double? atLat, double? atLon}) async {
    final la = atLat ?? lat;
    final lo = atLon ?? lon;
    try {
      final uri = Uri.parse(
        'https://air-quality-api.open-meteo.com/v1/air-quality'
        '?latitude=$la&longitude=$lo&current=us_aqi,pm2_5,pm10'
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

  Future<List<RoadEvent>> closures({double? nearLat, double? nearLon}) async {
    // Prefer a tighter envelope around the user; fall back to the whole Valley.
    final la = nearLat ?? 26.2;
    final lo = nearLon ?? -98.2;
    final xmin = (lo - 0.9).toStringAsFixed(4);
    final ymin = (la - 0.6).toStringAsFixed(4);
    final xmax = (lo + 0.9).toStringAsFixed(4);
    final ymax = (la + 0.6).toStringAsFixed(4);
    try {
      final geom = '{"xmin":$xmin,"ymin":$ymin,"xmax":$xmax,"ymax":$ymax,'
          '"spatialReference":{"wkid":4326}}';
      final uri = Uri.parse(
        '$_base?where=1%3D1&geometry=${Uri.encodeComponent(geom)}'
        '&geometryType=esriGeometryEnvelope&inSR=4326'
        '&spatialRel=esriSpatialRelIntersects'
        '&outFields=condition%2Croute_name%2Croadway%2Cfrom_limit%2Cto_limit%2C'
        'description%2Cdelay_flag%2Cdetour_flag%2Ccounty_num'
        '&returnGeometry=true&outSR=4326&f=json'
        '&resultRecordCount=200',
      );
      final res = await _client
          .get(uri, headers: _headers())
          .timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) return const [];
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final features = body['features'] as List? ?? const [];
      final out = <RoadEvent>[];
      for (final f in features) {
        final m = f as Map;
        final attrs = m['attributes'] as Map<String, dynamic>?;
        if (attrs == null) continue;
        final condition = '${attrs['condition'] ?? ''}'.trim();
        if (condition.isEmpty) continue;

        final route = '${attrs['route_name'] ?? ''}'.trim();
        final roadway = '${attrs['roadway'] ?? ''}'.trim();
        final from = '${attrs['from_limit'] ?? ''}'.trim();
        final to = '${attrs['to_limit'] ?? ''}'.trim();
        final delay = '${attrs['delay_flag'] ?? ''}'.toLowerCase() == 'true';
        final detour = '${attrs['detour_flag'] ?? ''}'.toLowerCase() == 'true';

        final g = m['geometry'] as Map<String, dynamic>?;
        final lat = _parseDouble(g?['y']) ?? _parseDouble(g?['latitude']) ?? 0;
        final lon = _parseDouble(g?['x']) ?? _parseDouble(g?['longitude']) ?? 0;

        out.add(RoadEvent(
          id: 'cd-${attrs['OBJECTID'] ?? out.length}',
          title: condition,
          description: _roadDescription(
            description: '${attrs['description'] ?? ''}',
            roadway: roadway,
            from: from,
            to: to,
            route: route,
            delay: delay,
            detour: detour,
          ),
          route: route,
          severity: _severityFor(condition.toLowerCase()),
          lat: lat,
          lon: lon,
        ));
      }
      // Most disruptive first, then by route for a stable order.
      out.sort((a, b) {
        final s = b.severity.index.compareTo(a.severity.index);
        if (s != 0) return s;
        return a.route.compareTo(b.route);
      });
      return out;
    } catch (_) {
      return const [];
    }
  }

  /// Builds a clean, human-readable description: strips the `<br/>` HTML the
  /// feed embeds and appends the real roadway / from–to limits and flags.
  static String _roadDescription({
    required String description,
    required String roadway,
    required String from,
    required String to,
    required String route,
    required bool delay,
    required bool detour,
  }) {
    final parts = <String>[];
    final cleaned = description
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll('&amp;', '&')
        .replaceAll('&nbsp;', ' ')
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .split('\n')
        .map((l) => l.replaceAll(RegExp(r'^[\s\-•]+'), '').trim())
        .where((l) => l.isNotEmpty)
        .toList();
    parts.addAll(cleaned);

    if (from.isNotEmpty || to.isNotEmpty) {
      final where = roadway.isNotEmpty ? '$roadway ($route)' : route;
      if (from.isNotEmpty && to.isNotEmpty && from != to) {
        parts.add('From $from to $to${where.isEmpty ? '' : ' · $where'}');
      } else {
        final loc = from.isNotEmpty ? from : to;
        parts.add('$loc${where.isEmpty ? '' : ' · $where'}');
      }
    } else if (roadway.isNotEmpty) {
      parts.add('$roadway${route.isEmpty ? '' : ' ($route)'}');
    }

    if (detour) parts.add('Detour available');
    if (delay) parts.add('Expect delays');
    return parts.join('\n');
  }

  static RoadSeverity _severityFor(String condition) {
    if (condition.contains('clos')) return RoadSeverity.closure;
    if (condition.contains('construction') ||
        condition.contains('road work') ||
        condition.contains('maintenance') ||
        condition.contains('detour')) {
      return RoadSeverity.major;
    }
    if (condition.contains('ice') ||
        condition.contains('snow') ||
        condition.contains('flood') ||
        condition.contains('water') ||
        condition.contains('high wind') ||
        condition.contains('fog')) {
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
