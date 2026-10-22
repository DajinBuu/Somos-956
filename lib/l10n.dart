import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Language display modes selected on first launch.
enum LangMode {
  english, // English only
  spanish, // Español only
  bilingual, // English with a smaller Spanish line beneath
}

class AppSettings extends ChangeNotifier {
  /// Primary language code: 'en' or 'es'.
  String lang = 'en';

  /// When true, show the other language as a smaller secondary line.
  bool bilingual = false;

  /// False until the very first language choice has been made.
  bool onboarded = true;

  bool reminderOn = true;
  final Set<String> savedResources = {};
  final List<Map<String, String>> reports = [];

  static const _kLang = 'lang';
  static const _kBilingual = 'bilingual';
  static const _kOnboarded = 'onboarded';
  static const _kReminder = 'reminder_on';
  static const _kSaved = 'saved_resources';
  static const _kReports = 'reports';

  LangMode get mode => bilingual
      ? LangMode.bilingual
      : (lang == 'es' ? LangMode.spanish : LangMode.english);

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    lang = p.getString(_kLang) ?? 'en';
    bilingual = p.getBool(_kBilingual) ?? false;
    onboarded = p.getBool(_kOnboarded) ?? false;
    reminderOn = p.getBool(_kReminder) ?? true;
    savedResources
      ..clear()
      ..addAll(p.getStringList(_kSaved) ?? const []);
    final raw = p.getStringList(_kReports) ?? const [];
    reports
      ..clear()
      ..addAll(raw.map((s) {
        final parts = s.split('|');
        return {
          'type': parts.isNotEmpty ? parts[0] : '',
          'text': parts.length > 1 ? parts[1] : '',
          'time': parts.length > 2 ? parts[2] : '',
        };
      }));
    notifyListeners();
  }

  void setLang(String l) {
    lang = l;
    notifyListeners();
    _save();
  }

  void setMode(LangMode m) {
    switch (m) {
      case LangMode.english:
        lang = 'en';
        bilingual = false;
      case LangMode.spanish:
        lang = 'es';
        bilingual = false;
      case LangMode.bilingual:
        lang = 'en';
        bilingual = true;
    }
    onboarded = true;
    notifyListeners();
    _save();
  }

  void setBilingual(bool v) {
    bilingual = v;
    notifyListeners();
    _save();
  }

  void setReminder(bool v) {
    reminderOn = v;
    notifyListeners();
    _save();
  }

  void toggleSaved(String id) {
    if (savedResources.contains(id)) {
      savedResources.remove(id);
    } else {
      savedResources.add(id);
    }
    notifyListeners();
    _save();
  }

  void addReport(String type, String text) {
    reports.add({
      'type': type,
      'text': text,
      'time': DateTime.now().toIso8601String(),
    });
    notifyListeners();
    _save();
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kLang, lang);
    await p.setBool(_kBilingual, bilingual);
    await p.setBool(_kOnboarded, onboarded);
    await p.setBool(_kReminder, reminderOn);
    await p.setStringList(_kSaved, savedResources.toList());
    await p.setStringList(
      _kReports,
      reports.map((r) => '${r['type']}|${r['text']}|${r['time']}').toList(),
    );
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
  final bool bilingual;
  const S(this.lang, {this.bilingual = false});

  static S of(BuildContext context) {
    final settings = LocaleScope.of(context);
    return S(settings.lang, bilingual: settings.bilingual);
  }

  bool get es => lang == 'es';

  /// The secondary language code shown under the primary in bilingual mode.
  String get secondaryLang => lang == 'es' ? 'en' : 'es';

  String _tIn(String code, String key, Map<String, String> args) {
    final row = _table[key];
    var s = (row == null) ? key : (row[code] ?? row['en'] ?? key);
    args.forEach((k, v) => s = s.replaceAll('{$k}', v));
    return s;
  }

  String t(String key, [Map<String, String> args = const {}]) =>
      _tIn(lang, key, args);

  /// Secondary-language text for a key (empty when key is unknown).
  String tSecondary(String key, [Map<String, String> args = const {}]) =>
      _tIn(secondaryLang, key, args);

  /// Primary text for a bilingual en/es pair.
  String pick(String en, String esText) => lang == 'es' ? esText : en;

  /// Secondary text for a bilingual en/es pair.
  String pickSecondary(String en, String esText) =>
      lang == 'es' ? en : esText;

  /// A widget that shows the primary text and, in bilingual mode, a smaller
  /// secondary line beneath it in a muted style.
  Widget b(String en, String esText, {double size = 14, FontWeight weight = FontWeight.normal, Color? color}) {
    if (!bilingual) {
      return Text(
        pick(en, esText),
        style: TextStyle(fontSize: size, fontWeight: weight, color: color),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          pick(en, esText),
          style: TextStyle(fontSize: size, fontWeight: weight, color: color),
        ),
        Text(
          pickSecondary(en, esText),
          style: TextStyle(
            fontSize: size * 0.82,
            color: (color ?? Colors.black87).withValues(alpha: 0.6),
            height: 1.2,
          ),
        ),
      ],
    );
  }

  /// Bilingual-aware lookup for a translation-table key.
  Widget tk(String key, {double size = 14, FontWeight weight = FontWeight.normal, Color? color}) =>
      b(t(key), tSecondary(key), size: size, weight: weight, color: color);

  static const Map<String, Map<String, String>> _table = {
    'app_title': {'en': 'Somos 956', 'es': 'Somos 956'},
    'tagline': {
      'en': 'One app for the 956 — health, roads, help & school',
      'es': 'Una app para el 956 — salud, calles, ayuda y escuela',
    },
    'nav_home': {'en': 'Home', 'es': 'Inicio'},
    'nav_health': {'en': 'Health', 'es': 'Salud'},
    'nav_move': {'en': 'Transport', 'es': 'Transporte'},
    'nav_community': {'en': 'Community', 'es': 'Comunidad'},
    'nav_education': {'en': 'Education', 'es': 'Educación'},
    'nav_more': {'en': 'More', 'es': 'Más'},

    // Home / dashboard
    'home_greeting_morning': {'en': 'Good morning', 'es': 'Buenos días'},
    'home_greeting_afternoon': {'en': 'Good afternoon', 'es': 'Buenas tardes'},
    'home_greeting_evening': {'en': 'Good evening', 'es': 'Buenas noches'},
    'home_welcome': {
      'en': 'Your one stop for healthcare, roads, help and school in the 956.',
      'es': 'Su parada única para salud, calles, ayuda y escuela en el 956.',
    },
    'home_quick': {'en': 'Quick actions', 'es': 'Acciones rápidas'},
    'home_glance': {'en': 'At a glance', 'es': 'De un vistazo'},
    'home_find_care': {'en': 'Find care', 'es': 'Buscar atención'},
    'home_bridge_waits': {'en': 'Bridge waits', 'es': 'Esperas en puentes'},
    'home_get_help': {'en': 'Get help', 'es': 'Obtener ayuda'},
    'home_edu_tools': {'en': 'School tools', 'es': 'Herramientas escolares'},
    'home_tip': {'en': "Solecito's tip", 'es': 'Consejo de Solecito'},
    'home_bridges_short': {'en': 'Live bridge waits & traffic', 'es': 'Esperas y tráfico en vivo'},
    'home_care_short': {'en': 'Hospitals, clinics & pharmacies', 'es': 'Hospitales, clínicas y farmacias'},
    'home_help_short': {'en': 'Food, shelter, legal & clinics', 'es': 'Comida, refugio, legal y clínicas'},
    'home_edu_short': {'en': 'Tutoring, libraries & scholarships', 'es': 'Tutoría, bibliotecas y becas'},
    'home_open': {'en': 'Open', 'es': 'Abrir'},
    'see_all': {'en': 'See all', 'es': 'Ver todo'},
    'tap_to_open': {'en': 'Tap to open', 'es': 'Toque para abrir'},
    'search_hint': {'en': 'Search resources…', 'es': 'Buscar recursos…'},
    'explore': {'en': 'Explore', 'es': 'Explorar'},
    'back': {'en': 'Back', 'es': 'Atrás'},

    'refresh': {'en': 'Refresh', 'es': 'Actualizar'},
    'live': {'en': 'Live', 'es': 'En vivo'},
    'demo': {'en': 'Demo data', 'es': 'Datos demo'},
    'predicted': {'en': 'AI predicted', 'es': 'Predicción IA'},
    'updated': {'en': 'Updated', 'es': 'Actualizado'},
    'now': {'en': 'Now', 'es': 'Ahora'},
    'call': {'en': 'Call', 'es': 'Llamar'},
    'directions': {'en': 'Directions', 'es': 'Cómo llegar'},
    'save': {'en': 'Save', 'es': 'Guardar'},
    'saved': {'en': 'Saved', 'es': 'Guardado'},
    'close': {'en': 'Close', 'es': 'Cerrar'},
    'min': {'en': 'min', 'es': 'min'},
    'hours': {'en': 'Hours', 'es': 'Horario'},
    'address': {'en': 'Address', 'es': 'Dirección'},
    'free': {'en': 'Free', 'es': 'Gratis'},
    'free_lowcost': {'en': 'Free or low-cost', 'es': 'Gratis o bajo costo'},
    'languages': {'en': 'Languages', 'es': 'Idiomas'},
    'map': {'en': 'Map', 'es': 'Mapa'},
    'list': {'en': 'List', 'es': 'Lista'},
    'open_now': {'en': 'Open now', 'es': 'Abierto ahora'},
    'search': {'en': 'Search', 'es': 'Buscar'},
    'learn_more': {'en': 'Learn more', 'es': 'Más información'},

    // Healthcare
    'health_title': {'en': 'Healthcare navigation', 'es': 'Navegación de salud'},
    'health_intro': {
      'en': 'Find care near you, keep track of your family’s visits, and understand medical words and forms in plain English or Spanish.',
      'es': 'Encuentre atención cerca, lleve el control de las citas de su familia y entienda términos y formularios médicos en inglés o español claro.',
    },
    'care_directory': {'en': 'Emergency & urgent care', 'es': 'Emergencias y atención urgente'},
    'care_hospital': {'en': 'Hospital / ER', 'es': 'Hospital / Emergencias'},
    'care_urgent': {'en': 'Urgent care', 'es': 'Atención urgente'},
    'care_clinic': {'en': 'Community clinic', 'es': 'Clínica comunitaria'},
    'care_pharmacy': {'en': 'Pharmacy', 'es': 'Farmacia'},
    'call_911': {'en': 'Call 911', 'es': 'Llame al 911'},
    'emergency_note': {
      'en': 'For a life-threatening emergency, call 911 first.',
      'es': 'Para una emergencia que pone en riesgo la vida, llame primero al 911.',
    },
    'family_profiles': {'en': 'Family health profiles', 'es': 'Perfiles de salud familiares'},
    'profiles_hint': {
      'en': 'Add each family member and track their upcoming visits so no appointment is missed.',
      'es': 'Agregue a cada familiar y lleve el control de sus próximas citas para no perder ninguna.',
    },
    'add_member': {'en': 'Add family member', 'es': 'Agregar familiar'},
    'member_name': {'en': 'Name', 'es': 'Nombre'},
    'member_age': {'en': 'Age', 'es': 'Edad'},
    'member_notes': {'en': 'Notes (allergies, medication)', 'es': 'Notas (alergias, medicamentos)'},
    'upcoming_visits': {'en': 'Upcoming visits', 'es': 'Próximas citas'},
    'add_visit': {'en': 'Add visit', 'es': 'Agregar cita'},
    'visit_what': {'en': 'Reason / doctor', 'es': 'Motivo / doctor'},
    'visit_when': {'en': 'Date', 'es': 'Fecha'},
    'no_visits': {'en': 'No visits scheduled yet.', 'es': 'Aún no hay citas programadas.'},
    'no_members': {'en': 'No family members added yet.', 'es': 'Aún no hay familiares agregados.'},
    'reminders_on': {'en': 'Visit reminders', 'es': 'Recordatorios de citas'},
    'reminders_hint': {
      'en': 'Get a notification before each visit.',
      'es': 'Reciba una notificación antes de cada cita.',
    },
    'term_decoder': {'en': 'Medical term decoder', 'es': 'Decodificador de términos médicos'},
    'term_hint': {
      'en': 'Type or paste a medical word, acronym, or phrase to see a plain-language explanation.',
      'es': 'Escriba o pegue una palabra, sigla o frase médica para ver una explicación en lenguaje sencillo.',
    },
    'term_placeholder': {'en': 'e.g. hypertension, CBC, deductible', 'es': 'ej. hipertensión, biometría hemática, deducible'},
    'decode': {'en': 'Explain it', 'es': 'Explícalo'},
    'term_not_found': {
      'en': 'No match in our dictionary yet. Try another word or ask your clinic for a translated form.',
      'es': 'Aún no hay una coincidencia en nuestro diccionario. Pruebe otra palabra o pida a su clínica un formulario traducido.',
    },
    'decode_ai_note': {
      'en': 'Plain-language explanation. It is not medical advice — confirm details with your doctor.',
      'es': 'Explicación en lenguaje sencillo. No es consejo médico — confirme los detalles con su doctor.',
    },
    'form_helper': {'en': 'Form helper', 'es': 'Ayuda con formularios'},
    'form_helper_hint': {
      'en': 'Common fields on clinic and insurance forms, translated.',
      'es': 'Campos comunes en formularios de clínica y seguro, traducidos.',
    },

    // Transportation
    'move_title': {'en': 'Cross-border & highway times', 'es': 'Tiempos en la frontera y carreteras'},
    'move_intro': {
      'en': 'Live waits at the international bridges plus AI-style predictions, and traffic on the I-2/I-69C corridors.',
      'es': 'Esperas en vivo en los puentes internacionales más predicciones con IA, y tráfico en los corredores I-2/I-69C.',
    },
    'bridges': {'en': 'International bridges', 'es': 'Puentes internacionales'},
    'bridge_wait': {'en': 'Wait', 'es': 'Espera'},
    'bridge_moving': {'en': 'Moving well', 'es': 'Fluido'},
    'bridge_slow': {'en': 'Slow', 'es': 'Lento'},
    'bridge_heavy': {'en': 'Heavy', 'es': 'Pesado'},
    'best_time': {'en': 'Best window', 'es': 'Mejor ventana'},
    'forecast': {'en': 'Next hours (AI forecast)', 'es': 'Próximas horas (pronóstico IA)'},
    'corridors': {'en': 'Highway corridors', 'es': 'Corredores de carretera'},
    'corridor_i2': {'en': 'I-2 (Expressway 83)', 'es': 'I-2 (Expressway 83)'},
    'corridor_i69c': {'en': 'I-69C / US-281', 'es': 'I-69C / US-281'},
    'corridor_i69e': {'en': 'I-69E / US-77', 'es': 'I-69E / US-77'},
    'traffic_light': {'en': 'Light', 'es': 'Ligero'},
    'traffic_moderate': {'en': 'Moderate', 'es': 'Moderado'},
    'traffic_heavy': {'en': 'Heavy', 'es': 'Pesado'},
    'traffic_severe': {'en': 'Severe', 'es': 'Severo'},
    'cargo_mode': {'en': 'Commercial / cargo', 'es': 'Comercial / carga'},
    'passenger_mode': {'en': 'Passenger', 'es': 'Pasajeros'},
    'pedestrian': {'en': 'On foot', 'es': 'A pie'},
    'eta_calculator': {'en': 'Predict my crossing time', 'es': 'Predecir mi tiempo de cruce'},
    'eta_bridge': {'en': 'Which bridge?', 'es': '¿Qué puente?'},
    'eta_when': {'en': 'When do you plan to cross?', 'es': '¿Cuándo piensa cruzar?'},
    'eta_result': {'en': 'Predicted wait', 'es': 'Espera predicha'},
    'eta_day': {'en': 'Which day?', 'es': '¿Qué día?'},
    'eta_typical_for': {'en': 'Typical wait', 'es': 'Espera típica'},
    'eta_historical': {
      'en': 'Fridays and Mondays run longest; Saturdays are usually lightest.',
      'es': 'Los viernes y lunes son los más largos; los sábados suelen ser los más ligeros.',
    },
    'busiest_day': {'en': 'Busiest day', 'es': 'Día más ocupado'},
    'lightest_day': {'en': 'Lightest day', 'es': 'Día más ligero'},
    'day_sun': {'en': 'Sun', 'es': 'Dom'},
    'day_mon': {'en': 'Mon', 'es': 'Lun'},
    'day_tue': {'en': 'Tue', 'es': 'Mar'},
    'day_wed': {'en': 'Wed', 'es': 'Mié'},
    'day_thu': {'en': 'Thu', 'es': 'Jue'},
    'day_fri': {'en': 'Fri', 'es': 'Vie'},
    'day_sat': {'en': 'Sat', 'es': 'Sáb'},
    'ai_engine_note': {
      'en': 'Bridge waits are live from U.S. CBP. These hour-by-hour bars are an estimate based on typical traffic — verify before you drive.',
      'es': 'Las esperas en los puentes son en vivo de CBP de EE. UU. Estas barras por hora son una estimación según el tráfico típico — verifique antes de conducir.',
    },

    // Community
    'community_title': {'en': 'Civic & human services', 'es': 'Servicios cívicos y humanos'},
    'community_intro': {
      'en': 'Clinics, food pantries, shelters and hotlines, what you may qualify for, a way to report problems anonymously, and tips for settling into Texas life.',
      'es': 'Clínicas, despensas, refugios y líneas de ayuda, lo que podría calificar, una forma de reportar problemas anónimamente, y consejos para la vida en Texas.',
    },
    'resources': {'en': 'Resource directory', 'es': 'Directorio de recursos'},
    'res_food': {'en': 'Food pantry', 'es': 'Despensa de alimentos'},
    'res_shelter': {'en': 'Shelter', 'es': 'Refugio'},
    'res_clinic': {'en': 'Clinic', 'es': 'Clínica'},
    'res_hotline': {'en': 'Hotline', 'es': 'Línea de ayuda'},
    'res_legal': {'en': 'Legal / rights', 'es': 'Legal / derechos'},
    'eligibility': {'en': 'What you may qualify for', 'es': 'Lo que podría calificar'},
    'eligibility_hint': {
      'en': 'Answer a few questions to see likely programs. This is a screening tool, not an official decision.',
      'es': 'Responda unas preguntas para ver programas probables. Es una herramienta orientativa, no una decisión oficial.',
    },
    'household_size': {'en': 'People in household', 'es': 'Personas en el hogar'},
    'monthly_income': {'en': 'Monthly household income (USD)', 'es': 'Ingreso mensual del hogar (USD)'},
    'has_children': {'en': 'Children under 18 at home', 'es': 'Niños menores de 18 en casa'},
    'has_elderly': {'en': 'Adults 65 or older at home', 'es': 'Adultos de 65 años o más en casa'},
    'uninsured': {'en': 'Anyone without health insurance', 'es': 'Alguien sin seguro médico'},
    'see_matches': {'en': 'See matches', 'es': 'Ver resultados'},
    'likely_eligible': {'en': 'Likely eligible', 'es': 'Probablemente elegible'},
    'maybe_eligible': {'en': 'May be eligible', 'es': 'Podría ser elegible'},
    'report': {'en': 'Report a problem anonymously', 'es': 'Reportar un problema anónimamente'},
    'report_hint': {
      'en': 'No name, no account. Reports stay anonymous.',
      'es': 'Sin nombre, sin cuenta. Los reportes son anónimos.',
    },
    'report_type': {'en': 'What is it about?', 'es': '¿De qué se trata?'},
    'report_dumping': {'en': 'Illegal dumping', 'es': 'Basura ilegal'},
    'report_roads': {'en': 'Broken street / pothole', 'es': 'Calle dañada / bache'},
    'report_lighting': {'en': 'Broken street light', 'es': 'Luz de calle dañada'},
    'report_water': {'en': 'Water leak / drainage', 'es': 'Fuga de agua / drenaje'},
    'report_unsafe': {'en': 'Unsafe spot', 'es': 'Lugar inseguro'},
    'report_details': {'en': 'Details (no personal info needed)', 'es': 'Detalles (no necesita dar datos personales)'},
    'report_location': {'en': 'Nearest cross streets (optional)', 'es': 'Calles cercanas (opcional)'},
    'submit_report': {'en': 'Submit anonymously', 'es': 'Enviar anónimamente'},
    'report_thanks': {
      'en': 'Thank you. Your report was recorded anonymously.',
      'es': 'Gracias. Su reporte se registró de forma anónima.',
    },
    'my_reports': {'en': 'My reports (this device only)', 'es': 'Mis reportes (solo en este dispositivo)'},
    'no_reports': {'en': 'No reports yet.', 'es': 'Aún no hay reportes.'},
    'cultural_tips': {'en': 'Settling into Texas', 'es': 'Adaptarse a Texas'},
    'cultural_hint': {
      'en': 'Everyday norms and traditions you’ll notice here, explained for newly arrived and multigenerational families.',
      'es': 'Costumbres y tradiciones cotidianas que verá aquí, explicadas para familias recién llegadas y multigeneracionales.',
    },

    // Education
    'education_title': {'en': 'Education & family support', 'es': 'Educación y apoyo familiar'},
    'education_intro': {
      'en': 'Tutoring, libraries, after-school programs, scholarships and college prep across the Valley.',
      'es': 'Tutoría, bibliotecas, programas extraescolares, becas y preparación universitaria en todo el Valle.',
    },
    'edu_k12': {'en': 'K-12 tutoring & help', 'es': 'Tutoría y apoyo K-12'},
    'edu_library': {'en': 'Libraries', 'es': 'Bibliotecas'},
    'edu_afterschool': {'en': 'After-school & activities', 'es': 'Extraescolares y actividades'},
    'edu_scholarship': {'en': 'Scholarships', 'es': 'Becas'},
    'edu_college': {'en': 'College prep', 'es': 'Preparación universitaria'},
    'edu_esl': {'en': 'English (ESL) classes', 'es': 'Clases de inglés (ESL)'},
    'edu_deadline': {'en': 'Deadline', 'es': 'Fecha límite'},
    'edu_amount': {'en': 'Award', 'es': 'Monto'},
    'edu_eligible': {'en': 'Who can apply', 'es': 'Quién puede aplicar'},
    'edu_for': {'en': 'Good for', 'es': 'Ideal para'},
    'filter_all': {'en': 'All', 'es': 'Todo'},

    // Settings / profile
    'settings': {'en': 'Settings', 'es': 'Ajustes'},
    'language': {'en': 'Language', 'es': 'Idioma'},
    'reminders': {'en': 'Visit reminders', 'es': 'Recordatorios de citas'},
    'reminders_enable': {'en': 'Enable reminders', 'es': 'Activar recordatorios'},
    'reminders_sub': {
      'en': 'Notify me before upcoming family visits.',
      'es': 'Avísame antes de las próximas citas familiares.',
    },
    'saved_resources': {'en': 'Saved resources', 'es': 'Recursos guardados'},
    'saved_empty': {
      'en': 'Nothing saved yet. Tap the bookmark on a resource to save it.',
      'es': 'Aún no hay nada guardado. Toque el marcador en un recurso para guardarlo.',
    },
    'saved_count': {'en': 'saved', 'es': 'guardados'},
    'about': {'en': 'About', 'es': 'Acerca de'},
    'version': {'en': 'Version', 'es': 'Versión'},
    'region': {'en': 'Region', 'es': 'Región'},
    'disclaimer_label': {'en': 'Disclaimer', 'es': 'Aviso'},
    'about_body': {
      'en': 'Somos 956 is a bilingual community app for the Rio Grande Valley. It brings healthcare, transportation, civic resources, and education together in one place. Data shown may be sample or demo until live feeds are connected.',
      'es': 'Somos 956 es una aplicación comunitaria bilingüe para el Valle del Río Grande. Reúne salud, transporte, recursos cívicos y educación en un solo lugar. Los datos mostrados pueden ser de ejemplo o demo hasta que se conecten fuentes en vivo.',
    },
    'about_text': {
      'en': 'Somos 956 is a bilingual community app for the Rio Grande Valley. It brings healthcare, transportation, civic resources, and education together in one place. Data shown may be sample or demo until live feeds are connected.',
      'es': 'Somos 956 es una aplicación comunitaria bilingüe para el Valle del Río Grande. Reúne salud, transporte, recursos cívicos y educación en un solo lugar. Los datos mostrados pueden ser de ejemplo o demo hasta que se conecten fuentes en vivo.',
    },
    'disclaimer': {
      'en': 'Not a substitute for professional medical, legal, or financial advice.',
      'es': 'No sustituye el consejo médico, legal o financiero profesional.',
    },

    // Onboarding / language choice
    'onb_choose': {'en': 'Choose your language', 'es': 'Elija su idioma'},
    'onb_subtitle': {
      'en': 'You can change this any time in Settings.',
      'es': 'Puede cambiarlo cuando quiera en Ajustes.',
    },
    'onb_english': {'en': 'English', 'es': 'English'},
    'onb_english_sub': {'en': 'Show everything in English', 'es': 'Todo en inglés'},
    'onb_spanish': {'en': 'Español', 'es': 'Español'},
    'onb_spanish_sub': {'en': 'Todo en español', 'es': 'Show everything in Spanish'},
    'onb_bilingual': {'en': 'Bilingual', 'es': 'Bilingüe'},
    'onb_bilingual_sub': {
      'en': 'English, with Spanish underneath',
      'es': 'Inglés, con español debajo',
    },
    'onb_continue': {'en': 'Continue', 'es': 'Continuar'},
    'onb_welcome': {
      'en': 'Hi, I’m Solecito! Let’s set up your app.',
      'es': '¡Hola, soy Solecito! Vamos a configurar tu app.',
    },
    'lang_mode': {'en': 'Display language', 'es': 'Idioma de pantalla'},
    'bilingual_show': {'en': 'Show secondary language', 'es': 'Mostrar idioma secundario'},

    // Live data
    'data_live': {'en': 'Live', 'es': 'En vivo'},
    'data_offline': {'en': 'Offline', 'es': 'Sin conexión'},
    'data_connecting': {'en': 'Connecting…', 'es': 'Conectando…'},
    'data_source': {'en': 'Source', 'es': 'Fuente'},
    'data_updated_just_now': {'en': 'just now', 'es': 'ahora mismo'},
    'weather': {'en': 'Weather', 'es': 'Clima'},
    'air_quality': {'en': 'Air quality', 'es': 'Calidad del aire'},
    'alerts': {'en': 'Alerts', 'es': 'Alertas'},
    'no_alerts': {'en': 'No active alerts', 'es': 'Sin alertas activas'},
    'feels_like': {'en': 'Feels like', 'es': 'Sensación'},
    'humidity': {'en': 'Humidity', 'es': 'Humedad'},
    'wind': {'en': 'Wind', 'es': 'Viento'},
    'aqi_good': {'en': 'Good', 'es': 'Buena'},
    'aqi_moderate': {'en': 'Moderate', 'es': 'Moderada'},
    'aqi_unhealthy_sensitive': {'en': 'Unhealthy for sensitive groups', 'es': 'Dañina para grupos sensibles'},
    'aqi_unhealthy': {'en': 'Unhealthy', 'es': 'Dañina'},
    'aqi_very_unhealthy': {'en': 'Very unhealthy', 'es': 'Muy dañina'},
    'aqi_hazardous': {'en': 'Hazardous', 'es': 'Peligrosa'},
    'heat_index': {'en': 'Heat index', 'es': 'Índice de calor'},
    'today_forecast': {'en': 'Today', 'es': 'Hoy'},
    'road_closures': {'en': 'Road conditions & closures', 'es': 'Condiciones y cierres de carreteras'},
    'no_closures': {'en': 'No reported closures right now', 'es': 'Sin cierres reportados ahora'},
    'live_now': {'en': 'Live now', 'es': 'En vivo ahora'},
    'refreshing': {'en': 'Refreshing…', 'es': 'Actualizando…'},
    'try_again': {'en': 'Try again', 'es': 'Reintentar'},
    'load_error': {
      'en': 'Couldn’t reach the live feed. Showing the best available info.',
      'es': 'No se pudo conectar a la fuente en vivo. Mostrando la mejor información disponible.',
    },
    'my_location': {'en': 'My area', 'es': 'Mi zona'},
    'location_prompt': {'en': 'Use your location', 'es': 'Use su ubicación'},
    'location_hint': {
      'en': 'See distances and get directions from where you are.',
      'es': 'Vea distancias y obtenga indicaciones desde donde está.',
    },
    'location_blocked': {'en': 'Location is off', 'es': 'Ubicación desactivada'},
    'location_blocked_hint': {
      'en': 'Enable location in your browser/device settings to get distances and directions.',
      'es': 'Active la ubicación en su navegador o dispositivo para ver distancias e indicaciones.',
    },
    'nearest_to_you': {'en': 'Nearest to you', 'es': 'Más cercanos a usted'},
    'fastest_now': {'en': 'Fastest right now', 'es': 'Más rápidos ahora'},
    'mi_away': {'en': 'mi away', 'es': 'mi de distancia'},
    'open_maps': {'en': 'Open in Maps', 'es': 'Abrir en Mapas'},
    'lanes_closed': {'en': 'Lanes closed', 'es': 'Carriles cerrados'},
    'est_wait': {'en': 'estimated', 'es': 'estimado'},
    'port_status': {'en': 'Port status', 'es': 'Estado del puerto'},
    'nearest_bridge': {'en': 'Nearest bridge', 'es': 'Puente más cercano'},
    'pick_location': {'en': 'Pick on map', 'es': 'Elegir en mapa'},
    'pick_location_title': {
      'en': 'Choose your location',
      'es': 'Elija su ubicación',
    },
    'pick_location_hint': {
      'en': 'Tap the map to drop a pin, or use your current location.',
      'es': 'Toque el mapa para poner un pin, o use su ubicación actual.',
    },
    'use_current_location': {
      'en': 'Use current location',
      'es': 'Usar ubicación actual',
    },
    'set_location': {'en': 'Set location', 'es': 'Establecer ubicación'},
    'clear_location': {'en': 'Clear pin', 'es': 'Quitar pin'},
    'location_set': {'en': 'Location set', 'es': 'Ubicación establecida'},
    'manual_location': {'en': 'Pinned on map', 'es': 'Fijado en el mapa'},
    'cancel': {'en': 'Cancel', 'es': 'Cancelar'},
  };
}
