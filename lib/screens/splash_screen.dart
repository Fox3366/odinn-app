import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/app_colors.dart';
import '../painters/radar_painter.dart';
import '../painters/hud_corner_painter.dart';
import '../painters/grid_painter.dart';
import '../widgets/loading_bar.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _radarCtrl, _ringCtrl, _hudCtrl,
      _logoCtrl, _textCtrl, _pulseCtrl;
  late Animation<double> _radarAngle, _ringScale, _hudOpacity,
      _logoOpacity, _logoScale, _textOpacity, _pulse;

  int _typewriterIndex = 0;
  static const String _title = 'ODİN';

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
    );
    _initAnimations();
    _startSequence();
  }

  void _initAnimations() {
    _radarCtrl  = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
    _radarAngle = Tween<double>(begin: 0, end: 2 * pi).animate(_radarCtrl);

    _ringCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000));
    _ringScale = CurvedAnimation(parent: _ringCtrl, curve: Curves.easeOut);

    _hudCtrl    = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _hudOpacity = CurvedAnimation(parent: _hudCtrl, curve: Curves.easeIn);

    _logoCtrl    = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _logoOpacity = CurvedAnimation(parent: _logoCtrl, curve: Curves.easeIn);
    _logoScale   = Tween<double>(begin: 0.7, end: 1.0).animate(
        CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOutBack));

    _textCtrl    = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _textOpacity = CurvedAnimation(parent: _textCtrl, curve: Curves.easeIn);

    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.6, end: 1.0).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  Future<void> _startSequence() async {
    _ringCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 400));
    _hudCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 600));
    _logoCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 800));
    _textCtrl.forward();
    _runTypewriter();
    await Future.delayed(const Duration(milliseconds: 2500));
    if (mounted) Navigator.of(context).pushReplacementNamed('/main');
  }

  Future<void> _runTypewriter() async {
    for (int i = 0; i <= _title.length; i++) {
      await Future.delayed(const Duration(milliseconds: 90));
      if (mounted) setState(() => _typewriterIndex = i);
    }
  }

  @override
  void dispose() {
    _radarCtrl.dispose(); _ringCtrl.dispose(); _hudCtrl.dispose();
    _logoCtrl.dispose();  _textCtrl.dispose(); _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(children: [
        CustomPaint(size: size, painter: const GridPainter(color: AppColors.grid)),

        Center(
          child: AnimatedBuilder(
            animation: Listenable.merge([_radarAngle, _ringScale, _pulse]),
            builder: (_, __) => CustomPaint(
              size: Size(size.width * 0.78, size.width * 0.78),
              painter: RadarPainter(
                angle: _radarAngle.value, ringProgress: _ringScale.value,
                pulse: _pulse.value, red: AppColors.red, redL: AppColors.redL,
              ),
            ),
          ),
        ),

        FadeTransition(
          opacity: _hudOpacity,
          child: CustomPaint(size: size, painter: const HudCornerPainter(color: AppColors.red)),
        ),

        Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            FadeTransition(
              opacity: _logoOpacity,
              child: ScaleTransition(
                scale: _logoScale,
                child: Container(
                  width: 90, height: 90,
                  // HATA DÜZELTİLDİ: Buradaki BoxDecoration önceden const'tu.
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.red, width: 2),
                  ),
                  child: Center(
                    child: Image.asset(
                      'assets/images/muninn.png',
                      width: 100, height: 100, fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            FadeTransition(
              opacity: _textOpacity,
              child: Text(
                _title.substring(0, _typewriterIndex),
                style: const TextStyle(
                  color: AppColors.white, fontSize: 26,
                  fontWeight: FontWeight.w700, letterSpacing: 6, fontFamily: 'monospace',
                ),
              ),
            ),
            const SizedBox(height: 8),
            FadeTransition(
              opacity: _textOpacity,
              child: const Text(
                'RAVENS OF THE SKY — TACTICAL INTELLIGENCE',
                style: TextStyle(
                  color: AppColors.red, fontSize: 12,
                  letterSpacing: 4, fontWeight: FontWeight.w400,
                ),
              ),
            ),
            const SizedBox(height: 44),
            FadeTransition(opacity: _textOpacity, child: const LoadingBar()),
          ]),
        ),

        Positioned(right: 20, bottom: 24,
          child: FadeTransition(
            opacity: _textOpacity,
            child: const Text('v1.0.0',
                style: TextStyle(color: AppColors.grey, fontSize: 11, letterSpacing: 2)),
          ),
        ),

        Positioned(left: 20, bottom: 24,
          child: FadeTransition(
            opacity: _textOpacity,
            child: Row(children: [
              AnimatedBuilder(
                animation: _pulse,
                builder: (_, __) => Container(
                  width: 7, height: 7,
                  decoration: BoxDecoration(
                    color: AppColors.red.withOpacity(_pulse.value),
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: AppColors.red.withOpacity(0.6), blurRadius: 6)],
                  ),
                ),
              ),
              const SizedBox(width: 7),
              const Text('SYSTEM BOOT',
                  style: TextStyle(color: AppColors.grey, fontSize: 10, letterSpacing: 2)),
            ]),
          ),
        ),
      ]),
    );
  }
}