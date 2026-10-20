import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../l10n.dart';
import '../models.dart';

Color heatColor(HeatLevel level) {
  switch (level) {
    case HeatLevel.normal:
      return const Color(0xFF2E7D32);
    case HeatLevel.caution:
      return const Color(0xFFF9A825);
    case HeatLevel.extreme:
      return const Color(0xFFEF6C00);
    case HeatLevel.danger:
      return const Color(0xFFC62828);
  }
}

Color severityColor(int severity) {
  switch (severity) {
    case 3:
      return const Color(0xFFC62828);
    case 2:
      return const Color(0xFFEF6C00);
    default:
      return const Color(0xFFF9A825);
  }
}

String severityLabel(BuildContext context, int severity) {
  final s = S.of(context);
  if (severity >= 3) return s.t('severity_closed');
  if (severity == 2) return s.t('severity_high');
  return s.t('severity_medium');
}

String fmtTime(DateTime t) {
  final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
  final m = t.minute.toString().padLeft(2, '0');
  return '$h:$m ${t.hour < 12 ? 'AM' : 'PM'}';
}

class LiveBadge extends StatelessWidget {
  final bool live;
  const LiveBadge({super.key, required this.live});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: (live ? Colors.green : Colors.blueGrey).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: live ? Colors.green.shade700 : Colors.blueGrey.shade700, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(live ? Icons.cell_tower : Icons.science_outlined,
              size: 12, color: live ? Colors.green.shade800 : Colors.blueGrey.shade800),
          const SizedBox(width: 4),
          Text(
            live ? s.t('live') : s.t('demo'),
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

class SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final Widget child;
  final EdgeInsets padding;

  const SectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(16, 12, 16, 16),
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                if (trailing case final trailing?) trailing,
              ],
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
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
    this.center = const LatLng(25.9017, -97.4975),
    this.zoom = 11.2,
    this.height = 300,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: height,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: center,
            initialZoom: zoom,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'org.rgvready.rgv_ready',
            ),
            MarkerLayer(
              markers: [
                for (final m in markers)
                  Marker(
                    point: m.point,
                    width: 38,
                    height: 38,
                    alignment: Alignment.topCenter,
                    child: GestureDetector(
                      onTap: m.onTap,
                      child: Container(
                        decoration: BoxDecoration(
                          color: m.color,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 4),
                          ],
                        ),
                        child: Icon(m.icon, color: Colors.white, size: 20),
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

class StageBadge extends StatelessWidget {
  final int stage;
  const StageBadge({super.key, required this.stage});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final (label, color) = switch (stage) {
      0 => (s.t('stage_none'), Colors.green.shade700),
      1 => (s.t('stage1'), Colors.yellow.shade800),
      2 => (s.t('stage2'), Colors.orange.shade800),
      3 => (s.t('stage3'), const Color(0xFFC2410C)),
      _ => (s.t('stage4'), Colors.red.shade800),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        border: Border.all(color: color, width: 1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontWeight: FontWeight.w700, fontSize: 12.5)),
    );
  }
}

class PercentBar extends StatelessWidget {
  final double percent;
  final Color color;
  const PercentBar({super.key, required this.percent, required this.color});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: LinearProgressIndicator(
        value: (percent / 100).clamp(0, 1),
        minHeight: 10,
        backgroundColor: color.withValues(alpha: 0.15),
        valueColor: AlwaysStoppedAnimation(color),
      ),
    );
  }
}
