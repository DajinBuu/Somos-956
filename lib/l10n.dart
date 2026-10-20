import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings extends ChangeNotifier {
  String lang = 'en';
  int zone = 1;
  int hydrationMinutes = 45;
  bool hydrationOn = false;
  bool heatAlertsOn = true;
  bool notifyStageChanges = true;

  static const _kLang = 'lang';
  static const _kZone = 'zone';
  static const _kHydMin = 'hydration_minutes';
  static const _kHydOn = 'hydration_on';
  static const _kHeatOn = 'heat_alerts_on';
  static const _kStageOn = 'stage_alerts_on';

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    lang = p.getString(_kLang) ?? 'en';
    zone = p.getInt(_kZone) ?? 1;
    hydrationMinutes = p.getInt(_kHydMin) ?? 45;
    hydrationOn = p.getBool(_kHydOn) ?? false;
    heatAlertsOn = p.getBool(_kHeatOn) ?? true;
    notifyStageChanges = p.getBool(_kStageOn) ?? true;
    notifyListeners();
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kLang, lang);
    await p.setInt(_kZone, zone);
    await p.setInt(_kHydMin, hydrationMinutes);
    await p.setBool(_kHydOn, hydrationOn);
    await p.setBool(_kHeatOn, heatAlertsOn);
    await p.setBool(_kStageOn, notifyStageChanges);
  }

  void setLang(String l) {
    lang = l;
    notifyListeners();
    _save();
  }

  void setZone(int z) {
    zone = z;
    notifyListeners();
    _save();
  }

  void setHydrationMinutes(int m) {
    hydrationMinutes = m;
    notifyListeners();
    _save();
  }

  void setHydrationOn(bool v) {
    hydrationOn = v;
    notifyListeners();
    _save();
  }

  void setHeatAlertsOn(bool v) {
    heatAlertsOn = v;
    notifyListeners();
    _save();
  }

  void setNotifyStageChanges(bool v) {
    notifyStageChanges = v;
    notifyListeners();
    _save();
  }
}

class LocaleScope extends InheritedNotifier<AppSettings> {
  const LocaleScope({super.key, required AppSettings settings, required super.child})
      : super(notifier: settings);

  static AppSettings of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<LocaleScope>();
    return scope!.notifier!;
  }
}

class S {
  final String lang;
  const S(this.lang);

  static S of(BuildContext context) => S(LocaleScope.of(context).lang);

