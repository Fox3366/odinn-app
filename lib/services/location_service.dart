import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

/// GPS izni isteme ve konum stream yönetiminden sorumludur.
/// Konum güncellemelerini callback ile dışarı iletir.
class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  StreamSubscription<Position>? _sub;

  /// İzinleri kontrol eder. Eksik izin varsa [onWarning] çağrılır.
  Future<void> requestPermissions({
    required void Function(String message) onWarning,
  }) async {
    final statuses = await [Permission.location].request();
    if (statuses[Permission.location]!.isPermanentlyDenied) {
      onWarning('⚠️ Konum izni kalıcı reddedildi! Lütfen ayarlardan açın.');
      await openAppSettings();
      return;
    }
    if (statuses[Permission.location]!.isDenied) {
      onWarning('⚠️ Konum izni verilmedi!');
      return;
    }
    final bg = await Permission.locationAlways.status;
    if (bg.isDenied) {
      final r = await Permission.locationAlways.request();
      if (r.isDenied || r.isPermanentlyDenied) {
        onWarning('Arka plan konum izni yok — Follow Me arka planda çalışmaz!');
      }
    }
  }

  /// GPS stream başlatır. [onPosition] her yeni konumda çağrılır.
  Future<void> startListening({
    required void Function(Position p) onPosition,
    required void Function(String error) onError,
  }) async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      onError('Lütfen GPS\'inizi açın');
      return;
    }
    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 1,
    );
    _sub = Geolocator.getPositionStream(locationSettings: settings).listen(
      onPosition,
      onError: (e) => onError(e.toString()),
    );
    debugPrint('📍 GPS dinleniyor');
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
  }
}