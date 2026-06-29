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
  List<MissionWaypoint> get currentMission => _currentMission;
  Timer? _timeoutTimer;
  int _retryCount = 0;
  static const int _maxRetryCount = 5;
  int _lastRequestedSeq = -1;
  bool _waitingForCountAck = false;

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
    
    // QGC Standartları: İlk nokta (Sequence 0) doğrudan kullanıcının noktasıdır.
    _currentMission = List.from(waypoints);
    _setState(MissionState.uploading);
    lastError = 'Zaman Aşımı (Timeout) - Drone yanıt vermedi';
    _retryCount = 0;
    _lastRequestedSeq = -1;
    _waitingForCountAck = true;

    _writeMissionCount();
  }

  void _writeMissionCount() {
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
      _waitingForCountAck = false;
      
      int seq = 0;
      if (msg is MissionRequestInt) seq = msg.seq;
      if (msg is MissionRequest) seq = msg.seq;

      if (seq >= 0 && seq < _currentMission.length) {
        _retryCount = 0;
        _lastRequestedSeq = seq;
        _sendMissionItem(seq);
      } else {
        lastError = 'Geçersiz Sequence İstendi: $seq';
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
    
    int frame = 6; // MAV_FRAME_GLOBAL_RELATIVE_ALT_INT by default
    double p1 = wp.param1;
    double p2 = wp.param2;
    double p3 = wp.param3;
    double p4 = wp.param4;
    int x = (wp.position.latitude * 1e7).toInt();
    int y = (wp.position.longitude * 1e7).toInt();
    double z = wp.altitude;

    // QGC Standartlarına Göre Parametre ve Frame Düzenlemesi
    if (wp.commandType == MissionCommandType.transitionToFw || 
        wp.commandType == MissionCommandType.transitionToMc) {
      // DO komutları (Transition) MAV_FRAME_MISSION (2) kullanır ve x, y, z sıfırdır.
      frame = 2;
      x = 0; y = 0; z = 0.0;
      p1 = (wp.commandType == MissionCommandType.transitionToFw) ? 3.0 : 4.0;
    } else if (wp.commandType == MissionCommandType.rtl) {
      // RTL genelde konumsuz bir MAV_FRAME_MISSION komutudur.
      frame = 2;
      x = 0; y = 0; z = 0.0;
    } else if (wp.commandType == MissionCommandType.vtolTakeoff) {
      // VTOL Takeoff için param2 heading olabilir, bizde yaw (param4) ve altitude önemli.
      // QGC'ye uyumlu olması için sadece altitude ve yaw gönderiliyor (zaten wp'de var).
    }

    _mavlink.sendMessage(MissionItemInt(
      targetSystem: _mavlink.droneSystemId ?? 1,
      targetComponent: _mavlink.droneComponentId ?? 1,
      seq: seq,
      frame: frame, 
      command: wp.commandType.mavCmd,
      current: seq == 0 ? 1 : 0,
      autocontinue: wp.autoContinue ? 1 : 0,
      param1: p1, 
      param2: p2,
      param3: p3, 
      param4: p4, 
      x: x,
      y: y,
      z: z,
      missionType: 0,
    ));
    
    _startTimeout(); // MAVLink paketini gönderdikten sonra timeout başlat
  }

  void _startTimeout() {
    _timeoutTimer?.cancel();
    // QGC 1000ms timeout bekler, cevap gelmezse tekrar gönderir (5 kez).
    _timeoutTimer = Timer(const Duration(milliseconds: 1000), () {
      if (_retryCount < _maxRetryCount) {
        _retryCount++;
        if (_waitingForCountAck) {
          _writeMissionCount(); // count mesajını tekrarla
        } else if (_lastRequestedSeq >= 0) {
          // sadece son item gönderildiyse _lastRequestedSeq >= 0'dır, mesajı tekrarla.
          // NOT: _sendMissionItem zaten içinde _startTimeout() çağırıyor, bu yüzden timer sıfırlanacak.
          _sendMissionItem(_lastRequestedSeq); 
        }
      } else {
        lastError = 'Bağlantı zayıf: Pakete cevap alınamadı ($_maxRetryCount deneme)';
        _setState(MissionState.error);
      }
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
