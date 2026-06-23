import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

import 'main_state.dart';
import '../core/app_colors.dart';
import '../models/follow_state.dart';
import '../models/flight_settings.dart';
import '../models/command_result.dart';
import '../services/mavlink_service.dart';
import '../services/follow_service.dart';
import '../services/location_service.dart';
import '../services/settings_service.dart';
import '../services/video_service.dart';
import '../services/telemetry_service.dart';
import '../services/flight_timer_service.dart';

class MainCubit extends Cubit<MainState> {
  final _mavlink = MavlinkService();
  final _follow = FollowService();
  final _location = LocationService();
  final _settings = SettingsService();
  final _video = VideoService();
  final _telemetry = TelemetryService();
  final _flightTimer = FlightTimerService();

  StreamSubscription? _connSub;
  StreamSubscription? _followSub;
  StreamSubscription? _ackSub;
  StreamSubscription? _videoSub;
  StreamSubscription? _videoConnSub;
  StreamSubscription? _telemetrySub;
  StreamSubscription? _flightTimerSub;

  MainCubit() : super(const MainState()) {
    _init();
  }

  Future<void> _init() async {
    await _loadSettings();
    await _initSystem();
    _initVideo();
    _initTelemetry();
  }

  Future<void> _loadSettings() async {
    final s = await _settings.load();
    final fs = await _settings.loadFlightSettings();
    emit(state.copyWith(ip: s.ip, port: s.port, flightSettings: fs));
    _mavlink.setTarget(s.ip, s.port);
    _video.setTarget(s.ip);
    _follow.applySettings(fs);
  }

  Future<void> _initSystem() async {
    await _location.requestPermissions(
      onWarning: (msg) => emitMessage(msg, Icons.warning_amber, Colors.orange),
    );

    await _location.startListening(
      onPosition: (Position p) {
        _follow.updateGcsPosition(p);
        _telemetry.updateGcsPosition(p.latitude, p.longitude);
        emit(state.copyWith(lat: p.latitude, lon: p.longitude, alt: p.altitude));
      },
      onError: (e) => debugPrint('GPS Hatası: $e'),
    );

    emit(state.copyWith(isConnected: _mavlink.isConnected));
    _connSub = _mavlink.connectionStream.listen((v) {
      emit(state.copyWith(isConnected: v));
      if (!v) {
        HapticFeedback.heavyImpact();
        emitMessage('BAĞLANTI KOPTU!', Icons.warning, AppColors.red);
      }
    });

    emit(state.copyWith(followState: _follow.currentState));
    _followSub = _follow.stateStream.listen((s) {
      bool followActive = state.followActive;
      if (s == FollowState.idle) followActive = false;
      emit(state.copyWith(followState: s, followActive: followActive));
    });

    _ackSub = _mavlink.commandAckStream.listen((r) {
      emit(state.copyWith(isCommandPending: false));
      Color color = r.accepted ? AppColors.green : AppColors.red;
      IconData icon = r.accepted ? Icons.check_circle_outline : Icons.error_outline;
      if (r.result == 3) {
        color = AppColors.amber;
        icon = Icons.timer_off;
      }
      emitMessage('${r.label}: ${r.resultText}', icon, color);
    });
  }

  void _initVideo() {
    _video.setTarget(state.ip);
    _video.start();
    _videoSub = _video.frameStream.listen((f) {
      emit(state.copyWith(currentFrame: f));
    });
    _videoConnSub = _video.connectionStream.listen((v) {
      emit(state.copyWith(videoConnected: v));
    });
  }

  void _initTelemetry() {
    _telemetry.start();
    
    _flightTimerSub = _flightTimer.elapsedStream.listen((d) {
      emit(state.copyWith(flightTime: d));
    });

    bool batteryWarningShown = false;
    _telemetrySub = _telemetry.telemetryStream.listen((t) {
      _flightTimer.updateArmState(t.isArmed);
      emit(state.copyWith(droneTelemetry: t));
      
      if (t.batteryPercent >= 0 && t.batteryPercent < 20 && !batteryWarningShown) {
        batteryWarningShown = true;
        HapticFeedback.heavyImpact();
        emitMessage('KRİTİK BATARYA: %${t.batteryPercent}', Icons.battery_alert, AppColors.red);
      } else if (t.batteryPercent >= 20) {
        batteryWarningShown = false;
      }
    });
  }

  void emitMessage(String text, IconData icon, Color color) {
    emit(state.copyWith(
      snackBarMessage: SnackBarMessage(
        text: text,
        icon: icon,
        color: color,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      ),
    ));
  }

  void setMapFullscreen(bool isFullscreen) {
    emit(state.copyWith(mapFullscreen: isFullscreen));
  }

  Future<void> saveSettings(String ip, String portStr) async {
    final port = int.tryParse(portStr) ?? 14540;
    await _settings.save(ip: ip, port: port);
    _mavlink.setTarget(ip, port);
    _video.setTarget(ip);
    emit(state.copyWith(ip: ip, port: port));
    emitMessage('Hedef güncellendi ($ip:$port)', Icons.check_circle, AppColors.green);
  }

