class HeatReading {
  final double tempF;
  final double? humidity;
  final double? heatIndexF;
  final String condition;
  final bool live;
  final DateTime observed;

  const HeatReading({
    required this.tempF,
    this.humidity,
    this.heatIndexF,
    required this.condition,
    required this.live,
    required this.observed,
  });

  double get hi => heatIndexF ?? tempF;
}

enum HeatLevel { normal, caution, extreme, danger }

HeatLevel heatLevelFor(double hi) {
  if (hi >= 125) return HeatLevel.danger;
  if (hi >= 103) return HeatLevel.extreme;
  if (hi >= 90) return HeatLevel.caution;
  return HeatLevel.normal;
}

double heatIndexF(double tempF, double rh) {
  var t = tempF;
  for (var i = 0; i < 3; i++) {
    final c = -42.379 +
        2.04901523 * t +
        10.14333127 * rh -
        0.22475541 * t * rh -
        0.00683783 * t * t -
        0.05481717 * rh * rh +
        0.00122874 * t * t * rh +
        0.00085282 * t * rh * rh -
        0.00000199 * t * t * rh * rh;
    t = tempF + (c - tempF) * 0.35;
  }
  final hiC = -8.78469475556 +
      1.61139411 * t +
      2.33854883889 * rh -
      0.14611605 * t * rh -
      0.012308094 * t * t -
      0.0164248277778 * rh * rh +
      0.002211732 * t * t * rh +
      0.00072546 * t * rh * rh -
      0.000003582 * t * t * rh * rh;
  return hiC * 9 / 5 + 32;
}

class NwsAlert {
  final String event;
  final String severity;
  final String headline;
  final String instruction;
  final DateTime? ends;
  final bool demo;

  const NwsAlert({
    required this.event,
    required this.severity,
    required this.headline,
    required this.instruction,
    this.ends,
    this.demo = false,
  });
}

enum SiteType { coolingCenter, splashPad, acBuilding }

class Site {
  final String name;
  final String address;
  final String city;
  final String phone;
  final String hours;
  final SiteType type;
  final double lat;
  final double lon;

  const Site({
    required this.name,
    required this.address,
    required this.city,
    required this.phone,
    required this.hours,
    required this.type,
    required this.lat,
    required this.lon,
  });
}

class ReservoirReading {
  final String name;
  final double percentFull;
  final double elevationFt;
  final bool live;
  final DateTime updated;
  final String conservationPoolFt;

  const ReservoirReading({
    required this.name,
    required this.percentFull,
    required this.elevationFt,
    required this.live,
    required this.updated,
    required this.conservationPoolFt,
  });
}

class WaterZone {
  final int number;
  final String nameEn;
  final String nameEs;
  final int stage;
  final String daysEn;
  final String daysEs;
  final String hoursRuleEn;
  final String hoursRuleEs;
  final List<String> rulesEn;
  final List<String> rulesEs;

  const WaterZone({
    required this.number,
    required this.nameEn,
    required this.nameEs,
    required this.stage,
    required this.daysEn,
    required this.daysEs,
    required this.hoursRuleEn,
    required this.hoursRuleEs,
    required this.rulesEn,
    required this.rulesEs,
  });
}

class WaterQualityReport {
  final String published;
  final double chlorine;
  final double ph;
  final double turbidity;
  final bool coliformDetected;
  final bool demo;

  const WaterQualityReport({
    required this.published,
    required this.chlorine,
    required this.ph,
    required this.turbidity,
    required this.coliformDetected,
    this.demo = true,
  });
}

enum BridgeState { open, delayed, heavy, closed }

class BridgeStatus {
  final String name;
  final String nameEs;
  final int waitMinutes;
  final BridgeState state;
  final DateTime? updated;
  final bool demo;

  const BridgeStatus({
    required this.name,
    required this.nameEs,
    required this.waitMinutes,
    required this.state,
    this.updated,
    this.demo = true,
  });
}

enum HazardType { flood, construction, accident, debris }

class Hazard {
  final String titleEn;
  final String titleEs;
  final String road;
  final HazardType type;
  final int severity;
  final double lat;
  final double lon;
  final DateTime? updated;

  const Hazard({
    required this.titleEn,
    required this.titleEs,
    required this.road,
    required this.type,
    required this.severity,
    required this.lat,
    required this.lon,
    this.updated,
  });
}

class SafetyTip {
  final String en;
  final String es;
  const SafetyTip(this.en, this.es);
}
