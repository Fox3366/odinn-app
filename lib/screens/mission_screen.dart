import 'dart:async';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../services/mission_service.dart';
import '../models/mission_waypoint.dart';
import '../widgets/mission_map_widget.dart';
import '../widgets/mission_list_panel.dart';
import '../widgets/mission_toolbar.dart';

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
        _showMessage('Görev başarıyla araca yüklendi!', Colors.green);
      } else if (state == MissionState.error) {
        _showMessage('Görev yükleme başarısız! Detay: ${_missionService.lastError}', Colors.red);
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

  void _addCommandAtLastPos(MissionCommandType type) {
    // Haritada nokta yoksa varsayılan Ankara (veya drone konumu) alınır.
    LatLng pos = _waypoints.isNotEmpty ? _waypoints.last.position : const LatLng(39.920770, 32.854110);
    setState(() {
      _waypoints.add(MissionWaypoint(position: pos, commandType: type));
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
      _showMessage('Lütfen önce görev noktaları belirleyin.', Colors.orange);
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
      // Appbar'ı kaldırıp tam ekran deneyimi sunuyoruz, veya şeffaf bir başlık koyabiliriz.
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Görev Planlayıcı', style: TextStyle(color: Colors.white, shadows: [Shadow(blurRadius: 3, color: Colors.black)])),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // 1. Katman: Tam Ekran Harita
          Positioned.fill(
            child: MissionMapWidget(
              waypoints: _waypoints,
              onMapTap: _addWaypoint,
              onWaypointTap: (idx) {},
            ),
          ),
          
          // 2. Katman: Sol Araç Çubuğu (Toolbar)
          Positioned(
            left: 16,
            top: 100, // AppBar'ın altına hizala
            child: MissionToolbar(
              onAddTakeoff: () => _addCommandAtLastPos(MissionCommandType.takeoff),
              onAddVtolTakeoff: () => _addCommandAtLastPos(MissionCommandType.vtolTakeoff),
              onAddWaypoint: () => _addCommandAtLastPos(MissionCommandType.waypoint),
              onAddTransitionFw: () => _addCommandAtLastPos(MissionCommandType.transitionToFw),
              onAddTransitionMc: () => _addCommandAtLastPos(MissionCommandType.transitionToMc),
              onAddLand: () => _addCommandAtLastPos(MissionCommandType.land),
              onAddVtolLand: () => _addCommandAtLastPos(MissionCommandType.vtolLand),
              onAddRtl: () => _addCommandAtLastPos(MissionCommandType.rtl),
            ),
          ),

          // 3. Katman: Sağ Görev Listesi Paneli
          Positioned(
            right: 16,
            top: 100,
            bottom: 16,
            width: 300, // Genişliği sabitliyoruz
            child: MissionListPanel(
              waypoints: _waypoints,
              onEdit: _editWaypoint,
              onDelete: _deleteWaypoint,
              onClearAll: _clearAll,
              onUpload: _uploadMission,
            ),
          ),

          // Yükleme Göstergesi
          if (_isUploading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Görev Yükleniyor...', style: TextStyle(color: Colors.white, fontSize: 18)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
