import 'package:flutter/material.dart';
import '../core/app_colors.dart';

class TopBar extends StatelessWidget {
  final bool             isConnected;
  final Animation<double> pulse;

  const TopBar({super.key, required this.isConnected, required this.pulse});

  @override
  Widget build(BuildContext context) {
    final statusColor = isConnected ? AppColors.green : AppColors.red;
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.95),
        border: Border(bottom: BorderSide(color: AppColors.red.withOpacity(0.4))),
      ),
      child: Row(children: [
        const Icon(Icons.flight, color: AppColors.red, size: 18),
        const SizedBox(width: 8),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ODİN', style: TextStyle(color: AppColors.white, fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 5)),
            Text('TACTICAL AERIAL INTELLIGENCE', style: TextStyle(color: AppColors.grey, fontSize: 7, letterSpacing: 2)),
          ],
        ),
        const Spacer(),
        AnimatedBuilder(
          animation: pulse,
          builder: (_, __) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.08),
              border: Border.all(color: statusColor.withOpacity(0.4)),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Row(children: [
              Container(
                width: 7, height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: statusColor.withOpacity(pulse.value),
                  boxShadow: [BoxShadow(color: statusColor.withOpacity(0.7), blurRadius: 8)],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                isConnected ? 'QGC BAĞLI' : 'BAĞLANTI YOK',
                style: TextStyle(color: statusColor, fontSize: 9, letterSpacing: 2, fontWeight: FontWeight.w700),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}