  static const Map<String, Map<String, String>> _table = {
    'app_title': {'en': 'RGV Ready', 'es': 'Listos RGV'},
    'tagline': {
      'en': 'Heat, water & roads for the 956',
      'es': 'Calor, agua y calles para el 956',
    },
    'nav_dashboard': {'en': 'Home', 'es': 'Inicio'},
    'nav_heat': {'en': 'Heat', 'es': 'Calor'},
    'nav_water': {'en': 'Water', 'es': 'Agua'},
    'nav_traffic': {'en': 'Traffic', 'es': 'Tráfico'},
    'refresh': {'en': 'Refresh', 'es': 'Actualizar'},
    'live': {'en': 'Live NWS', 'es': 'NWS en vivo'},
    'demo': {'en': 'Demo data', 'es': 'Datos de demostración'},
    'updated': {'en': 'Updated', 'es': 'Actualizado'},
    'settings': {'en': 'Settings', 'es': 'Ajustes'},

    'heat_index': {'en': 'Heat index', 'es': 'Índice de calor'},
    'air_temp': {'en': 'Air temperature', 'es': 'Temperatura del aire'},
    'humidity': {'en': 'Humidity', 'es': 'Humedad'},
    'feels_like': {'en': 'Feels like', 'es': 'Se siente como'},
    'conditions': {'en': 'Conditions', 'es': 'Condiciones'},
    'active_alerts': {'en': 'Active NWS alerts', 'es': 'Alertas activas del NWS'},
    'no_active_alerts': {
      'en': 'No active alerts for Brownsville right now.',
      'es': 'No hay alertas activas para Brownsville ahora mismo.',
    },
    'alerts_unavailable': {
      'en': 'Could not reach NWS — showing demo alerts.',
      'es': 'No se pudo conectar con el NWS — mostrando alertas de demostración.',
    },

    'heat_normal': {'en': 'Normal', 'es': 'Normal'},
    'heat_caution': {'en': 'Caution', 'es': 'Precaución'},
    'heat_extreme': {'en': 'Extreme', 'es': 'Extremo'},
    'heat_danger': {'en': 'Extreme danger', 'es': 'Peligro extremo'},
    'advice_normal': {
      'en': 'Hydrate regularly and use sunscreen. Check on elderly neighbors.',
      'es': 'Hidrátate y usa protector solar. Cuida a los vecinos mayores.',
    },
    'advice_caution': {
      'en': 'Drink water every 20 min outdoors. Light clothing. Limit midday sun.',
      'es': 'Toma agua cada 20 min al aire libre. Ropa ligera. Evita el sol del mediodía.',
    },
    'advice_extreme': {
      'en': 'Avoid outdoor work 10am–7pm. Take 15-min shade breaks every hour. Watch for cramps & dizziness.',
      'es': 'Evita el trabajo al aire libre de 10am–7pm. Descansa a la sombra 15 min cada hora. Vigila calambres y mareos.',
    },
    'advice_danger': {
      'en': 'Stay indoors with A/C. Heat stroke (hot dry skin, confusion) is a 911 emergency.',
      'es': 'Quédate adentro con A/C. Golpe de calor (piel seca y caliente, confusión) es emergencia 911.',
    },

    'reservoirs': {'en': 'Reservoirs', 'es': 'Embalses'},
    'full': {'en': 'full', 'es': 'lleno'},
    'elevation': {'en': 'Elevation', 'es': 'Elevación'},
    'conservation_pool': {
      'en': 'of conservation pool (estimated)',
      'es': 'del embalse de conservación (estimado)',
    },
    'your_zone': {'en': 'Your watering zone', 'es': 'Tu zona de riego'},
    'zone': {'en': 'Zone', 'es': 'Zona'},
    'restriction_stage': {'en': 'Restriction stage', 'es': 'Etapa de restricción'},
    'stage_none': {'en': 'Normal — no restrictions', 'es': 'Normal — sin restricciones'},
    'stage1': {'en': 'Stage 1 — Voluntary limits', 'es': 'Etapa 1 — Límites voluntarios'},
    'stage2': {'en': 'Stage 2 — Mandatory limits', 'es': 'Etapa 2 — Límites obligatorios'},
    'stage3': {'en': 'Stage 3 — Severe drought', 'es': 'Etapa 3 — Sequía severa'},
    'stage4': {'en': 'Stage 4 — Emergency', 'es': 'Etapa 4 — Emergencia'},
    'watering_days': {'en': 'Watering days', 'es': 'Días de riego'},
    'watering_hours': {'en': 'Allowed hours', 'es': 'Horas permitidas'},
    'watering_rules': {'en': 'Rules', 'es': 'Reglas'},
    'water_quality': {'en': 'Latest water quality report', 'es': 'Último reporte de calidad del agua'},
    'chlorine': {'en': 'Chlorine residual', 'es': 'Residuo de cloro'},
    'ph': {'en': 'pH', 'es': 'pH'},
    'turbidity': {'en': 'Turbidity', 'es': 'Turbidez'},
    'coliform': {'en': 'Total coliform', 'es': 'Coliformes totales'},
    'not_detected': {'en': 'Not detected', 'es': 'No detectados'},
    'no_burn_notice': {
      'en': 'Water meets all state and federal standards.',
      'es': 'El agua cumple con todas las normas estatales y federales.',
    },

    'cooling_centers': {'en': 'Cooling centers', 'es': 'Centros de enfriamiento'},
    'splash_pads': {'en': 'Splash pads', 'es': 'Áreas de juegos de agua'},
    'ac_buildings': {'en': 'A/C buildings', 'es': 'Edificios con A/C'},
    'map': {'en': 'Map', 'es': 'Mapa'},
    'list': {'en': 'List', 'es': 'Lista'},
    'free_entry': {'en': 'Free entry', 'es': 'Entrada gratis'},
    'call': {'en': 'Call', 'es': 'Llamar'},
    'hours': {'en': 'Hours', 'es': 'Horario'},
    'hydration_reminders': {'en': 'Hydration reminders', 'es': 'Recordatorios de hidratación'},
    'hydration_hint': {
      'en': 'Get a push notification reminding you to drink water while you work or play outside.',
      'es': 'Recibe una notificación para tomar agua mientras trabajas o juegas afuera.',
    },
    'remind_me_every': {'en': 'Remind me every', 'es': 'Recuérdame cada'},
    'next_reminder': {'en': 'Next reminder', 'es': 'Próximo recordatorio'},
    'minutes': {'en': 'min', 'es': 'min'},
    'worker_tips': {
      'en': 'Heat safety for field & construction workers',
      'es': 'Seguridad contra el calor para trabajadores de campo y construcción',
    },
    'dashboard_heat_card': {'en': 'Heat safety now', 'es': 'Seguridad contra el calor'},

    'bridge_delays': {'en': 'International bridge delays', 'es': 'Retrasos en puentes internacionales'},
    'wait': {'en': 'Wait', 'es': 'Espera'},
    'min': {'en': 'min', 'es': 'min'},
    'bridge_open': {'en': 'Moving', 'es': 'Fluido'},
    'bridge_delayed': {'en': 'Delayed', 'es': 'Retraso'},
    'bridge_heavy': {'en': 'Heavy', 'es': 'Pesado'},
    'bridge_closed': {'en': 'Closed', 'es': 'Cerrado'},
    'road_hazards': {'en': 'Road hazards', 'es': 'Peligros viales'},
    'flood_prone': {
      'en': 'Flash-flood hotspots',
      'es': 'Puntos de inundación repentina',
    },
    'severity_low': {'en': 'Caution', 'es': 'Precaución'},
    'severity_medium': {'en': 'Moderate', 'es': 'Moderado'},
    'severity_high': {'en': 'Severe', 'es': 'Severo'},
    'severity_closed': {'en': 'Closed', 'es': 'Cerrado'},
    'hazard_flood': {'en': 'Flooding', 'es': 'Inundación'},
    'hazard_construction': {'en': 'Construction', 'es': 'Construcción'},
    'hazard_accident': {'en': 'Accident', 'es': 'Accidente'},
    'hazard_debris': {'en': 'Debris / low water', 'es': 'Escombros / agua baja'},
    'demo_note': {
      'en': 'Bridge and street data are simulated demo feeds for the Congressional App Challenge; hook up CBP / TxDOT / city feeds to go live.',
      'es': 'Los datos de puentes y calles son simulados para el Congresional App Challenge; conecte fuentes CBP / TxDOT / ciudad para datos reales.',
    },
    'no_live_weather': {
      'en': 'Showing sample values — connect to the internet for live NWS data.',
      'es': 'Mostrando valores de ejemplo — conéctese a internet para datos del NWS.',
    },
    'view_details': {'en': 'Details', 'es': 'Detalles'},
    'close': {'en': 'Close', 'es': 'Cerrar'},
  };

  String t(String key, [Map<String, String> args = const {}]) {
    final row = _table[key];
    var s = (row == null) ? key : (row[lang] ?? row['en'] ?? key);
    args.forEach((k, v) => s = s.replaceAll('{$k}', v));
    return s;
  }

  String call(String key, [Map<String, String> args = const {}]) => t(key, args);
}
