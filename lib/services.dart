import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;

import 'local_data.dart';
import 'models.dart';

class NwsService {
  static const _headers = {'User-Agent': 'RGV-Ready (Congressional App Challenge demo)'};
  final http.Client _client;

  NwsService({http.Client? client}) : _client = client ?? http.Client();

  Future<HeatReading> fetchHeat() async {
    try {
      final res = await _client
          .get(Uri.parse('https://api.weather.gov/stations/KBRO/observations/latest'),
              headers: _headers)
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final p = jsonDecode(res.body)['properties'] as Map<String, dynamic>;
        final tempC = p['temperature']?['value'] as num?;
        final dewC = p['dewpoint']?['value'] as num?;
        final rh = p['relativeHumidity']?['value'] as num?;
        if (tempC != null) {
          final tempF = tempC * 9 / 5 + 32;
          double? hi;
          double? humidity = rh?.toDouble();
          if (dewC != null) {
            final dewF = dewC * 9 / 5 + 32;
            humidity = humidity ?? _rhFromDewpoint(tempF, dewF);
          }
          if (humidity != null) {
            hi = heatIndexF(tempF, humidity);
          }
          return HeatReading(
            tempF: tempF,
            humidity: humidity,
            heatIndexF: hi,
            condition: (p['textDescription'] as String?)?.isNotEmpty == true
                ? p['textDescription'] as String
                : 'KBRO station observation',
            live: true,
            observed: DateTime.tryParse(p['timestamp'] as String? ?? '') ?? DateTime.now(),
          );
        }
      }
    } catch (_) {}

    try {
      final pts = await _client
          .get(Uri.parse('https://api.weather.gov/points/$kBrownsvilleLat,$kBrownsvilleLon'),
              headers: _headers)
          .timeout(const Duration(seconds: 10));
      if (pts.statusCode == 200) {
        final hourlyUrl =
            jsonDecode(pts.body)['properties']['forecastHourly'] as String;
        final res = await _client
            .get(Uri.parse(hourlyUrl), headers: _headers)
            .timeout(const Duration(seconds: 10));
        if (res.statusCode == 200) {
          final periods =
              (jsonDecode(res.body)['properties']['periods'] as List).take(3);
          for (final raw in periods) {
            final t = raw['temperature'] as num?;
            if (t == null) continue;
            final hiRaw = raw['heatIndex'] as num?;
            return HeatReading(
              tempF: t.toDouble(),
              heatIndexF: hiRaw?.toDouble(),
              condition: (raw['shortForecast'] as String?) ?? '',
              live: true,
              observed: DateTime.now(),
            );
          }
        }
      }
    } catch (_) {}

    return HeatReading(
      tempF: 101,
      humidity: 41,
      heatIndexF: 108,
      condition: 'Sunny / Soleado',
      live: false,
      observed: DateTime.now(),
    );
  }

  Future<List<NwsAlert>> fetchAlerts() async {
    try {
      final res = await _client.get(
          Uri.parse('https://api.weather.gov/alerts/active?point=$kBrownsvilleLat,$kBrownsvilleLon'),
          headers: _headers).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final features = jsonDecode(res.body)['features'] as List?;
        if (features != null) {
          return features.map((f) {
            final p = f['properties'] as Map<String, dynamic>;
            return NwsAlert(
              event: (p['event'] as String?) ?? '',
              severity: (p['severity'] as String?) ?? 'Unknown',
              headline: (p['headline'] as String?) ?? '',
              instruction: (p['instruction'] as String?) ?? '',
              ends: DateTime.tryParse(p['ends'] as String? ?? ''),
            );
          }).toList();
        }
      }
    } catch (_) {}
    return [
      const NwsAlert(
        event: 'Excessive Heat Warning (demo)',
        severity: 'Extreme',
        headline:
            'Demo alert: heat index up to 112°F expected across the lower Rio Grande Valley.',
        instruction:
            'Limit outdoor activity, drink water, and check on neighbors without A/C. / Limite la actividad al aire libre, tome agua y cuide a vecinos sin A/C.',
        demo: true,
      ),
    ];
  }

  static double _rhFromDewpoint(double tF, double dF) {
    final tC = (tF - 32) * 5 / 9;
    final dC = (dF - 32) * 5 / 9;
    const a = 17.625, b = 243.04;
    final alpha = ((a * dC) / (b + dC)) - ((a * tC) / (b + tC));
    return 100.0 * math.pow(10.0, alpha);
  }
}

class ReservoirService {
  static const _sites = {
    'Amistad': (
      '08450700',
      'Amistad Reservoir',
      1174.75,
      '1174.7 ft',
      1110.0,
      41.0,
    ),
    'Falcon': (
      '08461200',
      'Falcon Reservoir',
      296.7,
      '296.7 ft',
      258.7,
      33.0,
    ),
  };
  static const _deadElev = {'Amistad': 1065.0, 'Falcon': 240.0};

  final http.Client _client;
  ReservoirService({http.Client? client}) : _client = client ?? http.Client();

  Future<List<ReservoirReading>> fetch() async {
    final out = <ReservoirReading>[];
    for (final e in _sites.entries) {
      final id = e.value.$1;
      final name = e.value.$2;
      final consElev = e.value.$3;
      final consLabel = e.value.$4;
      final demoElev = e.value.$5;
      final demoPct = e.value.$6;
      var live = false;
      var elev = demoElev;
      var pct = demoPct;
      try {
        final res = await _client
            .get(Uri.parse(
                'https://waterservices.usgs.gov/nwis/dv/?format=json&sites=$id&parameterCd=00065&siteStatus=all'))
            .timeout(const Duration(seconds: 10));
        if (res.statusCode == 200) {
          final series = jsonDecode(res.body)['value']['timeSeries'] as List;
          if (series.isNotEmpty) {
            final vals = series.first['values'] as List;
            if (vals.isNotEmpty && (vals.first['value'] as List).isNotEmpty) {
              final last = (vals.first['value'] as List).last;
              final v = double.tryParse(last['value'] as String? ?? '');
              if (v != null && v > 50) {
                elev = v;
                final dead = _deadElev[e.key]!;
                pct = ((elev - dead) / (consElev - dead) * 100).clamp(0, 100).toDouble();
                live = true;
              }
            }
          }
        }
      } catch (_) {}
      out.add(ReservoirReading(
        name: name,
        percentFull: pct,
        elevationFt: elev,
        live: live,
        updated: DateTime.now(),
        conservationPoolFt: consLabel,
      ));
    }
    return out;
  }
}
