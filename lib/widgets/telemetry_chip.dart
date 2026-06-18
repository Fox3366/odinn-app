import 'package:flutter/material.dart';
import '../core/app_colors.dart';

/// Tek bir telemetri değerini gösteren kompakt, yeniden kullanılabilir chip widget.
/// [TelemetryBar] tarafından satır içi kullanılır.
class TelemetryChip extends StatelessWidget {
  final IconData icon;
  final String   value;
  final String   unit;
  final Color    color;

  const TelemetryChip({
    super.key,
    required this.icon,
    required this.value,
    this.unit  = '',
    this.color = AppColors.grey,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.bg,
        border: Border.all(color: color.withOpacity(0.25)),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 11),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            fontFamily: 'monospace',
          ),
        ),
        if (unit.isNotEmpty) ...[
          const SizedBox(width: 2),
          Text(
            unit,
            style: TextStyle(
              color: color.withOpacity(0.6),
              fontSize: 8,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ]),
    );
  }
}
