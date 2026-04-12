import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants.dart';
import '../../../core/theme.dart';
import '../../../models/facility.dart';
import '../../../models/inspection.dart';

/// Displays an OSM map with custom teardrop markers for each facility.
/// Marker color is driven by the facility's latest inspection grade
/// (spec §4.2). Urgent-flagged facilities get a pulsing ring overlay.
class DistrictMap extends StatefulWidget {
  final List<Facility> facilities;
  final Map<String, Inspection> inspectionsByFacilityId;
  final LatLng? center;
  final double initialZoom;
  final ValueChanged<Facility>? onFacilityTap;
  final Facility? selected;

  const DistrictMap({
    super.key,
    required this.facilities,
    required this.inspectionsByFacilityId,
    this.center,
    this.initialZoom = AppConstants.districtInitialZoom,
    this.onFacilityTap,
    this.selected,
  });

  @override
  State<DistrictMap> createState() => _DistrictMapState();
}

class _DistrictMapState extends State<DistrictMap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final center = widget.center ??
        const LatLng(
          AppConstants.districtCenterLat,
          AppConstants.districtCenterLng,
        );

    return LayoutBuilder(
      builder: (context, constraints) {
        // Guarantee tight finite constraints before handing off to
        // flutter_map. Without this, loose or unbounded constraints cause
        // the map's internal hit-test MouseRegions to be zero-sized during
        // the first frame, which trips mouse_tracker assertions on hover.
        final width = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final height = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : MediaQuery.sizeOf(context).height * 0.55;
        if (width <= 0 || height <= 0) {
          return const SizedBox.shrink();
        }
        return SizedBox(
          width: width,
          height: height,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              fit: StackFit.expand,
              children: [
                FlutterMap(
                  options: MapOptions(
                    initialCenter: center,
                    initialZoom: widget.initialZoom,
                    minZoom: 8,
                    maxZoom: 16,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.drag |
                          InteractiveFlag.pinchZoom |
                          InteractiveFlag.doubleTapZoom |
                          InteractiveFlag.scrollWheelZoom,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'in.gov.yadadri.fimms_demo',
                      maxZoom: 19,
                    ),
                    AnimatedBuilder(
                      animation: _pulse,
                      builder: (context, _) {
                        return MarkerLayer(
                          markers: [
                            for (final f in widget.facilities)
                              _buildMarker(context, f),
                          ],
                        );
                      },
                    ),
                    const _AttributionLayer(),
                  ],
                ),
                // Decorative border drawn ABOVE the map; IgnorePointer
                // keeps mouse events from hitting this layer so the map's
                // gestures still work.
                const IgnorePointer(
                  child: _MapBorder(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Marker _buildMarker(BuildContext context, Facility f) {
    final inspection = widget.inspectionsByFacilityId[f.id];
    final grade = inspection?.grade ?? Grade.average;
    final color = grade.color;
    final urgent = inspection?.urgentFlag ?? false;
    final isSelected = widget.selected?.id == f.id;

    return Marker(
      point: f.location,
      width: 46,
      height: 52,
      alignment: Alignment.topCenter,
      child: GestureDetector(
        onTap: () => widget.onFacilityTap?.call(f),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (urgent)
              Positioned(
                bottom: 4,
                child: Container(
                  width: 36 + (_pulse.value * 14),
                  height: 36 + (_pulse.value * 14),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: FimmsColors.secondary
                          .withValues(alpha: 1 - _pulse.value),
                      width: 2,
                    ),
                  ),
                ),
              ),
            Positioned(
              bottom: 0,
              child: _Teardrop(
                color: color,
                type: f.type,
                selected: isSelected,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Teardrop extends StatelessWidget {
  final Color color;
  final FacilityType type;
  final bool selected;

  const _Teardrop({
    required this.color,
    required this.type,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(32, 40),
      painter: _TeardropPainter(
        color: color,
        selected: selected,
      ),
      child: SizedBox(
        width: 32,
        height: 40,
        child: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Icon(
            type == FacilityType.hostel
                ? Icons.house_outlined
                : Icons.local_hospital_outlined,
            size: 16,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _TeardropPainter extends CustomPainter {
  final Color color;
  final bool selected;
  _TeardropPainter({required this.color, required this.selected});

  @override
  void paint(Canvas canvas, Size size) {
    final path = ui.Path();
    final w = size.width;
    final h = size.height;
    final headRadius = w / 2;
    path.moveTo(w / 2, h);
    path.quadraticBezierTo(0, h * 0.55, w / 2 - headRadius, headRadius);
    path.arcToPoint(
      Offset(w / 2 + headRadius, headRadius),
      radius: Radius.circular(headRadius),
      clockwise: true,
    );
    path.quadraticBezierTo(w, h * 0.55, w / 2, h);
    path.close();

    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fill);

    final stroke = Paint()
      ..color = selected ? Colors.white : Colors.white.withValues(alpha: 0.9)
      ..strokeWidth = selected ? 3 : 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, stroke);

    if (selected) {
      final outer = Paint()
        ..color = color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      canvas.drawPath(path, outer);
    }
  }

  @override
  bool shouldRepaint(covariant _TeardropPainter old) =>
      old.color != color || old.selected != selected;
}

class _MapBorder extends StatelessWidget {
  const _MapBorder();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FimmsColors.outline),
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _AttributionLayer extends StatelessWidget {
  const _AttributionLayer();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomRight,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            '© OpenStreetMap contributors',
            style: TextStyle(fontSize: 10, color: FimmsColors.textMuted),
          ),
        ),
      ),
    );
  }
}