  Future<void> saveFlightSettings(FlightSettings fs) async {
    await _settings.saveFlightSettings(fs);
    _follow.applySettings(fs);
    emit(state.copyWith(flightSettings: fs));
    emitMessage('Uçuş ayarları kaydedildi', Icons.check_circle, AppColors.green);
  }

  bool requireConnection() {
    if (!state.isConnected) {
      emitMessage('Drone bağlantısı yok!', Icons.link_off, AppColors.red);
      return false;
    }
    if (state.isCommandPending) {
      emitMessage('Önceki komutun yanıtı bekleniyor...', Icons.hourglass_empty, AppColors.amber);
      return false;
    }
    return true;
  }

  void toggleFollow() {
    if (!state.isConnected && !state.followActive) {
      emitMessage('Önce drone bağlantısı kurulmalı!', Icons.link_off, AppColors.red);
      return;
    }
    if (state.lat == 0.0 || state.lon == 0.0) {
      emitMessage('GPS fix bekleniyor...', Icons.gps_off, AppColors.amber);
      return;
    }
    HapticFeedback.mediumImpact();
    final newActive = !state.followActive;
    emit(state.copyWith(followActive: newActive));
    if (newActive) {
      _follow.start();
      emitMessage('FOLLOW ME AKTİF', Icons.person_pin_circle, AppColors.cyan);
    } else {
      _follow.stop();
      emitMessage('FOLLOW ME PASİF', Icons.person_pin_circle_outlined, AppColors.grey);
    }
  }

  void sendArmDisarm(bool arm) {
    if (!requireConnection()) return;
    HapticFeedback.heavyImpact();
    emit(state.copyWith(isCommandPending: true));
    _mavlink.sendArmDisarm(arm);
    emitMessage(arm ? 'ARM gönderiliyor...' : 'DISARM gönderiliyor...', Icons.hourglass_top, AppColors.amber);
  }

  void sendHold() {
    if (!requireConnection()) return;
    HapticFeedback.heavyImpact();
    emit(state.copyWith(followActive: false, isCommandPending: true));
    _mavlink.sendHold();
    emitMessage('HOLD komutu gönderildi — yanıt bekleniyor...', Icons.hourglass_top, AppColors.amber);
  }

  void sendLand() {
    if (!requireConnection()) return;
    HapticFeedback.heavyImpact();
    emit(state.copyWith(followActive: false, isCommandPending: true));
    _mavlink.sendLand();
    emitMessage('LAND komutu gönderildi — yanıt bekleniyor...', Icons.hourglass_top, AppColors.amber);
  }

  void sendOrbit(double radius) {
    if (!requireConnection()) return;
    HapticFeedback.heavyImpact();
    emit(state.copyWith(followActive: false, isCommandPending: true));
    _mavlink.sendOrbit(radius: radius);
    emitMessage('ORBİT komutu gönderildi (${radius.toStringAsFixed(0)}m) — yanıt bekleniyor...', Icons.hourglass_top, AppColors.amber);
  }

  void sendStabilize() {
    if (!requireConnection()) return;
    HapticFeedback.heavyImpact();
    emit(state.copyWith(followActive: false, isCommandPending: true));
    _mavlink.sendStabilize();
    emitMessage('STABİLİZE komutu gönderildi — yanıt bekleniyor...', Icons.hourglass_top, AppColors.amber);
  }

  void sendTakeoff(double alt) {
    if (!requireConnection()) return;
    HapticFeedback.heavyImpact();
    emit(state.copyWith(isCommandPending: true));
    _mavlink.sendTakeoff(alt);
    emitMessage('TAKEOFF komutu gönderildi (${alt.toStringAsFixed(0)}m) — yanıt bekleniyor...', Icons.hourglass_top, AppColors.amber);
  }

  void sendRtl() {
    if (!requireConnection()) return;
    HapticFeedback.heavyImpact();
    emit(state.copyWith(followActive: false, isCommandPending: true));
    _mavlink.sendRtl();
    emitMessage('RTL komutu gönderildi — yanıt bekleniyor...', Icons.hourglass_top, AppColors.amber);
  }

  void sendTransition(bool toMulticopter) {
    if (!requireConnection()) return;
    HapticFeedback.heavyImpact();
    emit(state.copyWith(isCommandPending: true));
    _mavlink.sendVtolTransition(toMulticopter: toMulticopter);
    final modeStr = toMulticopter ? 'MULTICOPTER' : 'SABİT KANAT';
    emitMessage('$modeStr geçiş komutu gönderildi...', Icons.hourglass_top, AppColors.cyan);
  }

  void sendMissionStart() {
    if (!requireConnection()) return;
    HapticFeedback.heavyImpact();
    emit(state.copyWith(followActive: false, isCommandPending: true));
    _mavlink.sendMissionStart();
    emitMessage('GÖREV komutu gönderildi — yanıt bekleniyor...', Icons.hourglass_top, AppColors.amber);
  }

  @override
  Future<void> close() {
    _connSub?.cancel();
    _followSub?.cancel();
    _ackSub?.cancel();
    _videoSub?.cancel();
    _videoConnSub?.cancel();
    _telemetrySub?.cancel();
    _flightTimerSub?.cancel();
    
    _location.stop();
    _video.dispose();
    _telemetry.dispose();
    _flightTimer.dispose();
    
    return super.close();
  }
}
