import 'package:shared_preferences/shared_preferences.dart';

import '../models/flight_settings.dart';

/// Bağlantı ve uçuş ayarlarını SharedPreferences üzerinden okur ve yazar.
class SettingsService {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  static const String _keyIp   = 'ws_ip';
  static const String _keyPort = 'ws_port';

  // Flight settings keys
  static const String _keyFollowAlt   = 'fs_follow_alt';
  static const String _keyNearDist    = 'fs_near_dist';
  static const String _keyFarDist     = 'fs_far_dist';
  static const String _keyOrbitRadius = 'fs_orbit_radius';
  static const String _keyTakeoffAlt  = 'fs_takeoff_alt';

  Future<({String ip, int port})> load() async {
    final prefs = await SharedPreferences.getInstance();
    final ip   = prefs.getString(_keyIp)   ?? '10.0.2.2';
    final port = int.tryParse(prefs.getString(_keyPort) ?? '') ?? 14540;
    return (ip: ip, port: port);
  }

  Future<void> save({required String ip, required int port}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyIp,   ip);
    await prefs.setString(_keyPort, port.toString());
  }

  Future<FlightSettings> loadFlightSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return FlightSettings(
      followAltitude:     prefs.getDouble(_keyFollowAlt)   ?? 30.0,
      followDistanceNear: prefs.getDouble(_keyNearDist)    ?? 150.0,
      followDistanceFar:  prefs.getDouble(_keyFarDist)     ?? 300.0,
      defaultOrbitRadius: prefs.getDouble(_keyOrbitRadius)  ?? 50.0,
      defaultTakeoffAlt:  prefs.getDouble(_keyTakeoffAlt)   ?? 10.0,
    );
  }

  Future<void> saveFlightSettings(FlightSettings s) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyFollowAlt,   s.followAltitude);
    await prefs.setDouble(_keyNearDist,    s.followDistanceNear);
    await prefs.setDouble(_keyFarDist,     s.followDistanceFar);
    await prefs.setDouble(_keyOrbitRadius, s.defaultOrbitRadius);
    await prefs.setDouble(_keyTakeoffAlt,  s.defaultTakeoffAlt);
  }
}