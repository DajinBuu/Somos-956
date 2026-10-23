enum CareType { hospital, urgent, clinic, pharmacy }

class CareFacility {
  final String id;
  final String name;
  final CareType type;
  final String address;
  final String city;
  final String phone;
  final bool acceptsUninsured;
  final bool bilingual;
  final bool open24h;
  final double lat;
  final double lon;
  final String servicesEn;
  final String servicesEs;

  const CareFacility({
    required this.id,
    required this.name,
    required this.type,
    required this.address,
    required this.city,
    required this.phone,
    required this.acceptsUninsured,
    required this.bilingual,
    required this.open24h,
    required this.lat,
    required this.lon,
    required this.servicesEn,
    required this.servicesEs,
  });
}

class FamilyMember {
  final String name;
  final int age;
  final String notes;
  final List<Visit> visits;
  const FamilyMember({
    required this.name,
    required this.age,
    this.notes = '',
    this.visits = const [],
  });
}

class Visit {
  final String reason;
  final DateTime date;
  const Visit({required this.reason, required this.date});
}

class MedicalTerm {
  final String term;
  final String plainEn;
  final String plainEs;
  final String category; // diagnosis | test | insurance | medication | form
  const MedicalTerm(this.term, this.plainEn, this.plainEs, this.category);
}

class FormField {
  final String fieldEn;
  final String fieldEs;
  final String explainEn;
  final String explainEs;
  const FormField(this.fieldEn, this.fieldEs, this.explainEn, this.explainEs);
}

enum BridgeState { moving, slow, heavy }

class Bridge {
  final String id;
  final String name;
  final String nameEs;
  final String city;
  final String cityEs;
  final String crossing;
  final String portNumber; // CBP port_number used by the live BWT feed
  final List<int> hourlyPattern; // 24 values, typical wait minutes by hour
  final double peakScale; // per-crossing magnitude vs. the shared shape
  final double lat;
  final double lon;
  const Bridge({
    required this.id,
    required this.name,
    required this.nameEs,
    required this.city,
    required this.cityEs,
    required this.crossing,
    required this.portNumber,
    required this.hourlyPattern,
    this.peakScale = 1.0,
    required this.lat,
    required this.lon,
  });
}

class BridgeReading {
  final Bridge bridge;
  final int waitMinutes;
  final BridgeState state;
  final DateTime updated;
  final bool live;
  final int? passengerWait;
  final int? commercialWait;
  final int? pedestrianWait;
  final String laneStatus;
  final bool lanesClosed;
  final int? fastestLaneWait;
  const BridgeReading({
    required this.bridge,
    required this.waitMinutes,
    required this.state,
    required this.updated,
    this.live = false,
    this.passengerWait,
    this.commercialWait,
    this.pedestrianWait,
    this.laneStatus = '',
    this.lanesClosed = false,
    this.fastestLaneWait,
  });
}

class BridgeForecast {
  final int hour;
  final int wait;
  const BridgeForecast(this.hour, this.wait);
}

enum RoadSeverity { info, minor, major, closure }

class RoadEvent {
  final String id;
  final String title;
  final String description;
  final String route;
  final RoadSeverity severity;
  final double lat;
  final double lon;
  const RoadEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.route,
    required this.severity,
    required this.lat,
    required this.lon,
  });
}

class WeatherSnapshot {
  final double temperatureF;
  final double feelsLikeF;
  final int humidity;
  final double windMph;
  final String condition;
  final int weatherCode;
  final double? heatIndexF;
  final DateTime updated;
  const WeatherSnapshot({
    required this.temperatureF,
    required this.feelsLikeF,
    required this.humidity,
    required this.windMph,
    required this.condition,
    required this.weatherCode,
    required this.updated,
    this.heatIndexF,
  });
}

class AirQuality {
  final int aqi;
  final double pm25;
  final double pm10;
  final DateTime updated;
  const AirQuality({
    required this.aqi,
    required this.pm25,
    required this.pm10,
    required this.updated,
  });
}

class WeatherAlert {
  final String event;
  final String severity;
  final String headline;
  final String area;
  final String description;
  const WeatherAlert({
    required this.event,
    required this.severity,
    required this.headline,
    required this.area,
    required this.description,
  });
}

enum CorridorLevel { light, moderate, heavy, severe }

class Corridor {
  final String id;
  final String name;
  final String nameEs;
  final String segment;
  final CorridorLevel level;
  final int speedMph;
  final double lat;
  final double lon;
  const Corridor({
    required this.id,
    required this.name,
    required this.nameEs,
    required this.segment,
    required this.level,
    required this.speedMph,
    required this.lat,
    required this.lon,
  });
}

