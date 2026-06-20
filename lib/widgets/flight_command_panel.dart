import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import 'tactical_button.dart';
import 'transition_dialog.dart';

/// Takeoff, RTL ve Mission Start butonlarını içeren ikinci komut paneli.
/// Callback'ler main_screen'den gelir; dialog/onay mantığı oradan yönetilir.
class FlightCommandPanel extends StatelessWidget {
  final bool isArmed;
  final VoidCallback onArmDisarm;
  final VoidCallback onTakeoff;
  final VoidCallback onRtl;
  final VoidCallback onMissionStart;
  final void Function(bool toMulticopter) onTransition;

  const FlightCommandPanel({
    super.key,
    required this.isArmed,
    required this.onArmDisarm,
    required this.onTakeoff,
    required this.onRtl,
    required this.onMissionStart,
    required this.onTransition,
  });

  Widget _header(String title, IconData icon) => Row(children: [
    Container(width: 3, height: 16, color: AppColors.red, margin: const EdgeInsets.only(right: 8)),
    Icon(icon, color: AppColors.red, size: 13),
    const SizedBox(width: 6),
    Text(title, style: const TextStyle(color: AppColors.white, fontSize: 11, letterSpacing: 3, fontWeight: FontWeight.w600)),
  ]);

  Future<void> _handleTransition(BuildContext context) async {
    final toMc = await TransitionDialog.show(context);
    if (toMc != null) {
      onTransition(toMc);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.greyD),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _header('UÇUŞ KOMUTLARI', Icons.flight_takeoff),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(
            child: TacticalButton(
              label: isArmed ? 'DISARM' : 'ARM',
              icon: Icons.power_settings_new,
              color: isArmed ? AppColors.redL : AppColors.green,
              onTap: onArmDisarm,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TacticalButton(
              label: 'TAKEOFF',
              icon: Icons.flight_takeoff,
              color: AppColors.green,
              onTap: onTakeoff,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TacticalButton(
              label: 'RTL',
              icon: Icons.home,
              color: AppColors.amber,
              onTap: onRtl,
            ),
          ),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: TacticalButton(
              label: 'GÖREV BAŞLAT',
              icon: Icons.route,
              color: AppColors.cyan,
              onTap: onMissionStart,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TacticalButton(
              label: 'TRANSITION',
              icon: Icons.transform,
              color: AppColors.amber,
              onTap: () => _handleTransition(context),
            ),
          ),
        ]),
      ]),
    );
  }
}
