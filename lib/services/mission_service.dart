import 'dart:async';
import 'package:dart_mavlink/mavlink.dart';
import 'package:dart_mavlink/dialects/common.dart';
import 'mavlink_service.dart';
import 'package:latlong2/latlong.dart';

enum MissionState {
  idle,
  uploading,
  success,
  error
}

enum MissionCommandType {
  waypoint,
  takeoff,
  land,
  rtl,
  loiterUnlim,
  loiterTime,
  roi,
  transitionToFw,
  transitionToMc
}

extension MissionCommandTypeExtension on MissionCommandType {
  int get mavCmd {
    switch (this) {
      case MissionCommandType.waypoint: return 16;
      case MissionCommandType.takeoff: return 22;
      case MissionCommandType.land: return 21;
      case MissionCommandType.rtl: return 20;
      case MissionCommandType.loiterUnlim: return 17;
      case MissionCommandType.loiterTime: return 19;
      case MissionCommandType.roi: return 195;
      case MissionCommandType.transitionToFw: return 3000;
      case MissionCommandType.transitionToMc: return 3000;
    }
  }

  String get label {
    switch (this) {
      case MissionCommandType.waypoint: return 'Ara Nokta (Git)';
      case MissionCommandType.takeoff: return 'Kalkış Yap';
      case MissionCommandType.land: return 'İniş Yap';
      case MissionCommandType.rtl: return 'Eve Dönüş (RTL)';
      case MissionCommandType.loiterUnlim: return 'Süresiz Bekleme (Daire)';
      case MissionCommandType.loiterTime: return 'Süreli Bekleme';
      case MissionCommandType.roi: return 'Kamerayı Çevir (ROI)';
      case MissionCommandType.transitionToFw: return 'Sabit Kanata Geç (FW)';
      case MissionCommandType.transitionToMc: return 'Multikoptere Geç (MC)';
    }
  }
}

class MissionWaypoint {
  final LatLng position;
  double altitude;
  MissionCommandType commandType;
  double param1; // Used for hold time, delay, etc.

  MissionWaypoint({
    required this.position, 
    this.altitude = 50.0,
    this.commandType = MissionCommandType.waypoint,
    this.param1 = 0.0,
  });
}

class MissionService {
  static final MissionService _instance = MissionService._internal();
  factory MissionService() => _instance;

  final MavlinkService _mavlink = MavlinkService();
  StreamSubscription? _frameSub;

  final _stateCtrl = StreamController<MissionState>.broadcast();
  Stream<MissionState> get stateStream => _stateCtrl.stream;
  MissionState _currentState = MissionState.idle;

  List<MissionWaypoint> _currentMission = [];
  Timer? _timeoutTimer;

  MissionService._internal() {
    _frameSub = _mavlink.rawFrameStream.listen(_onFrame);
  }

  void _setState(MissionState state) {
    _currentState = state;
    _stateCtrl.add(state);
  }

  /// Start mission upload protocol
  void uploadMission(List<MissionWaypoint> waypoints) {
    if (waypoints.isEmpty) return;
    
    // We add a dummy HOME waypoint at index 0 (QGC standard behavior)
    // PX4 usually expects item 0 to be home or the first actual waypoint
    _currentMission = waypoints;
    _setState(MissionState.uploading);

    // Send MISSION_COUNT
    _mavlink.sendMessage(MissionCount(
      targetSystem: _mavlink.droneSystemId ?? 1,
      targetComponent: _mavlink.droneComponentId ?? 1,
      count: _currentMission.length,
      missionType: 0, // MAV_MISSION_TYPE_MISSION
      opaqueId: 0,
    ));

    _startTimeout();
  }

  void _onFrame(MavlinkFrame frame) {
    if (_currentState != MissionState.uploading) return;

    final msg = frame.message;

    if (msg is MissionRequestInt || msg is MissionRequest) {
      _clearTimeout();
      int seq = 0;
      if (msg is MissionRequestInt) seq = msg.seq;
      if (msg is MissionRequest) seq = msg.seq;

      if (seq >= 0 && seq < _currentMission.length) {
        _sendMissionItem(seq);
        _startTimeout();
      } else {
        // Invalid sequence requested
        _setState(MissionState.error);
      }
    } else if (msg is MissionAck) {
      _clearTimeout();
      if (msg.type == 0) { // MAV_MISSION_ACCEPTED
        _setState(MissionState.success);
        // Reset to idle after a short delay
        Future.delayed(const Duration(seconds: 2), () {
          if (_currentState == MissionState.success) {
            _setState(MissionState.idle);
          }
        });
      } else {
        _setState(MissionState.error);
      }
    }
  }

  void _sendMissionItem(int seq) {
    final wp = _currentMission[seq];
    
    _mavlink.sendMessage(MissionItemInt(
      targetSystem: _mavlink.droneSystemId ?? 1,
      targetComponent: _mavlink.droneComponentId ?? 1,
      seq: seq,
      frame: 6, // MAV_FRAME_GLOBAL_RELATIVE_ALT_INT
      command: wp.commandType.mavCmd, // Get from selected command type
      current: seq == 0 ? 1 : 0,
      autocontinue: 1,
      param1: (wp.commandType == MissionCommandType.transitionToFw) ? 3.0 :
              (wp.commandType == MissionCommandType.transitionToMc) ? 4.0 :
              wp.param1, // Custom param (e.g. hold time)
      param2: 0, // Accept radius
      param3: 0, // Pass radius
      param4: double.nan, // Yaw (NaN uses default)
      x: (wp.position.latitude * 1e7).toInt(),
      y: (wp.position.longitude * 1e7).toInt(),
      z: wp.altitude,
      missionType: 0,
    ));
  }

  void _startTimeout() {
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(const Duration(seconds: 3), () {
      _setState(MissionState.error);
    });
  }

  void _clearTimeout() {
    _timeoutTimer?.cancel();
  }

  void dispose() {
    _frameSub?.cancel();
    _timeoutTimer?.cancel();
    _stateCtrl.close();
  }
}
