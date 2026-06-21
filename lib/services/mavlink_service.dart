import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

import 'package:dart_mavlink/mavlink.dart';
import 'package:dart_mavlink/dialects/common.dart';

import '../models/command_result.dart';
import 'udp_socket_service.dart';

/// MAVLink paket parse, heartbeat gönderimi ve COMMAND_ACK dinlemesinden sorumludur.
/// Follow Me mantığı FollowService'e taşındı.
/// UDP soket açma UdpSocketService'e taşındı.
class MavlinkService {
  static final MavlinkService _instance = MavlinkService._internal();
  factory MavlinkService() => _instance;
  MavlinkService._internal();

  String _host = '10.0.2.2';
  int    _port = 14540;

  final _udp    = UdpSocketService(port: 14551);
  final _parser = MavlinkParser(MavlinkDialectCommon());

  int _sequence      = 0;
  final int _systemId    = 254;
  final int _componentId = 190;

  int? droneSystemId;
  int? droneComponentId;

  /// Drone'un son bilinen konumu — FollowService tarafından okunur.
  double droneLat = 0.0;
  double droneLon = 0.0;

  // --- Bağlantı stream ---
  final _connCtrl = StreamController<bool>.broadcast();
  Stream<bool> get connectionStream => _connCtrl.stream;
  bool _isConnected = false;
  bool get isConnected => _isConnected;

  // --- ACK stream ---
  final _ackCtrl = StreamController<CommandResult>.broadcast();
  Stream<CommandResult> get commandAckStream => _ackCtrl.stream;

  // --- Raw frame stream (TelemetryService tarafından dinlenir) ---
  final _rawFrameCtrl = StreamController<MavlinkFrame>.broadcast();
  Stream<MavlinkFrame> get rawFrameStream => _rawFrameCtrl.stream;

  Timer? _keepAliveTimer;
  Timer? _timeoutTimer;
  final Map<int, Timer> _pendingCommands = {};

  /// Yalnızca bizim gönderdiğimiz komutlara ait ACK'ler UI'a iletilir.
  static const Set<int> _ownCommands = {21, 22, 34, 176, 192, 400, 3000};

  Future<void> init() async {
    await _udp.bind((dg) => _parser.parse(dg.data));
    _startKeepAlive();
  }

  void setTarget(String host, int port) {
    _host = host;
    _port = port;
  }

  void _startKeepAlive() {
    _keepAliveTimer = Timer.periodic(const Duration(seconds: 1), (_) => sendHeartbeat());
    _parser.stream.listen(_onFrame);
  }

  void _onFrame(MavlinkFrame frame) {
    // TelemetryService'e ham frame ilet
    if (!_rawFrameCtrl.isClosed) _rawFrameCtrl.add(frame);

    if (frame.message is Heartbeat) {
      final hb = frame.message as Heartbeat;
      // Sadece otopilotlardan gelen heartbeat'leri dikkate al (GCS veya MAVProxy'i yoksay)
      // MAV_AUTOPILOT_PX4 = 12, type 6 = GCS
      if (hb.autopilot == 12 && hb.type != 6) {
        droneSystemId    = frame.systemId;
        droneComponentId = frame.componentId;
        _updateConnection(true);
      }
    }
    if (frame.message is GlobalPositionInt) {
      final pos = frame.message as GlobalPositionInt;
      droneLat = pos.lat / 1e7;
      droneLon = pos.lon / 1e7;
    }
    if (frame.message is CommandAck) {
      _handleAck(frame.message as CommandAck);
    }
  }

  void _updateConnection(bool status) {
    if (_isConnected != status) {
      _isConnected = status;
      _connCtrl.add(status);
    }
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(const Duration(seconds: 8), () {
      _isConnected = false;
      _connCtrl.add(false);
    });
  }

  void _handleAck(CommandAck ack) {
    if (!_ownCommands.contains(ack.command)) {
      debugPrint('📨 ACK yoksayıldı — CMD #${ack.command}');
      return;
    }
    
    // Timer'ı iptal et
    _pendingCommands[ack.command]?.cancel();
    _pendingCommands.remove(ack.command);

    final result = CommandResult(
      command: ack.command,
      result:  ack.result,
      label:   _label(ack.command),
    );
    debugPrint('📨 ACK — ${result.label}: ${result.resultText}');
    if (!_ackCtrl.isClosed) _ackCtrl.add(result);
  }

  String _label(int cmd) {
    switch (cmd) {
      case 21:   return 'LAND';
      case 22:   return 'TAKEOFF';
      case 34:   return 'ORBIT';
      case 176:  return 'SET_MODE';
      case 192:  return 'REPOSITION';
      case 400:  return 'ARM/DISARM';
      case 3000: return 'VTOL GEÇİŞ';
      default:   return 'CMD_$cmd';
    }
  }

  // ─── Komut API'si ─────────────────────────────────────────────────────────

  void sendHeartbeat() {
    sendMessage(Heartbeat(
      type: 6, autopilot: 8, baseMode: 0,
      customMode: 0, systemStatus: 4, mavlinkVersion: 3,
    ));
  }
  
  void sendArmDisarm(bool arm) {
    _sendCommand(400, p1: arm ? 1.0 : 0.0);
  }

  void sendLand() => _sendCommand(21);

