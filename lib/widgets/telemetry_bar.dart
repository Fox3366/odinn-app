import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../models/drone_telemetry.dart';
import 'telemetry_chip.dart';

/// Video HUD altında gösterilen kompakt telemetri şeridi.
/// DroneTelemetry verisini alarak batarya, hız, irtifa, mesafe,
/// GPS uydu, uçuş modu, voltaj ve uçuş süresi bilgilerini gösterir.
class TelemetryBar extends StatelessWidget {
  final DroneTelemetry telemetry;
  final Duration flightTime;

  const TelemetryBar({
    super.key,
    required this.telemetry,
    this.flightTime = Duration.zero,
  });

  Color _batteryColor() {
    if (telemetry.batteryPercent < 0)  return AppColors.grey;
    if (telemetry.batteryPercent > 50) return AppColors.green;
    if (telemetry.batteryPercent > 20) return AppColors.amber;
    return AppColors.red;
  }

  IconData _batteryIcon() {
    if (telemetry.batteryPercent < 0)  return Icons.battery_unknown;
    if (telemetry.batteryPercent > 80) return Icons.battery_full;
    if (telemetry.batteryPercent > 50) return Icons.battery_5_bar;
    if (telemetry.batteryPercent > 20) return Icons.battery_3_bar;
    return Icons.battery_1_bar;
  }

  Color _gpsColor() {
    if (telemetry.gpsFixType >= 3) return AppColors.green;
    if (telemetry.gpsFixType == 2) return AppColors.amber;
    return AppColors.red;
  }

  Color _modeColor() {
    final m = telemetry.flightMode.toUpperCase();
    if (m.contains('RTL') || m.contains('LAND'))   return AppColors.amber;
    if (m.contains('MISSION') || m.contains('AUTO')) return AppColors.cyan;
    if (m.contains('STABILIZED') || m.contains('MANUAL')) return AppColors.redL;
    if (m.contains('OFFBOARD'))  return AppColors.green;
    if (m.contains('LOITER') || m.contains('POSCTL')) return AppColors.green;
    return AppColors.white;
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (d.inHours > 0) {
      final h = d.inHours.toString().padLeft(2, '0');
      return '$h:$m:$s';
    }
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.greyD),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          // Batarya %
          TelemetryChip(
            icon:  _batteryIcon(),
            value: telemetry.batteryPercent >= 0
                ? '${telemetry.batteryPercent}'
                : '--',
            unit:  '%',
            color: _batteryColor(),
          ),

          // Batarya Voltaj
          TelemetryChip(
            icon:  Icons.bolt,
            value: telemetry.batteryVoltage > 0
                ? telemetry.batteryVoltage.toStringAsFixed(1)
                : '--',
            unit:  'V',
            color: _batteryColor(),
          ),

          // Batarya Akım
          TelemetryChip(
            icon:  Icons.electric_meter,
            value: telemetry.batteryCurrent >= 0
                ? telemetry.batteryCurrent.toStringAsFixed(1)
                : '--',
            unit:  'A',
            color: _batteryColor(),
          ),

          // Hız
          TelemetryChip(
            icon:  Icons.speed,
            value: telemetry.groundSpeed.toStringAsFixed(1),
            unit:  'm/s',
            color: AppColors.cyan,
          ),

          // Throttle
          TelemetryChip(
            icon:  Icons.flight_takeoff, // or similar icon like swap_vert or adjust
            value: '${telemetry.throttle}',
            unit:  '%',
            color: AppColors.cyan,
          ),

          // İrtifa (AGL)
          TelemetryChip(
            icon:  Icons.height,
            value: telemetry.relativeAlt.toStringAsFixed(1),
            unit:  'm',
            color: AppColors.amber,
          ),

          // GCS-Drone Mesafesi
          TelemetryChip(
            icon:  Icons.social_distance,
            value: telemetry.distanceToGcs < 1000
                ? telemetry.distanceToGcs.toStringAsFixed(0)
                : (telemetry.distanceToGcs / 1000).toStringAsFixed(1),
            unit:  telemetry.distanceToGcs < 1000 ? 'm' : 'km',
            color: AppColors.redL,
          ),

          // GPS uydu
          TelemetryChip(
            icon:  Icons.satellite_alt,
            value: '${telemetry.satelliteCount}',
            unit:  'sat',
            color: _gpsColor(),
          ),

          // Uçuş Modu
          TelemetryChip(
            icon:  Icons.flight,
            value: telemetry.flightMode,
            color: _modeColor(),
          ),

          // Uçuş Süresi
          if (telemetry.isArmed || flightTime > Duration.zero)
            TelemetryChip(
              icon:  Icons.timer_outlined,
              value: _formatDuration(flightTime),
              color: telemetry.isArmed ? AppColors.green : AppColors.grey,
            ),
        ],
      ),
    );
  }
}
