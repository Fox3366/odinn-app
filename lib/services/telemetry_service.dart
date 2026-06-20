import 'dart:async';
import 'dart:math' as math;

import 'package:dart_mavlink/mavlink.dart';
import 'package:dart_mavlink/dialects/common.dart';

import '../models/drone_telemetry.dart';
import 'mavlink_service.dart';

/// MavlinkService'ten gelen ham MAVLink frame'lerini dinleyerek
/// [DroneTelemetry] nesnesi üretir.
///
/// Performans için:
/// - Dahili state'i her frame'de günceller ama stream'e
///   yalnızca [_emitIntervalMs] aralıklarla yayınlar (throttle).
/// - UI tarafında gereksiz rebuild önlenir.
class TelemetryService {
  static final TelemetryService _instance = TelemetryService._internal();
  factory TelemetryService() => _instance;
  TelemetryService._internal();

  final _mavlink = MavlinkService();

  // --- Throttle ayarı (ms) ---
  static const int _emitIntervalMs = 500; // 2 Hz

  // --- Dahili mutable state (her frame'de güncellenir) ---
  double _batteryVoltage = 0.0;
  int    _batteryPercent = -1;
  double _batteryCurrent = 0.0;
  int    _throttle       = 0;
  double _groundSpeed    = 0.0;
  double _altitude       = 0.0;
  double _relativeAlt    = 0.0;
  int    _satelliteCount = 0;
  int    _gpsFixType     = 0;
  double _heading        = 0.0;
  int    _customMode     = 0;
  bool   _isArmed        = false;

  // GCS konumu — dışarıdan güncellenir
  double _gcsLat = 0.0;
  double _gcsLon = 0.0;

  // --- Stream ---
  final _ctrl = StreamController<DroneTelemetry>.broadcast();
  Stream<DroneTelemetry> get telemetryStream => _ctrl.stream;

  StreamSubscription<MavlinkFrame>? _frameSub;
  Timer? _emitTimer;

  /// Servis başlatma — MavlinkService.rawFrameStream'e bağlanır.
  void start() {
    _frameSub?.cancel();
    _frameSub = _mavlink.rawFrameStream.listen(_onFrame);
    _emitTimer?.cancel();
    _emitTimer = Timer.periodic(
      const Duration(milliseconds: _emitIntervalMs),
      (_) => _emit(),
    );
  }

  /// GCS konumunu günceller (mesafe hesabı için).
  void updateGcsPosition(double lat, double lon) {
    _gcsLat = lat;
    _gcsLon = lon;
  }

  void _onFrame(MavlinkFrame frame) {
    final msg = frame.message;

    if (msg is SysStatus) {
      _batteryVoltage = msg.voltageBattery / 1000.0; // mV → V
      _batteryPercent = msg.batteryRemaining;         // -1 bilinmiyor
      _batteryCurrent = msg.currentBattery >= 0 ? msg.currentBattery / 100.0 : -1.0; // cA → A
    }

    if (msg is GlobalPositionInt) {
      _altitude    = msg.alt / 1000.0;          // mm → m
      _relativeAlt = msg.relativeAlt / 1000.0;  // mm → m
      _heading     = msg.hdg / 100.0;            // cdeg → deg
    }

    if (msg is VfrHud) {
      _groundSpeed = msg.groundspeed; // m/s
      _throttle    = msg.throttle;    // %
    }

    if (msg is GpsRawInt) {
      _satelliteCount = msg.satellitesVisible;
      _gpsFixType     = msg.fixType;
    }

    if (msg is Heartbeat) {
      _customMode = msg.customMode;
      _isArmed    = (msg.baseMode & 128) != 0; // MAV_MODE_FLAG_SAFETY_ARMED
    }
  }

  void _emit() {
    if (_ctrl.isClosed) return;

    final dist = (_gcsLat != 0.0 && _gcsLon != 0.0 &&
                  _mavlink.droneLat != 0.0 && _mavlink.droneLon != 0.0)
        ? _haversine(_gcsLat, _gcsLon, _mavlink.droneLat, _mavlink.droneLon)
        : 0.0;

    _ctrl.add(DroneTelemetry(
      batteryVoltage: _batteryVoltage,
      batteryPercent: _batteryPercent,
      batteryCurrent: _batteryCurrent,
      throttle:       _throttle,
      groundSpeed:    _groundSpeed,
      altitude:       _altitude,
      relativeAlt:    _relativeAlt,
      distanceToGcs:  dist,
      satelliteCount: _satelliteCount,
      gpsFixType:     _gpsFixType,
      flightMode:     _px4ModeName(_customMode),
      heading:        _heading,
      isArmed:        _isArmed,
    ));
  }

  /// PX4 custom_mode → insan-okunur mod adı.
  /// custom_mode: alt 8 bit = sub_mode, sonraki 8 bit = main_mode
  String _px4ModeName(int customMode) {
    final mainMode = (customMode >> 16) & 0xFF;
    final subMode  = (customMode >> 24) & 0xFF;

    switch (mainMode) {
      case 1: return 'MANUAL';
      case 2: return 'ALTCTL';
      case 3: return 'POSCTL';
      case 4:
        switch (subMode) {
          case 1:  return 'AUTO READY';
          case 2:  return 'AUTO TAKEOFF';
          case 3:  return 'AUTO LOITER';
          case 4:  return 'AUTO MISSION';
          case 5:  return 'AUTO RTL';
          case 6:  return 'AUTO LAND';
          case 8:  return 'AUTO FOLLOW';
          default: return 'AUTO ($subMode)';
        }
      case 5: return 'ACRO';
      case 6: return 'OFFBOARD';
      case 7: return 'STABILIZED';
      case 8: return 'RATTITUDE';
      default: return 'MOD $mainMode';
    }
  }

  double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371000.0;
    final dLat = (lat2 - lat1) * math.pi / 180;
    final dLon = (lon2 - lon1) * math.pi / 180;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180) *
            math.cos(lat2 * math.pi / 180) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  void dispose() {
    _frameSub?.cancel();
    _emitTimer?.cancel();
    _ctrl.close();
  }
}
