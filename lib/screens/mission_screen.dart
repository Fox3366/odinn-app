import 'dart:async';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../services/mission_service.dart';
import '../widgets/mission_map_widget.dart';
import '../widgets/mission_list_panel.dart';

class MissionScreen extends StatefulWidget {
  const MissionScreen({super.key});

  @override
  State<MissionScreen> createState() => _MissionScreenState();
}

class _MissionScreenState extends State<MissionScreen> {
  final MissionService _missionService = MissionService();
  final List<MissionWaypoint> _waypoints = [];
  StreamSubscription? _stateSub;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _stateSub = _missionService.stateStream.listen((state) {
      if (!mounted) return;
      setState(() {
        _isUploading = (state == MissionState.uploading);
      });

      if (state == MissionState.success) {
        _showMessage('Gorev basariyla araca yuklendi!', Colors.green);
      } else if (state == MissionState.error) {
        _showMessage('Gorev yukleme basarisiz oldu (Timeout).', Colors.red);
      }
    });
  }

  void _showMessage(String text, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), backgroundColor: color, duration: const Duration(seconds: 3)),
    );
  }

  void _addWaypoint(LatLng point) {
    setState(() {
      _waypoints.add(MissionWaypoint(position: point, altitude: 50.0));
    });
  }

  void _editWaypoint(int index, MissionCommandType type, double alt, double param1) {
    setState(() {
      _waypoints[index].commandType = type;
      _waypoints[index].altitude = alt;
      _waypoints[index].param1 = param1;
    });
  }

  void _deleteWaypoint(int index) {
    setState(() {
      _waypoints.removeAt(index);
    });
  }

  void _clearAll() {
    setState(() {
      _waypoints.clear();
    });
  }

  void _uploadMission() {
    if (_waypoints.isEmpty) {
      _showMessage('Lutfen once haritaya tiklayarak gorev noktalari belirleyin.', Colors.orange);
      return;
    }
    _missionService.uploadMission(_waypoints);
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gorev Planlayici (Map)'),
        backgroundColor: Colors.blueGrey[900],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: MissionMapWidget(
                  waypoints: _waypoints,
                  onMapTap: _addWaypoint,
                  onWaypointTap: (idx) {
                    // Marker'a tklannca zel bir eylem yaplabilir (rnein silme/editleme)
                  },
                ),
              ),
              MissionListPanel(
                waypoints: _waypoints,
                onEdit: _editWaypoint,
                onDelete: _deleteWaypoint,
                onClearAll: _clearAll,
                onUpload: _uploadMission,
              ),
            ],
          ),
          if (_isUploading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Gorev Yukleniyor...', style: TextStyle(color: Colors.white, fontSize: 18)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
