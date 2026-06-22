import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/follow_state.dart';
import '../models/flight_settings.dart';
import 'mavlink_service.dart';

/// Follow Me uçuş mantığını yönetir.
/// MavlinkService'e bağımlıdır, UI'a bağımlı değildir.
class FollowService {
  static final FollowService _instance = FollowService._internal();
  factory FollowService() => _instance;
  FollowService._internal();

  final _mavlink = MavlinkService();

  double thresholdFarM  = 300.0;
  double thresholdNearM = 150.0;
  double _followAlt     = 30.0;

  /// FlightSettings'ten gelen değerleri uygular.
  void applySettings(FlightSettings s) {
    thresholdNearM = s.followDistanceNear;
    thresholdFarM  = s.followDistanceFar;
    _followAlt     = s.followAltitude;
  }

  // GCS (telefon) konumu — LocationService callback'i tarafından güncellenir
  double _gcsLat = 0.0;
  double _gcsLon = 0.0;
  double _gcsAlt = 0.0; // AMSL irtifa
  double _gcsHeading = 0.0;
  double _gcsSpeed = 0.0;
  double _gcsAccH = 0.0; // Yatay hassasiyet
  double _gcsAccV = 0.0; // Dikey hassasiyet

  FollowState _state      = FollowState.idle;
  bool        _active     = false;
  bool        _transitioning = false;
  
  // Spam önleme
  double _lastSentLat = 0.0;
  double _lastSentLon = 0.0;
  bool   _isFwSent    = false;

  Timer? _timer;

  final _stateCtrl = StreamController<FollowState>.broadcast();
  Stream<FollowState> get stateStream   => _stateCtrl.stream;
  FollowState         get currentState  => _state;

  /// Ana ekrandan GPS güncellemesi alır.
  void updateGcsPosition(Position p) {
    _gcsLat = p.latitude;
    _gcsLon = p.longitude;
    _gcsAlt = p.altitude;
    _gcsHeading = p.heading; // 0.0 - 359.9
    _gcsSpeed = p.speed; // m/s
    _gcsAccH = p.accuracy;
    _gcsAccV = p.altitudeAccuracy;
  }

  void start() {
    if (_mavlink.droneSystemId == null) {
      debugPrint('⚠️ Drone bağlı değil, Follow başlatılamaz.');
      return;
    }
    _active        = true;
    _transitioning = false;
    _isFwSent      = false;
    _lastSentLat   = 0.0;
    _lastSentLon   = 0.0;
    _setState(FollowState.approaching);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_active) _tick();
    });
  }

  void stop() {
    _active        = false;
    _transitioning = false;
    _timer?.cancel();
    _setState(FollowState.idle);
    _mavlink.sendHold();
  }

  void _tick() {
    if (_transitioning) {
      debugPrint('🔄 Geçiş devam ediyor, bekleniyor...');
      return;
    }

    debugPrint('--- KONUM DENETİMİ ---');
    debugPrint('📱 Telefon (GCS): Lat: $_gcsLat, Lon: $_gcsLon');
    debugPrint('✈️  Drone: Lat: ${_mavlink.droneLat}, Lon: ${_mavlink.droneLon}');

    if (_gcsLat == 0.0 || _gcsLon == 0.0 ||
        _mavlink.droneLat == 0.0 || _mavlink.droneLon == 0.0) {
      debugPrint('🛰️ GPS Fix Bekleniyor...');
      return;
    }

    final dist = _haversine(_gcsLat, _gcsLon, _mavlink.droneLat, _mavlink.droneLon);
    debugPrint('📏 Mesafe: ${dist.toStringAsFixed(1)}m | Safha: $_state');

    switch (_state) {
      case FollowState.approaching:
        _handleApproaching(dist);
        break;
      case FollowState.following:
        _handleFollowing(dist);
        break;
      default:
        break;
    }
  }

  void _handleApproaching(double dist) {
    if (dist > thresholdFarM) {
      // Uzak: sabit kanatlı olarak yönlendirmeye git
      if (!_isFwSent) {
        _mavlink.sendVtolTransition(toMulticopter: false);
        _isFwSent = true;
      }
      _sendRepositionIfMoved();
    } else if (dist > thresholdNearM) {
      // Orta mesafe: yeniden konumlandır
      _isFwSent = false;
      _sendRepositionIfMoved();
    } else {
      // Kritik mesafe: multicopter moduna geç, ardından follow modu etkinleştir
      debugPrint('🔄 Kritik Mesafe (<${thresholdNearM}m): MC Transition başlatılıyor...');
      _transitioning = true;
      _setState(FollowState.transitioning);
      _mavlink.sendVtolTransition(toMulticopter: true);

      Future.delayed(const Duration(seconds: 4), () {
        if (!_active) {
          _transitioning = false;
          return;
        }
        _transitioning = false;
        _setState(FollowState.following);
        // Hata düzeltildi: sendHold() yerine sendFollowMode() kullanıldı
        _mavlink.sendFollowMode();
      });
    }
  }

  void _handleFollowing(double dist) {
    // QGC Mantığı: vx, vy hesapla
    double vx = 0.0;
    double vy = 0.0;
    int estCap = 1; // 1 << 0 (POS)
    
    if (_gcsSpeed > 0.0) {
      estCap |= (1 << 1); // 1 << 1 (VEL)
      final dirRad = _gcsHeading * (math.pi / 180.0);
      vx = math.cos(dirRad) * _gcsSpeed;
      vy = math.sin(dirRad) * _gcsSpeed;
    }
    
    if (_gcsHeading >= 0.0) {
      estCap |= (1 << 2); // 1 << 2 (HEADING)
    }

    _mavlink.sendFollowTarget(
      lat: _gcsLat,
      lon: _gcsLon,
      alt: _gcsAlt, // _followAlt değil, kesinlikle cihazın mutlak AMSL irtifası!
      vel: [vx, vy, 0.0],
      posCov: [_gcsAccH, _gcsAccH, _gcsAccV],
      estCapabilities: estCap,
    );

    if (dist > thresholdFarM * 1.5) {
      debugPrint('⚠️ Mesafe çok arttı, approaching moduna dönülüyor...');
      _mavlink.sendHold();
      _setState(FollowState.approaching);
    }
  }

  void _sendRepositionIfMoved() {
    // Sadece konum 5 metreden fazla değiştiyse yeni Reposition gönder (spam önleme)
    if (_lastSentLat == 0.0 || _haversine(_lastSentLat, _lastSentLon, _gcsLat, _gcsLon) > 5.0) {
      _mavlink.sendReposition(_gcsLat, _gcsLon, _followAlt); // Hata düzeltildi: _gcsAlt -> _followAlt
      _lastSentLat = _gcsLat;
      _lastSentLon = _gcsLon;
    }
  }

  void _setState(FollowState s) {
    _state = s;
    _stateCtrl.add(s);
  }

  double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371000.0;
    final dLat = (lat2 - lat1) * math.pi / 180;
    final dLon = (lon2 - lon1) * math.pi / 180;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180) *
            math.cos(lat2 * math.pi / 180) *
            math.sin(dLon / 2) * math.sin(dLon / 2);
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  void dispose() {
    _timer?.cancel();
    _stateCtrl.close();
  }
}