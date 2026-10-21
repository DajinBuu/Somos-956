import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../l10n.dart';
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
  final String title;
  final Widget? trailing;
  final Widget child;
  final EdgeInsets padding;
  final String? subtitle;

  const SectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
    this.trailing,
    this.subtitle,
    this.padding = const EdgeInsets.fromLTRB(16, 12, 16, 16),
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
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
                      Text(
                        title,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      if (subtitle != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(subtitle!,
                              style: Theme.of(context).textTheme.bodySmall),
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
