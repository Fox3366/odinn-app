import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import 'tactical_button.dart';

class TransitionDialog extends StatelessWidget {
  const TransitionDialog({super.key});

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => const TransitionDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.cyan),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.transform, color: AppColors.cyan, size: 40),
            const SizedBox(height: 14),
            const Text(
              'VTOL GEÇİŞİ',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Hangi uçuş moduna geçiş yapmak istiyorsunuz?',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.grey, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TacticalButton(
                    label: 'MULTICOPTER',
                    icon: Icons.flight_takeoff,
                    color: AppColors.amber,
                    onTap: () => Navigator.pop(context, true), // true = to MC
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TacticalButton(
                    label: 'SABİT KANAT',
                    icon: Icons.flight,
                    color: AppColors.cyan,
                    onTap: () => Navigator.pop(context, false), // false = to FW
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text(
                'İPTAL',
                style: TextStyle(color: AppColors.grey, letterSpacing: 2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
