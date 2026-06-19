import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

import '../core/app_colors.dart';
import '../models/follow_state.dart';
import '../models/flight_settings.dart';
import '../models/drone_telemetry.dart';
import '../models/command_result.dart';
import '../services/mavlink_service.dart';
import '../services/follow_service.dart';
import '../services/location_service.dart';
import '../services/settings_service.dart';
import '../services/video_service.dart';
import '../services/telemetry_service.dart';
import '../services/flight_timer_service.dart';
import '../painters/bg_scan_painter.dart';
import '../widgets/top_bar.dart';
import '../widgets/video_hud.dart';
import '../widgets/command_panel.dart';
import '../widgets/flight_command_panel.dart';
import '../widgets/follow_state_bar.dart';
import '../widgets/connection_panel.dart';
import '../widgets/flight_settings_panel.dart';
import '../widgets/telemetry_bar.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/takeoff_dialog.dart';
import '../widgets/preflight_checklist_dialog.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  // --- Servisler ---
  final _mavlink    = MavlinkService();
  final _follow     = FollowService();
  final _location   = LocationService();
  final _settings   = SettingsService();
  final _video      = VideoService();
  final _telemetry  = TelemetryService();
  final _flightTimer = FlightTimerService();

  // --- Subscription'lar ---
  StreamSubscription<bool>?          _connSub;
  StreamSubscription<FollowState>?   _followSub;
  StreamSubscription<CommandResult>? _ackSub;
  StreamSubscription<Uint8List>?     _videoSub;
  StreamSubscription<bool>?          _videoConnSub;
  StreamSubscription<DroneTelemetry>? _telemetrySub;
  StreamSubscription<Duration>?      _flightTimerSub;

  // --- UI Durumu ---
  double      _lat = 0, _lon = 0, _alt = 0;
  bool        _isConnected    = false;
  bool        _followActive   = false;
  bool        _videoConnected = false;
  bool        _mapFullscreen  = false;
  FollowState _followState    = FollowState.idle;
  Uint8List?  _currentFrame;
  DroneTelemetry _droneTelemetry = const DroneTelemetry();
  FlightSettings _flightSettings = const FlightSettings();
  Duration _flightTime = Duration.zero;

  bool _isCommandPending    = false;
  bool _batteryWarningShown = false;

  // --- Controller'lar ---
  final _ipCtrl   = TextEditingController();
  final _portCtrl = TextEditingController();

  // --- Animasyonlar ---
  late AnimationController _pulseCtrl, _bgCtrl, _radarCtrl;
  late Animation<double>   _pulse, _radarAngle;

  // --- Tab ---
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadSettings();
    _initSystem();
    _initVideo();
    _initTelemetry();
    _initAnimations();
  }

  void _initAnimations() {
    _pulseCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))
      ..repeat(reverse: true);
    _pulse      = Tween<double>(begin: 0.3, end: 1.0)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _bgCtrl     = AnimationController(vsync: this, duration: const Duration(seconds: 8))
      ..repeat();

    _radarCtrl  = AnimationController(vsync: this, duration: const Duration(seconds: 4))
      ..repeat();
    _radarAngle = Tween<double>(begin: 0, end: 2 * pi).animate(_radarCtrl);
  }

  Future<void> _loadSettings() async {
    final s = await _settings.load();
    final fs = await _settings.loadFlightSettings();
    if (!mounted) return;
    setState(() {
      _ipCtrl.text    = s.ip;
      _portCtrl.text  = s.port.toString();
      _flightSettings = fs;
    });
    _mavlink.setTarget(s.ip, s.port);
    _video.setTarget(s.ip);
    _follow.applySettings(fs);
  }

  Future<void> _initSystem() async {
    await _location.requestPermissions(
      onWarning: (msg) => _snack(msg, Icons.warning_amber, Colors.orange),
    );

    await _location.startListening(
      onPosition: (Position p) {
        _follow.updateGcsPosition(p.latitude, p.longitude, p.altitude);
        _telemetry.updateGcsPosition(p.latitude, p.longitude);
        if (mounted) {
          setState(() {
            _lat = p.latitude;
            _lon = p.longitude;
            _alt = p.altitude;
          });
        }
      },
      onError: (e) => debugPrint('GPS Hatası: $e'),
    );

    _isConnected = _mavlink.isConnected;
    _connSub = _mavlink.connectionStream.listen((v) {
      if (mounted) {
        setState(() => _isConnected = v);
        if (!v) {
          HapticFeedback.heavyImpact();
          _snack('BAĞLANTI KOPTU!', Icons.warning, AppColors.red);
        }
      }
    });

    _followState = _follow.currentState;
    _followSub = _follow.stateStream.listen((s) {
      if (mounted) {
        setState(() {
          _followState = s;
          if (s == FollowState.idle) _followActive = false;
        });
      }
    });

    _ackSub = _mavlink.commandAckStream.listen((r) {
      if (!mounted) return;
      setState(() => _isCommandPending = false);
      
      Color color = r.accepted ? AppColors.green : AppColors.red;
      IconData icon = r.accepted ? Icons.check_circle_outline : Icons.error_outline;
      if (r.result == 3) {
        color = AppColors.amber;
        icon = Icons.timer_off;
      }
      
      _snack('${r.label}: ${r.resultText}', icon, color);
    });
  }

  void _initVideo() {
    _video.setTarget(_ipCtrl.text);
    _video.start();
    _videoSub    = _video.frameStream.listen((f) {
      if (mounted) setState(() => _currentFrame = f);
    });
    _videoConnSub = _video.connectionStream.listen((v) {
      if (mounted) setState(() => _videoConnected = v);
    });
  }

  void _initTelemetry() {
    _telemetry.start();
    
    _flightTimerSub = _flightTimer.elapsedStream.listen((d) {
      if (mounted) setState(() => _flightTime = d);
    });

    _telemetrySub = _telemetry.telemetryStream.listen((t) {
      if (mounted) {
        _flightTimer.updateArmState(t.isArmed);
        setState(() => _droneTelemetry = t);
        
        // Düşük batarya uyarısı (%20 altı)
        if (t.batteryPercent >= 0 && t.batteryPercent < 20 && !_batteryWarningShown) {
          _batteryWarningShown = true;
          HapticFeedback.heavyImpact();
          _snack('KRİTİK BATARYA: %${t.batteryPercent}', Icons.battery_alert, AppColors.red);
        } else if (t.batteryPercent >= 20) {
          _batteryWarningShown = false; // Şarj edilirse veya pil değişirse sıfırla
        }
      }
    });
  }

  Future<void> _saveSettings() async {
    final ip   = _ipCtrl.text.trim();
    final port = int.tryParse(_portCtrl.text.trim()) ?? 14540;
    await _settings.save(ip: ip, port: port);
    _mavlink.setTarget(ip, port);
    _video.setTarget(ip);
    if (mounted) _snack('Hedef güncellendi ($ip:$port)', Icons.check_circle, AppColors.green);
  }

  Future<void> _saveFlightSettings(FlightSettings fs) async {
    await _settings.saveFlightSettings(fs);
    _follow.applySettings(fs);
    if (mounted) {
      setState(() => _flightSettings = fs);
      _snack('Uçuş ayarları kaydedildi', Icons.check_circle, AppColors.green);
    }
  }

  // ─── Komut Handler'ları ──────────────────────────────────────────────────

  /// Drone bağlı değilse uyarı gösterir ve false döner.
  bool _requireConnection() {
    if (!_isConnected) {
      _snack('Drone bağlantısı yok!', Icons.link_off, AppColors.red);
      return false;
    }
    if (_isCommandPending) {
      _snack('Önceki komutun yanıtı bekleniyor...', Icons.hourglass_empty, AppColors.amber);
      return false;
    }
    return true;
  }

  void _toggleFollow() {
    if (!_isConnected && !_followActive) {
      _snack('Önce drone bağlantısı kurulmalı!', Icons.link_off, AppColors.red);
      return;
    }
    if (_lat == 0.0 || _lon == 0.0) {
      _snack('GPS fix bekleniyor...', Icons.gps_off, AppColors.amber);
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() => _followActive = !_followActive);
    if (_followActive) {
      _follow.start();
      _snack('FOLLOW ME AKTİF', Icons.person_pin_circle, AppColors.cyan);
    } else {
      _follow.stop();
      _snack('FOLLOW ME PASİF', Icons.person_pin_circle_outlined, AppColors.grey);
    }
  }

  Future<void> _onArmDisarm() async {
    if (!_requireConnection()) return;
    
    if (!_droneTelemetry.isArmed) {
      // ARM edilecekse checklist göster
      final ok = await PreflightChecklistDialog.show(
        context,
        telemetry: _droneTelemetry,
        isConnected: _isConnected,
      );
      if (!ok || !mounted) return;
    } else {
      // DISARM edilecekse basit onay
      final confirmed = await ConfirmDialog.show(
        context,
        title: 'MOTORLARI KAPAT',
        description: 'Drone motorları kapatılacak (DISARM).\nHavadaysa düşmesine sebep olur!',
        icon: Icons.power_settings_new,
        accentColor: AppColors.red,
      );
      if (!confirmed || !mounted) return;
    }

    HapticFeedback.heavyImpact();
    setState(() => _isCommandPending = true);
    _mavlink.sendArmDisarm(!_droneTelemetry.isArmed);
    _snack(_droneTelemetry.isArmed ? 'DISARM gönderiliyor...' : 'ARM gönderiliyor...', Icons.hourglass_top, AppColors.amber);
  }

  void _onHold() {
    if (!_requireConnection()) return;
    HapticFeedback.heavyImpact();
    setState(() {
      _followActive = false;
      _isCommandPending = true;
    });
    _mavlink.sendHold();
    _snack('HOLD komutu gönderildi — yanıt bekleniyor...', Icons.hourglass_top, AppColors.amber);
  }

  void _onLand() {
    if (!_requireConnection()) return;
    HapticFeedback.heavyImpact();
    setState(() {
      _followActive = false;
      _isCommandPending = true;
    });
    _mavlink.sendLand();
    _snack('LAND komutu gönderildi — yanıt bekleniyor...', Icons.hourglass_top, AppColors.amber);
  }

  void _onOrbit(double radius) {
    if (!_requireConnection()) return;
    HapticFeedback.heavyImpact();
    setState(() {
      _followActive = false;
      _isCommandPending = true;
    });
    _mavlink.sendOrbit(radius: radius);
    _snack('ORBİT komutu gönderildi (${radius.toStringAsFixed(0)}m) — yanıt bekleniyor...', Icons.hourglass_top, AppColors.amber);
  }

  void _onStabilize() {
    if (!_requireConnection()) return;
    HapticFeedback.heavyImpact();
    setState(() {
      _followActive = false;
      _isCommandPending = true;
    });
    _mavlink.sendStabilize();
    _snack('STABİLİZE komutu gönderildi — yanıt bekleniyor...', Icons.hourglass_top, AppColors.amber);
  }

  Future<void> _onTakeoff() async {
    if (!_requireConnection()) return;
    
    // Uçuş öncesi kontrol
    final ok = await PreflightChecklistDialog.show(
      context,
      telemetry: _droneTelemetry,
      isConnected: _isConnected,
    );
    if (!ok || !mounted) return;

    final alt = await TakeoffDialog.show(
      context,
      defaultAltitude: _flightSettings.defaultTakeoffAlt,
    );
    if (alt == null || !mounted) return;
    HapticFeedback.heavyImpact();
    setState(() => _isCommandPending = true);
    _mavlink.sendTakeoff(alt);
    _snack('TAKEOFF komutu gönderildi (${alt.toStringAsFixed(0)}m) — yanıt bekleniyor...', Icons.hourglass_top, AppColors.amber);
  }

  Future<void> _onRtl() async {
    if (!_requireConnection()) return;
    final confirmed = await ConfirmDialog.show(
      context,
      title:       'RTL',
      description: 'Return to Launch komutu gönderilecek.\nDrone kalkış noktasına dönüp iniş yapacak.',
      icon:        Icons.home,
      accentColor: AppColors.amber,
    );
    if (!confirmed || !mounted) return;
    HapticFeedback.heavyImpact();
    setState(() {
      _followActive = false;
      _isCommandPending = true;
    });
    _mavlink.sendRtl();
    _snack('RTL komutu gönderildi — yanıt bekleniyor...', Icons.hourglass_top, AppColors.amber);
  }

  Future<void> _onMissionStart() async {
    if (!_requireConnection()) return;
    final confirmed = await ConfirmDialog.show(
      context,
      title:       'GÖREV BAŞLAT',
      description: 'Yüklenmiş görev planı başlatılacak.\nDrone otonom olarak waypoint\'leri takip edecek.',
      icon:        Icons.route,
      accentColor: AppColors.cyan,
    );
    if (!confirmed || !mounted) return;
    HapticFeedback.heavyImpact();
    setState(() {
      _followActive = false;
      _isCommandPending = true;
    });
    _mavlink.sendMissionStart();
    _snack('GÖREV komutu gönderildi — yanıt bekleniyor...', Icons.hourglass_top, AppColors.amber);
  }

  // ─── Yardımcılar ────────────────────────────────────────────────────────

  void _snack(String msg, IconData icon, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        backgroundColor: AppColors.greyD,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: BorderSide(color: color.withOpacity(0.4)),
        ),
        content: Row(children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 8),
          Expanded(
            child: Text(msg,
                style: const TextStyle(
                  color: AppColors.white, fontSize: 11, letterSpacing: 1,
                )),
          ),
        ]),
        duration: const Duration(seconds: 2),
      ));
  }

  @override
  void dispose() {
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
    _pulseCtrl.dispose();
    _bgCtrl.dispose();
    _radarCtrl.dispose();
    _ipCtrl.dispose();
    _portCtrl.dispose();
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(children: [
        AnimatedBuilder(
          animation: _bgCtrl,
          builder: (_, __) => CustomPaint(
            size: MediaQuery.of(context).size,
            painter: BgScanPainter(progress: _bgCtrl.value, red: AppColors.red),
          ),
        ),
        if (_mapFullscreen)
          _buildFullscreen()
        else
          SafeArea(
            child: Column(children: [
              TopBar(isConnected: _isConnected, pulse: _pulse),
              _buildMapArea(),
              const SizedBox(height: 6),
              TelemetryBar(telemetry: _droneTelemetry, flightTime: _flightTime),
              const SizedBox(height: 2),
              _buildTabBar(),
              Expanded(child: _buildTabContent()),
            ]),
          ),
      ]),
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 36,
      margin: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.greyD),
        borderRadius: BorderRadius.circular(3),
      ),
      child: TabBar(
        controller: _tabCtrl,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: AppColors.red.withOpacity(0.12),
          border: Border(bottom: BorderSide(color: AppColors.red, width: 2)),
        ),
        labelColor: AppColors.red,
        unselectedLabelColor: AppColors.grey,
        labelStyle: const TextStyle(fontSize: 10, letterSpacing: 3, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w500),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'KOMUTLAR'),
          Tab(text: 'AYARLAR'),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    return TabBarView(
      controller: _tabCtrl,
      children: [
        // Tab 1: Komutlar
        SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Column(children: [
            CommandPanel(
              followActive:       _followActive,
              followState:        _followState,
              isConnected:        _isConnected,
              onFollowToggle:     _toggleFollow,
              onHold:             _onHold,
              onLand:             _onLand,
              onOrbit:            _onOrbit,
              onStabilize:        _onStabilize,
              defaultOrbitRadius: _flightSettings.defaultOrbitRadius,
            ),
            if (_followActive) ...[
              const SizedBox(height: 10),
              FollowStateBar(currentState: _followState),
            ],
            const SizedBox(height: 10),
            FlightCommandPanel(
              isArmed:        _droneTelemetry.isArmed,
              onArmDisarm:    _onArmDisarm,
              onTakeoff:      _onTakeoff,
              onRtl:          _onRtl,
              onMissionStart: _onMissionStart,
            ),
            const SizedBox(height: 20),
            _buildFooter(),
          ]),
        ),

        // Tab 2: Ayarlar
        SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Column(children: [
            ConnectionPanel(
              ipCtrl:   _ipCtrl,
              portCtrl: _portCtrl,
              onSave:   _saveSettings,
            ),
            const SizedBox(height: 10),
            FlightSettingsPanel(
              settings: _flightSettings,
              onSave:   _saveFlightSettings,
            ),
            const SizedBox(height: 20),
            _buildFooter(),
          ]),
        ),
      ],
    );
  }

  Widget _buildMapArea() {
    return GestureDetector(
      onTap: () => setState(() => _mapFullscreen = true),
      child: Container(
        height: 220,
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0A0A),
          border: Border.all(
            color: (_videoConnected ? AppColors.green : AppColors.red).withOpacity(
              _videoConnected ? 0.45 : 0.35,
            ),
          ),
          borderRadius: BorderRadius.circular(3),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: VideoHud(
            frame:          _currentFrame,
            videoConnected: _videoConnected,
            fullscreen:     false,
            lat: _lat, lon: _lon, alt: _alt,
            radarAngle:     _radarAngle,
          ),
        ),
      ),
    );
  }

  Widget _buildFullscreen() {
    return GestureDetector(
      onTap: () => setState(() => _mapFullscreen = false),
      child: Stack(children: [
        VideoHud(
          frame:          _currentFrame,
          videoConnected: _videoConnected,
          fullscreen:     true,
          lat: _lat, lon: _lon, alt: _alt,
          radarAngle:     _radarAngle,
        ),
        Positioned(top: 48, right: 16,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.red.withOpacity(0.5)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(Icons.fullscreen_exit, color: AppColors.red, size: 20),
          ),
        ),
        Positioned(bottom: 24, left: 0, right: 0,
          child: Center(
            child: Text('KÜÇÜLTMEK İÇİN DOKUN',
                style: TextStyle(
                  color: AppColors.grey.withOpacity(0.5),
                  fontSize: 9, letterSpacing: 3,
                )),
          ),
        ),
      ]),
    );
  }

  Widget _buildFooter() {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text('ODİN  v2.0.0',
          style: TextStyle(color: AppColors.grey.withOpacity(0.3), fontSize: 9, letterSpacing: 2)),
      Text('RAVENS OF THE SKY',
          style: TextStyle(color: AppColors.grey.withOpacity(0.2), fontSize: 9, letterSpacing: 2)),
    ]);
  }
}