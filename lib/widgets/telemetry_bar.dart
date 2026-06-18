import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../models/drone_telemetry.dart';
import 'telemetry_chip.dart';

/// Video HUD altında gösterilen kompakt telemetri şeridi.
/// DroneTelemetry verisini alarak batarya, hız, irtifa, mesafe,
/// GPS uydu, uçuş modu bilgilerini yatay chip'ler halinde gösterir.
class TelemetryBar extends StatelessWidget {
  final DroneTelemetry telemetry;

  const TelemetryBar({super.key, required this.telemetry});

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
          // Batarya
          TelemetryChip(
            icon:  _batteryIcon(),
            value: telemetry.batteryPercent >= 0
                ? '${telemetry.batteryPercent}'
                : '--',
            unit:  '%',
            color: _batteryColor(),
          ),

          // Hız
          TelemetryChip(
            icon:  Icons.speed,
            value: telemetry.groundSpeed.toStringAsFixed(1),
            unit:  'm/s',
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
                : '${(telemetry.distanceToGcs / 1000).toStringAsFixed(1)}k',
            unit:  'm',
            color: AppColors.redL,
          ),

          // GPS uydu
          TelemetryChip(
            icon:  Icons.satellite_alt,
            value: '${telemetry.satelliteCount}',
            unit:  'sat',
            color: _gpsColor(),
          ),

          // Uçuş modu
          TelemetryChip(
            icon:  Icons.flight,
            value: telemetry.flightMode,
            color: AppColors.white,
          ),
        ],
      ),
    );
  }
}
