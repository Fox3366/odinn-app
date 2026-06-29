import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/mission_waypoint.dart';
import '../services/telemetry_service.dart';
import '../services/mavlink_service.dart';

class MissionMapWidget extends StatefulWidget {
  final List<MissionWaypoint> waypoints;
  final Function(LatLng) onMapTap;
  final Function(int) onWaypointTap;
  
  const MissionMapWidget({
    super.key,
    required this.waypoints,
    required this.onMapTap,
    required this.onWaypointTap,
  });

  @override
  State<MissionMapWidget> createState() => _MissionMapWidgetState();
}

class _MissionMapWidgetState extends State<MissionMapWidget> {
  final MapController _mapController = MapController();
  final TelemetryService _telemetry = TelemetryService();
  final MavlinkService _mavlink = MavlinkService();

  LatLng _dronePos = const LatLng(39.92077, 32.85411); // Varsayilan Ankara
  double _droneHeading = 0.0;
  bool _isAutoCenter = true;
  bool _hasInitialFix = false;

  @override
  void initState() {
    super.initState();
    _telemetry.telemetryStream.listen((data) {
      if (mounted) {
        setState(() {
          if (_mavlink.droneLat != 0.0 && _mavlink.droneLon != 0.0) {
            final newPos = LatLng(_mavlink.droneLat, _mavlink.droneLon);
            _dronePos = newPos;
            
            // Ilk fix alindiginda veya autoCenter aciksa haritayi tasi
            if (!_hasInitialFix || _isAutoCenter) {
              _hasInitialFix = true;
              // Harita tamamen yuklenmediyse diye try-catch icine aliyoruz
              try {
                _mapController.move(_dronePos, _mapController.camera.zoom);
              } catch (e) {
                // Ignore if camera is not ready
              }
            }
          }
          _droneHeading = data.heading.toDouble();
        });
      }
    });
  }

  void _recenter() {
    setState(() {
      _isAutoCenter = true;
    });
    try {
      _mapController.move(_dronePos, 16.0);
    } catch (e) {
      // Ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Marker> markers = [];
    List<LatLng> points = [];

    // Drone Marker
    markers.add(
      Marker(
        point: _dronePos,
        width: 60,
        height: 60,
        child: Transform.rotate(
          angle: _droneHeading * (3.1415926535 / 180.0),
          child: const Icon(Icons.navigation, color: Colors.redAccent, size: 40),
        ),
      )
    );

    // Waypoint Markers
    for (int i = 0; i < widget.waypoints.length; i++) {
      final wp = widget.waypoints[i];
      points.add(wp.position);
      markers.add(
        Marker(
          point: wp.position,
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: () => widget.onWaypointTap(i),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          )
        )
      );
    }

    // Yön Okları (Directional Arrows)
    const distanceCalc = Distance();
    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      
      final dist = distanceCalc(p1, p2);
      // Sadece 5 metreden uzak noktalar arasına ok çiz (iç içe binmemesi için)
      if (dist > 5.0) {
        final bearing = distanceCalc.bearing(p1, p2);
        final midpoint = distanceCalc.offset(p1, dist / 2, bearing);
        
        markers.add(
          Marker(
            point: midpoint,
            width: 40,
            height: 40,
            child: IgnorePointer(
              child: Transform.rotate(
                angle: bearing * (math.pi / 180.0),
                child: const Icon(Icons.arrow_upward_rounded, color: Colors.blueAccent, size: 40),
              ),
            ),
          )
        );
      }
    }

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _dronePos,
            initialZoom: 15.0,
            onPositionChanged: (pos, hasGesture) {
              if (hasGesture) {
                setState(() {
                  _isAutoCenter = false;
                });
              }
            },
            onTap: (tapPosition, point) => widget.onMapTap(point),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.muninn.iha',
            ),
            PolylineLayer(
              polylines: [
                Polyline(
                  points: points,
                  strokeWidth: 4.0,
                  color: Colors.blueAccent,
                )
              ],
            ),
            MarkerLayer(markers: markers),
          ],
        ),
        
        // Auto-center Toggle Button
        Positioned(
          bottom: 20,
          right: 20,
          child: FloatingActionButton(
            backgroundColor: _isAutoCenter ? Colors.blue : Colors.blueGrey,
            onPressed: _recenter,
            child: Icon(_isAutoCenter ? Icons.gps_fixed : Icons.gps_not_fixed, color: Colors.white),
          ),
        ),
      ],
    );
  }
}