  /// Takeoff — verilen irtifaya kalkış
  void sendTakeoff(double altitude) {
    if (droneSystemId == null) return;
    sendMessage(CommandLong(
      targetSystem: droneSystemId!, targetComponent: droneComponentId!,
      command: 22, confirmation: 0,
      param1: 0, param2: 0, param3: 0, param4: double.nan,
      param5: double.nan, param6: double.nan, param7: altitude,
    ));
  }

  /// RTL — Return to Launch, PX4'te main_mode = 4 (AUTO), sub_mode = 5 (RTL)
  void sendRtl() => _setPx4Mode(4, 5);

  /// Mission Start — PX4'te main_mode = 4 (AUTO), sub_mode = 4 (MISSION)
  void sendMissionStart() => _setPx4Mode(4, 4);

  /// Loiter (askı) modu — PX4'te main_mode = 4 (AUTO), sub_mode = 3 (LOITER)
  void sendHold() => _setPx4Mode(4, 3);

  /// Stabilize modu — PX4'te main_mode = 7 (STABILIZED)
  void sendStabilize() => _setPx4Mode(7, 0);

  /// Follow modu — PX4'te main_mode = 4 (AUTO), sub_mode = 8 (FOLLOW_TARGET)
  void sendFollowMode() => _setPx4Mode(4, 8);

  void sendVtolTransition({required bool toMulticopter}) {
    _sendCommand(3000, p1: toMulticopter ? 3.0 : 4.0);
  }

  void sendOrbit({double radius = 50.0}) {
    if (droneSystemId == null) return;
    sendMessage(CommandLong(
      targetSystem: droneSystemId!, targetComponent: droneComponentId!,
      command: 34, confirmation: 0,
      param1: radius,     // Yarıçap (metre)
      param2: double.nan, // PX4 otomatik seyir hızını kullanır (MPC_XY_CRUISE veya FW_AIRSPD_TRIM)
      param3: 0.0,  // Yaw behavior (0: front to center)
      param4: 0.0,
      param5: double.nan, // Use current lat
      param6: double.nan, // Use current lon
      param7: double.nan, // Use current alt
    ));
  }

  void sendReposition(double lat, double lon, double alt) {
    if (droneSystemId == null) return;
    sendMessage(CommandLong(
      targetSystem: droneSystemId!, targetComponent: droneComponentId!,
      command: 192, confirmation: 0,
      param1: -1,  param2: 1,
      param3: 0,   param4: double.nan,
      param5: lat, param6: lon, param7: alt,
    ));
  }

  void sendFollowTarget(double lat, double lon, double alt) {
    // timestamp ms cinsinden olmalıdır (time_boot_ms standardı)
    // estCapabilities=1 → konum alanı güvenilir
    // attitudeQ identity quaternion [1,0,0,0]
    sendMessage(FollowTarget(
      timestamp:       DateTime.now().millisecondsSinceEpoch,
      estCapabilities: 1,
      lat: (lat * 1e7).toInt(),
      lon: (lon * 1e7).toInt(),
      alt: alt,
      vel:         Float32List(3),
      acc:         Float32List(3),
      attitudeQ:   Float32List.fromList([1.0, 0.0, 0.0, 0.0]),
      rates:       Float32List(3),
      positionCov: Float32List(3),
      customState: 0,
    ));
  }

  // ─── İç yardımcılar ───────────────────────────────────────────────────────

  void _sendCommand(int cmd, {double p1 = 0, double p2 = 0}) {
    if (droneSystemId == null) return;
    sendMessage(CommandLong(
      targetSystem: droneSystemId!, targetComponent: droneComponentId!,
      command: cmd, confirmation: 0,
      param1: p1, param2: p2,
      param3: 0, param4: 0, param5: 0, param6: 0, param7: 0,
    ));
  }

  /// SET_MODE (CMD 176) PX4 için: param1=1 (MAV_MODE_FLAG_CUSTOM_MODE_ENABLED)
  /// param2=mainMode, param3=subMode
  void _setPx4Mode(int mainMode, int subMode) {
    if (droneSystemId == null) return;
    sendMessage(CommandLong(
      targetSystem: droneSystemId!, targetComponent: droneComponentId!,
      command: 176, confirmation: 0,
      param1: 1, param2: mainMode.toDouble(), param3: subMode.toDouble(),
      param4: 0, param5: 0, param6: 0, param7: 0,
    ));
  }

  void sendMessage(MavlinkMessage msg) {
    final frame = MavlinkFrame.v2(_sequence, _systemId, _componentId, msg);
    _udp.send(frame.serialize(), _host, _port);
    _sequence = (_sequence + 1) & 0xFF;

    // Timeout takibi
    if (msg is CommandLong && _ownCommands.contains(msg.command)) {
      final cmd = msg.command;
      _pendingCommands[cmd]?.cancel();
      _pendingCommands[cmd] = Timer(const Duration(seconds: 5), () {
        _pendingCommands.remove(cmd);
        if (!_ackCtrl.isClosed) {
          _ackCtrl.add(CommandResult(
            command: cmd,
            result: 3, // 3 = Timeout
            label: _label(cmd),
          ));
        }
      });
    }
  }

  void dispose() {
    _keepAliveTimer?.cancel();
    _timeoutTimer?.cancel();
    for (final t in _pendingCommands.values) { t.cancel(); }
    _pendingCommands.clear();
    _udp.close();
    _connCtrl.close();
    _ackCtrl.close();
    _rawFrameCtrl.close();
  }
}