enum ResourceType { food, shelter, clinic, hotline, legal }

class CommunityResource {
  final String id;
  final String name;
  final ResourceType type;
  final String address;
  final String city;
  final String phone;
  final String hoursEn;
  final String hoursEs;
  final String detailEn;
  final String detailEs;
  final double lat;
  final double lon;
  const CommunityResource({
    required this.id,
    required this.name,
    required this.type,
    required this.address,
    required this.city,
    required this.phone,
    required this.hoursEn,
    required this.hoursEs,
    required this.detailEn,
    required this.detailEs,
    required this.lat,
    required this.lon,
  });
}

class EligibilityProgram {
  final String name;
  final String nameEs;
  final String descriptionEn;
  final String descriptionEs;
  final bool childRelated;
  final bool elderlyRelated;
  final bool uninsuredRelated;
  final int incomeThresholdMonthly; // for household of 1, scaled up
  const EligibilityProgram({
    required this.name,
    required this.nameEs,
    required this.descriptionEn,
    required this.descriptionEs,
    this.childRelated = false,
    this.elderlyRelated = false,
    this.uninsuredRelated = false,
    required this.incomeThresholdMonthly,
  });
}

class CulturalTip {
  final String titleEn;
  final String titleEs;
  final String bodyEn;
  final String bodyEs;
  const CulturalTip(this.titleEn, this.titleEs, this.bodyEn, this.bodyEs);
}

enum EduType { tutoring, library, afterschool, scholarship, college, esl }

class EduResource {
  final String id;
  final String name;
  final EduType type;
  final String provider;
  final String address;
  final String city;
  final String phone;
  final String detailEn;
  final String detailEs;
  final String deadlineEn;
  final String deadlineEs;
  final String rewardEn;
  final String rewardEs;
  final bool free;
  final double lat;
  final double lon;
  const EduResource({
    required this.id,
    required this.name,
    required this.type,
    required this.provider,
    this.address = '',
    this.city = '',
    this.phone = '',
    required this.detailEn,
    required this.detailEs,
    this.deadlineEn = '',
    this.deadlineEs = '',
    this.rewardEn = '',
    this.rewardEs = '',
    this.free = true,
    this.lat = 0,
    this.lon = 0,
  });
}

// ---------------------------------------------------------------------------
// Mosquito activity
// ---------------------------------------------------------------------------

/// Overall mosquito pressure for an area, derived from weather that drives
/// breeding and biting: recent rainfall, warmth, and humidity.
enum MosquitoLevel { low, moderate, high, severe }

/// A geographic sector of the Rio Grande Valley used to sample live weather and
/// estimate mosquito activity. Coordinates are a representative center point.
class MosquitoZone {
  final String id;
  final String name;
  final String nameEs;
  final String county;
  final double lat;
  final double lon;
  const MosquitoZone({
    required this.id,
    required this.name,
    required this.nameEs,
    required this.county,
    required this.lat,
    required this.lon,
  });
}

/// A live, weather-derived mosquito risk estimate for a [MosquitoZone].
class MosquitoRisk {
  final MosquitoZone zone;
  final MosquitoLevel level;
  final int score; // 0-100
  final double tempF;
  final int humidity;
  final double rain7dIn; // rainfall over the past 7 days, inches
  final bool live;
  final DateTime updated;
  const MosquitoRisk({
    required this.zone,
    required this.level,
    required this.score,
    required this.tempF,
    required this.humidity,
    required this.rain7dIn,
    this.live = true,
    required this.updated,
  });
}

/// A user-submitted mosquito hot spot. Persisted locally on the device.
class MosquitoReport {
  final String id;
  final String note;
  final MosquitoLevel severity;
  final double lat;
  final double lon;
  final DateTime when;
  const MosquitoReport({
    required this.id,
    required this.note,
    required this.severity,
    required this.lat,
    required this.lon,
    required this.when,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'note': note,
        'severity': severity.name,
        'lat': lat,
        'lon': lon,
        'when': when.toIso8601String(),
      };

  static MosquitoReport? fromJson(Map<String, dynamic> m) {
    try {
      return MosquitoReport(
        id: '${m['id']}',
        note: '${m['note'] ?? ''}',
        severity: MosquitoLevel.values.firstWhere(
          (e) => e.name == '${m['severity']}',
          orElse: () => MosquitoLevel.moderate,
        ),
        lat: (m['lat'] as num).toDouble(),
        lon: (m['lon'] as num).toDouble(),
        when: DateTime.tryParse('${m['when']}') ?? DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }
}
