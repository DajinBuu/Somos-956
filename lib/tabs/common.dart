import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../l10n.dart';
import '../location.dart';
import '../widgets/mascot.dart';

Color healthCareColor(int type) {
  switch (type) {
    case 0:
      return const Color(0xFFC62828); // hospital
    case 1:
      return const Color(0xFFEF6C00); // urgent
    case 2:
      return const Color(0xFF0E7490); // clinic
    default:
      return const Color(0xFF6A1B9A); // pharmacy
  }
}

Color levelColor(int index) {
  const c = [
    Color(0xFF2E7D32),
    Color(0xFFF9A825),
    Color(0xFFEF6C00),
    Color(0xFFC62828),
  ];
  return c[index.clamp(0, 3)];
}

String fmtTime(DateTime t) {
  final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
  final m = t.minute.toString().padLeft(2, '0');
  return '$h:$m ${t.hour < 12 ? 'AM' : 'PM'}';
}

String fmtDate(DateTime t, bool es) {
  const en = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  const sp = [
    'ene', 'feb', 'mar', 'abr', 'may', 'jun',
    'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
  ];
  final m = (es ? sp : en)[t.month - 1];
  return '$m ${t.day}, ${t.year}';
}

class LiveBadge extends StatelessWidget {
  final bool live;
  final String? label;
  const LiveBadge({super.key, required this.live, this.label});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: (live ? Colors.green : Colors.blueGrey).withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: live ? Colors.green.shade700 : Colors.blueGrey.shade700,
            width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(live ? Icons.cell_tower : Icons.science_outlined,
              size: 12,
              color: live ? Colors.green.shade800 : Colors.blueGrey.shade800),
          const SizedBox(width: 4),
          Text(
            label ?? (live ? s.t('live') : s.t('demo')),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: live ? Colors.green.shade800 : Colors.blueGrey.shade800,
            ),
          ),
        ],
      ),
    );
  }
}

class AiBadge extends StatelessWidget {
  final String? label;
  const AiBadge({super.key, this.label});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF6A1B9A).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF6A1B9A), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_awesome, size: 12, color: Color(0xFF6A1B9A)),
          const SizedBox(width: 4),
          Text(
            label ?? s.t('predicted'),
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6A1B9A)),
          ),
        ],
      ),
    );
  }
}

class SectionCard extends StatelessWidget {
  final IconData icon;
  /// Translation key (unless [rawTitle] is set).
  final String title;
  final bool rawTitle;
  final Widget? trailing;
  final Widget child;
  final EdgeInsets padding;
  /// Translation key for the subtitle.
  final String? subtitle;

  const SectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
    this.rawTitle = false,
    this.trailing,
    this.subtitle,
    this.padding = const EdgeInsets.fromLTRB(16, 12, 16, 16),
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final s = S.of(context);
    final titleWidget = rawTitle
        ? Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          )
        : s.tk(title);
    return Card(
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, color: scheme.primary, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      titleWidget,
                      if (subtitle != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: s.tk(subtitle!, size: 12.5),
                        ),
                    ],
                  ),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

/// A friendly empty-state placeholder featuring the mascot.
class EmptyState extends StatelessWidget {
  final String message;
  final MascotMood mood;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.message,
    this.mood = MascotMood.happy,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      child: Column(
        children: [
          Mascot(size: 74, mood: mood),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: onAction,
              icon: const Icon(Icons.add, size: 18),
              label: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

class MapMarker {
  final LatLng point;
  final Color color;
  final IconData icon;
  final String label;
  final void Function()? onTap;
  const MapMarker({
    required this.point,
    required this.color,
    required this.icon,
    required this.label,
    this.onTap,
  });
}

class MapPane extends StatelessWidget {
  final List<MapMarker> markers;
  final LatLng center;
  final double zoom;
  final double height;

  const MapPane({
    super.key,
    required this.markers,
    this.center = const LatLng(kValleyCenterLat, kValleyCenterLon),
    this.zoom = 9.4,
    this.height = 320,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: height,
        child: FlutterMap(
          options: MapOptions(initialCenter: center, initialZoom: zoom),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'org.somos956.somos_956',
            ),
            MarkerLayer(
              markers: [
                for (final m in markers)
                  Marker(
                    point: m.point,
                    width: 34,
                    height: 34,
                    alignment: Alignment.topCenter,
                    child: GestureDetector(
                      onTap: m.onTap,
                      child: Tooltip(
                        message: m.label,
                        child: Container(
                          decoration: BoxDecoration(
                            color: m.color,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: const [
                              BoxShadow(color: Colors.black26, blurRadius: 4),
                            ],
                          ),
                          child: Icon(m.icon, color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

const kValleyCenterLat = 26.2034;
const kValleyCenterLon = -98.2300;

/// Opens a bottom sheet where the user can drop a pin on the map (or use their
/// current GPS location) to choose the location distances are measured from.
Future<void> showLocationPicker(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _LocationPickerSheet(),
  );
}

class _LocationPickerSheet extends StatefulWidget {
  const _LocationPickerSheet();

  @override
  State<_LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<_LocationPickerSheet> {
  final _controller = MapController();
  LatLng? _pin;
  bool _gpsBusy = false;

  @override
  void initState() {
    super.initState();
    if (locationService.hasFix) {
      final (lat, lon) = locationService.reference;
      _pin = LatLng(lat, lon);
    }
  }

  Future<void> _useGps() async {
    setState(() => _gpsBusy = true);
    locationService.clearManual();
    final p = await locationService.ensure();
    if (!mounted) return;
    setState(() {
      _gpsBusy = false;
      _pin = LatLng(
        p?.latitude ?? locationService.reference.$1,
        p?.longitude ?? locationService.reference.$2,
      );
    });
    _controller.move(_pin!, 12);
  }

  void _save() {
    final pin = _pin;
    if (pin == null) return;
    locationService.setManual(pin.latitude, pin.longitude);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(S.of(context).t('location_set'))),
    );
  }

  void _clear() {
    locationService.clearManual();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final (clat, clon) = locationService.reference;
    final center = _pin ?? LatLng(clat, clon);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.pin_drop, color: Color(0xFF0E7490)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(s.t('pick_location_title'),
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(s.t('pick_location_hint'),
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 320,
                child: FlutterMap(
                  mapController: _controller,
                  options: MapOptions(
                    initialCenter: center,
                    initialZoom: 11,
                    onTap: (_, point) => setState(() => _pin = point),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'org.somos956.somos_956',
                    ),
                    if (_pin != null)
                      MarkerLayer(markers: [
                        Marker(
                          point: _pin!,
                          width: 40,
                          height: 40,
                          alignment: Alignment.topCenter,
                          child: const Icon(Icons.location_on,
                              color: Color(0xFFC62828), size: 40),
                        ),
                      ]),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _gpsBusy ? null : _useGps,
                  icon: _gpsBusy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.my_location, size: 18),
                  label: Text(s.t('use_current_location')),
                ),
                const Spacer(),
                if (locationService.isManual)
                  TextButton(
                    onPressed: _clear,
                    child: Text(s.t('clear_location')),
                  ),
                const SizedBox(width: 4),
                FilledButton.icon(
                  onPressed: _pin == null ? null : _save,
                  icon: const Icon(Icons.check, size: 18),
                  label: Text(s.t('set_location')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const InfoTile({super.key, required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: Theme.of(context).colorScheme.secondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(TextSpan(children: [
              TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              TextSpan(text: value),
            ])),
          ),
        ],
      ),
    );
  }
}
