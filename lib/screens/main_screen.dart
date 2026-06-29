import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/app_colors.dart';
import '../models/follow_state.dart';
import '../models/flight_settings.dart';
import '../models/drone_telemetry.dart';
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
import 'mission_screen.dart';

import 'main_cubit.dart';
import 'main_state.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MainCubit(),
      child: const _MainScreenBody(),
    );
  }
}

class _MainScreenBody extends StatefulWidget {
  const _MainScreenBody({super.key});
  @override
  State<_MainScreenBody> createState() => _MainScreenBodyState();
}

class _MainScreenBodyState extends State<_MainScreenBody> with TickerProviderStateMixin {
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

  // ─── Komut Handler'ları ──────────────────────────────────────────────────

  Future<void> _onArmDisarm(MainState state) async {
    final cubit = context.read<MainCubit>();
    if (!cubit.requireConnection()) return;
    
    if (!state.droneTelemetry.isArmed) {
      final ok = await PreflightChecklistDialog.show(
        context,
        telemetry: state.droneTelemetry,
        isConnected: state.isConnected,
      );
      if (!ok || !mounted) return;
      cubit.sendArmDisarm(true);
    } else {
      final confirmed = await ConfirmDialog.show(
        context,
        title: 'MOTORLARI KAPAT',
        description: 'Drone motorları kapatılacak (DISARM).\nHavadaysa düşmesine sebep olur!',
        icon: Icons.power_settings_new,
        accentColor: AppColors.red,
      );
      if (!confirmed || !mounted) return;
      cubit.sendArmDisarm(false);
    }
  }

  Future<void> _onTakeoff(MainState state) async {
    final cubit = context.read<MainCubit>();
    if (!cubit.requireConnection()) return;
    
    final ok = await PreflightChecklistDialog.show(
      context,
      telemetry: state.droneTelemetry,
      isConnected: state.isConnected,
    );
    if (!ok || !mounted) return;

    final alt = await TakeoffDialog.show(
      context,
      defaultAltitude: state.flightSettings.defaultTakeoffAlt,
    );
    if (alt == null || !mounted) return;
    cubit.sendTakeoff(alt);
  }

  Future<void> _onRtl() async {
    final cubit = context.read<MainCubit>();
    if (!cubit.requireConnection()) return;
    final confirmed = await ConfirmDialog.show(
      context,
      title:       'RTL',
      description: 'Return to Launch komutu gönderilecek.\nDrone kalkış noktasına dönüp iniş yapacak.',
      icon:        Icons.home,
      accentColor: AppColors.amber,
    );
    if (!confirmed || !mounted) return;
    cubit.sendRtl();
  }

