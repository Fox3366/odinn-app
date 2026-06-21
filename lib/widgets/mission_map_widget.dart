import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/mission_service.dart';
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

  LatLng _dronePos = const LatLng(39.92077, 32.85411); // Default Ankara
  double _droneHeading = 0.0;

  @override
  void initState() {
    super.initState();
    _telemetry.telemetryStream.listen((data) {
      if (mounted) {
        setState(() {
          // DroneTelemetry objesinde lat/lon olmadigi icin MavlinkService'den aliyoruz.
          if (_mavlink.droneLat != 0.0 && _mavlink.droneLon != 0.0) {
            _dronePos = LatLng(_mavlink.droneLat, _mavlink.droneLon);
          }
          _droneHeading = data.heading.toDouble();
        });
      }
    });
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

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _dronePos,
        initialZoom: 15.0,
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
    );
  }
}
