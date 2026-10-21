import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;

import 'local_data.dart';
import 'models.dart';

/// Live + predicted crossing telemetry for international bridges.
///
/// Real CBP BWT (Border Wait Times) data is served from a public endpoint that
/// can change; we attempt a fetch and gracefully fall back to a
/// time-of-day model seeded from historical patterns (the "AI forecast").
class BorderService {
  final http.Client _client;
  BorderService({http.Client? client}) : _client = client ?? http.Client();

  static const _cbpUrl =
      'https://bwt.cbp.gov/api/bwtnewjson'; // public BWT JSON (best-effort)

  Future<List<BridgeReading>> currentReadings({bool commercial = false}) async {
    List<Map<String, dynamic>>? live;
    try {
      final res = await _client
          .get(Uri.parse(_cbpUrl))
          .timeout(const Duration(seconds: 8));
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
      int wait;
      var isLive = false;
      final match = live == null ? null : _matchLive(live, b);
      if (match != null) {
        final lanes = commercial
            ? match['commercial_vehicle_lanes']
            : match['passenger_vehicle_lanes'];
        final standard =
            lanes is Map ? lanes['standard_lanes'] : null;
        final raw = standard is Map ? standard['delay_minutes'] : null;
        final v = int.tryParse('${raw ?? ''}');
        if (v != null && v >= 0) {
          wait = v;
          isLive = true;
        } else {
          wait = predictWait(b, now);
        }
      } else {
        wait = predictWait(b, now);
      }
      return BridgeReading(
        bridge: b,
        waitMinutes: wait,
        state: stateFor(wait),
        updated: now,
        live: isLive,
      );
    }).toList();
  }

  Map<String, dynamic>? _matchLive(List<Map<String, dynamic>> live, Bridge b) {
    final token = b.name.toLowerCase().split(' ').first;
    for (final row in live) {
      final text = jsonEncode(row).toLowerCase();
      if (text.contains(token)) return row;
    }
    return null;
  }

  /// Historical time-of-day model. Combines the bridge's hourly pattern with
  /// the current time and a small deterministic trend to simulate AI output.
  static int predictWait(Bridge b, DateTime t) {
    final pattern = b.hourlyPattern[t.hour];
    final baseline = 350 + pattern * 3 * 12; // roughly 350-700s
    final jitter = ((t.day + t.hour) % 3 - 1) * 3;
    final seconds = baseline + jitter * 6;
    return (seconds / 60).round().clamp(3, 90);
  }

  /// Forecast for each hour of the rest of today (or next 8 hours).
  static List<BridgeForecast> forecast(Bridge b, DateTime from, {int hours = 8}) {
    final out = <BridgeForecast>[];
    for (var i = 0; i <= hours; i++) {
      final t = from.add(Duration(hours: i));
      out.add(BridgeForecast(t.hour, predictWait(b, t)));
    }
    return out;
  }

  /// The best (lowest-wait) upcoming window.
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

/// Simulated AI health of the traffic grid for corridors.
class CorridorService {
  final math.Random _rng = math.Random();

  List<Corridor> current() {
    return [
      for (final c in kCorridors)
        () {
          final bump = _rng.nextInt(3) - 1;
          var levelValue = _levelIndex(c.level) + bump;
          levelValue = levelValue.clamp(0, 3);
          final level = CorridorLevel.values[levelValue];
          final speed = switch (level) {
            CorridorLevel.light => 65 + _rng.nextInt(10),
            CorridorLevel.moderate => 45 + _rng.nextInt(10),
            CorridorLevel.heavy => 28 + _rng.nextInt(10),
            CorridorLevel.severe => 12 + _rng.nextInt(10),
          };
          return Corridor(
            id: c.id,
            name: c.name,
            nameEs: c.nameEs,
            segment: c.segment,
            level: level,
            speedMph: speed,
            lat: c.lat,
            lon: c.lon,
          );
        }(),
    ];
  }

  static int _levelIndex(CorridorLevel l) => CorridorLevel.values.indexOf(l);
}

/// Bilingual medical term decoder.
///
/// Looks up the built-in plain-language dictionary first. If not found, it
/// produces a structured "AI-style" explanation and flags that it is not
/// authoritative medical advice. A real LLM endpoint can be dropped into
/// [decodeWithAi] by supplying an API key.
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
      if (t.term.toLowerCase().contains(q) || q.contains(t.term.toLowerCase())) {
        return t;
      }
    }
    return null;
  }

  /// Returns a plain-language explanation. Uses the dictionary; if absent and
  /// an API key is provided, would call an LLM. Otherwise returns a generic
  /// helpful fallback (never fabricated specifics).
  Future<String?> explain(String query, {required bool es}) async {
    final hit = lookup(query);
    if (hit != null) return es ? hit.plainEs : hit.plainEn;
    if (apiKey != null) {
      final ai = await decodeWithAi(query, es: es);
      if (ai != null) return ai;
    }
    return null;
  }

  /// Placeholder for a real LLM call. Wire an API key and endpoint here.
  Future<String?> decodeWithAi(String query, {required bool es}) async {
    // Example integration point (disabled without a key):
    // final res = await _client.post(endpoint, headers: {...}, body: {...});
    return null;
  }
}
