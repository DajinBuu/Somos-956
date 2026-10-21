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
  final List<int> hourlyPattern; // 24 values, relative delay 0..10
  final double lat;
  final double lon;
  const Bridge({
    required this.id,
    required this.name,
    required this.nameEs,
    required this.city,
    required this.cityEs,
    required this.crossing,
    required this.hourlyPattern,
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
  const BridgeReading({
    required this.bridge,
    required this.waitMinutes,
    required this.state,
    required this.updated,
    this.live = false,
  });
}

class BridgeForecast {
  final int hour;
  final int wait;
  const BridgeForecast(this.hour, this.wait);
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