  Future<void> _onMissionStart() async {
    final cubit = context.read<MainCubit>();
    if (!cubit.requireConnection()) return;
    final confirmed = await ConfirmDialog.show(
      context,
      title:       'GÖREV BAŞLAT',
      description: 'Yüklenmiş görev planı başlatılacak.\nDrone otonom olarak waypoint\'leri takip edecek.',
      icon:        Icons.route,
      accentColor: AppColors.cyan,
    );
    if (!confirmed || !mounted) return;
    cubit.sendMissionStart();
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
          side: BorderSide(color: color.withValues(alpha: 0.4)),
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
    return MultiBlocListener(
      listeners: [
        BlocListener<MainCubit, MainState>(
          listenWhen: (prev, curr) => prev.snackBarMessage != curr.snackBarMessage && curr.snackBarMessage != null,
          listener: (context, state) {
            final msg = state.snackBarMessage!;
            _snack(msg.text, msg.icon, msg.color);
          },
        ),
        BlocListener<MainCubit, MainState>(
          listenWhen: (prev, curr) => prev.ip != curr.ip || prev.port != curr.port,
          listener: (context, state) {
            if (_ipCtrl.text != state.ip) _ipCtrl.text = state.ip;
            if (_portCtrl.text != state.port.toString()) _portCtrl.text = state.port.toString();
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.translucent,
          child: Stack(children: [
            AnimatedBuilder(
              animation: _bgCtrl,
              builder: (_, __) => CustomPaint(
                size: MediaQuery.of(context).size,
                painter: BgScanPainter(progress: _bgCtrl.value, red: AppColors.red),
              ),
            ),
            BlocBuilder<MainCubit, MainState>(
              builder: (context, state) {
                if (state.mapFullscreen) {
                  return _buildFullscreen(state);
                }
                final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
                return SafeArea(
                  child: Column(children: [
                    TopBar(isConnected: state.isConnected, pulse: _pulse),
                    if (!isKeyboardOpen) ...[
                      _buildMapArea(state),
                      const SizedBox(height: 6),
                    ],
                    TelemetryBar(telemetry: state.droneTelemetry, flightTime: state.flightTime),
                    const SizedBox(height: 2),
                    _buildTabBar(),
                    Expanded(child: _buildTabContent(state)),
                  ]),
                );
              },
            ),
          ]),
        ),
      ),
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
          color: AppColors.red.withValues(alpha: 0.12),
          border: const Border(bottom: BorderSide(color: AppColors.red, width: 2)),
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

  Widget _buildTabContent(MainState state) {
    final cubit = context.read<MainCubit>();
    return TabBarView(
      controller: _tabCtrl,
      children: [
        // Tab 1: Komutlar
        SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Column(children: [
            CommandPanel(
              followActive:       state.followActive,
              followState:        state.followState,
              isConnected:        state.isConnected,
              onFollowToggle:     cubit.toggleFollow,
              onOrbit:            cubit.sendOrbit,
              defaultOrbitRadius: state.flightSettings.defaultOrbitRadius,
              onTransition:       cubit.sendTransition,
            ),
            if (state.followActive) ...[
              const SizedBox(height: 10),
              FollowStateBar(currentState: state.followState),
            ],
            const SizedBox(height: 10),
            FlightCommandPanel(
              isArmed:        state.droneTelemetry.isArmed,
              onArmDisarm:    () => _onArmDisarm(state),
              onTakeoff:      () => _onTakeoff(state),
              onRtl:          _onRtl,
              onMissionStart: _onMissionStart,
              onLand:         cubit.sendLand,
              onHold:         cubit.sendHold,
              onStabilize:    cubit.sendStabilize,
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MissionScreen())),
              icon: const Icon(Icons.map, color: Colors.white),
              label: const Text('HARİTA VE GÖREV PLANLAYICI', style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cyan.withValues(alpha: 0.15),
                foregroundColor: AppColors.cyan,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                  side: BorderSide(color: AppColors.cyan.withValues(alpha: 0.5)),
                ),
              ),
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
              onSave:   () => cubit.saveSettings(_ipCtrl.text, _portCtrl.text),
            ),
            const SizedBox(height: 10),
            FlightSettingsPanel(
              settings: state.flightSettings,
              onSave:   cubit.saveFlightSettings,
            ),
            const SizedBox(height: 20),
            _buildFooter(),
          ]),
        ),
      ],
    );
  }

  Widget _buildMapArea(MainState state) {
    return GestureDetector(
      onTap: () => context.read<MainCubit>().setMapFullscreen(true),
      child: Container(
        height: 220,
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0A0A),
          border: Border.all(
            color: (state.videoConnected ? AppColors.green : AppColors.red).withValues(alpha: 
              state.videoConnected ? 0.45 : 0.35,
            ),
          ),
          borderRadius: BorderRadius.circular(3),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: VideoHud(
            frame:          state.currentFrame,
            videoConnected: state.videoConnected,
            fullscreen:     false,
            lat: state.lat, lon: state.lon, alt: state.alt,
            radarAngle:     _radarAngle,
          ),
        ),
      ),
    );
  }

  Widget _buildFullscreen(MainState state) {
    return GestureDetector(
      onTap: () => context.read<MainCubit>().setMapFullscreen(false),
      child: Stack(children: [
        VideoHud(
          frame:          state.currentFrame,
          videoConnected: state.videoConnected,
          fullscreen:     true,
          lat: state.lat, lon: state.lon, alt: state.alt,
          radarAngle:     _radarAngle,
        ),
        Positioned(top: 48, right: 16,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.red.withValues(alpha: 0.5)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(Icons.fullscreen_exit, color: AppColors.red, size: 20),
          ),
        ),
        Positioned(bottom: 24, left: 0, right: 0,
          child: Center(
            child: Text('KÜÇÜLTMEK İÇİN DOKUN',
                style: TextStyle(
                  color: AppColors.grey.withValues(alpha: 0.5),
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
          style: TextStyle(color: AppColors.grey.withValues(alpha: 0.3), fontSize: 9, letterSpacing: 2)),
      Text('RAVENS OF THE SKY',
          style: TextStyle(color: AppColors.grey.withValues(alpha: 0.2), fontSize: 9, letterSpacing: 2)),
    ]);
  }
}
