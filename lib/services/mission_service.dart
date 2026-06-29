import 'dart:async';
import 'package:dart_mavlink/mavlink.dart';
import 'package:dart_mavlink/dialects/common.dart';
import 'mavlink_service.dart';
import '../models/mission_waypoint.dart';

enum MissionState {
  idle,
  uploading,
  success,
  error
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

  String lastError = '';

  /// Start mission upload protocol
  void uploadMission(List<MissionWaypoint> waypoints) {
    if (waypoints.isEmpty) return;
    
    // QGC Standartları: PX4 otopilotu için ilk (home) nokta gönderilmez.
    // Kullanıcının haritada eklediği İLK nokta doğrudan Sequence 0 olarak gönderilir.
    _currentMission = List.from(waypoints);
    _setState(MissionState.uploading);
    lastError = 'Zaman Aşımı (Timeout) - Drone yanıt vermedi';

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
        lastError = 'Drone reddetti. Hata Kodu: ${msg.type}';
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
      frame: wp.frame, // Genelde MAV_FRAME_GLOBAL_RELATIVE_ALT_INT (6)
      command: wp.commandType.mavCmd,
      current: seq == 0 ? 1 : 0,
      autocontinue: wp.autoContinue ? 1 : 0,
      param1: wp.param1, 
      param2: wp.param2,
      param3: wp.param3, 
      param4: wp.param4, 
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
