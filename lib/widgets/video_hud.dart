import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../painters/grid_painter.dart';
import '../painters/mini_radar_painter.dart';
import '../painters/hud_corner_painter.dart';

/// Video akışını veya radar/grid fallback'ini gösterir.
/// Üstüne HUD overlay, koordinat bilgisi ve sinyal durumu çizer.
class VideoHud extends StatelessWidget {
  final Uint8List? frame;
  final bool       videoConnected;
  final bool       fullscreen;
  final double     lat, lon, alt;
  final Animation<double> radarAngle;

  const VideoHud({
    super.key,
    required this.frame,
    required this.videoConnected,
    required this.fullscreen,
    required this.lat,
    required this.lon,
    required this.alt,
    required this.radarAngle,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Stack(children: [
      // Arka plan
      if (frame != null)
        Positioned.fill(child: Image.memory(frame!, fit: BoxFit.cover, gaplessPlayback: true))
      else ...[
        CustomPaint(
          size: fullscreen ? size : const Size(double.infinity, 240),
          painter: const GridPainter(color: Color(0xFF161616), step: 24),
        ),
        Positioned.fill(
          child: Opacity(
            opacity: 0.15,
            child: Image.asset('assets/images/gogebakanlar_logo.png', fit: BoxFit.contain),
          ),
        ),
        Center(
          child: AnimatedBuilder(
            animation: radarAngle,
            builder: (_, __) => CustomPaint(
              size: Size(
                fullscreen ? size.width * 0.7 : 180,
                fullscreen ? size.width * 0.7 : 180,
              ),
              painter: MiniRadarPainter(angle: radarAngle.value, red: AppColors.red),
            ),
          ),
        ),
      ],

      // HUD çerçevesi
      CustomPaint(
        size: fullscreen ? size : const Size(double.infinity, 240),
        painter: HudCornerPainter(color: AppColors.red, opacity: 0.45, strokeWidth: 1.5, cornerLen: 14, pad: 8),
      ),

      // Koordinatlar
      Positioned(
        top: 8, left: 10, right: 10,
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('LAT: ${lat.toStringAsFixed(5)}  LON: ${lon.toStringAsFixed(5)}',
              style: TextStyle(color: AppColors.red.withOpacity(0.85), fontSize: 8, letterSpacing: 1, fontFamily: 'monospace')),
          Text('ALT: ${alt.toStringAsFixed(1)}m',
              style: TextStyle(color: AppColors.red.withOpacity(0.85), fontSize: 8, letterSpacing: 1, fontFamily: 'monospace')),
        ]),
      ),

      // Sinyal durumu
      Positioned(
        bottom: 8, right: 10,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(2),
            border: Border.all(color: (videoConnected ? AppColors.green : AppColors.grey).withOpacity(0.4)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 5, height: 5, decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: videoConnected ? AppColors.green : AppColors.grey,
            )),
            const SizedBox(width: 5),
            Text(videoConnected ? 'LIVE' : 'NO SIGNAL',
                style: TextStyle(
                  color: videoConnected ? AppColors.green : AppColors.grey,
                  fontSize: 8, letterSpacing: 2, fontWeight: FontWeight.w700,
                )),
          ]),
        ),
      ),
    ]);
  }
}