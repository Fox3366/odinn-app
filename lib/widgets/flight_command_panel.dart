import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import 'tactical_button.dart';
import 'confirm_dialog.dart';

/// Temel uçuş komutları ve acil durum müdahale butonları.
class FlightCommandPanel extends StatelessWidget {
  final bool isArmed;
  final VoidCallback onArmDisarm;
  final VoidCallback onTakeoff;
  final VoidCallback onRtl;
  final VoidCallback onMissionStart;
  final VoidCallback onLand;
  final VoidCallback onHold;
  final VoidCallback onStabilize;

  const FlightCommandPanel({
    super.key,
    required this.isArmed,
    required this.onArmDisarm,
    required this.onTakeoff,
    required this.onRtl,
    required this.onMissionStart,
    required this.onLand,
    required this.onHold,
    required this.onStabilize,
  });

  Widget _header(String title, IconData icon) => Row(children: [
    Container(width: 3, height: 16, color: AppColors.red, margin: const EdgeInsets.only(right: 8)),
    Icon(icon, color: AppColors.red, size: 13),
    const SizedBox(width: 6),
    Text(title, style: const TextStyle(color: AppColors.white, fontSize: 11, letterSpacing: 3, fontWeight: FontWeight.w600)),
  ]);

  Future<void> _handleLand(BuildContext context) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title:       'LAND (İNİŞ)',
      description: 'İniş komutu gönderilecek.\nDrone bulunduğu konumda iniş yapacak.',
      icon:        Icons.flight_land,
      accentColor: AppColors.redL,
    );
    if (confirmed) onLand();
  }

  Future<void> _handleHold(BuildContext context) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title:       'HOLD',
      description: 'Drone bulunduğu konumda havada asılı kalacak (LOITER).\nMevcut görev veya takip durdurulacak.',
      icon:        Icons.pause_circle_outline,
      accentColor: Colors.orange,
    );
    if (confirmed) onHold();
  }

  Future<void> _handleStabilize(BuildContext context) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title:       'STABİLİZE',
      description: 'Drone stabilize moduna alınacak.\nManuel kumanda kontrolü gerektirir.',
      icon:        Icons.settings_backup_restore,
      accentColor: AppColors.cyan,
    );
    if (confirmed) onStabilize();
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
        _header('TEMEL UÇUŞ & ACİL DURUM', Icons.flight_takeoff),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: TacticalButton(label: isArmed ? 'DISARM' : 'ARM', icon: Icons.power_settings_new, color: isArmed ? AppColors.redL : AppColors.green, onTap: onArmDisarm)),
          const SizedBox(width: 10),
          Expanded(child: TacticalButton(label: 'TAKEOFF', icon: Icons.flight_takeoff, color: AppColors.green, onTap: onTakeoff)),
          const SizedBox(width: 10),
          Expanded(child: TacticalButton(label: 'LAND', icon: Icons.flight_land, color: AppColors.amber, onTap: () => _handleLand(context))),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: TacticalButton(label: 'GÖREV BAŞLAT', icon: Icons.route, color: AppColors.cyan, onTap: onMissionStart)),
          const SizedBox(width: 10),
          Expanded(child: TacticalButton(label: 'RTL (EVE DÖN)', icon: Icons.home, color: AppColors.amber, onTap: onRtl)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: TacticalButton(label: 'HOLD', icon: Icons.pause_circle_outline, color: Colors.orange, onTap: () => _handleHold(context))),
          const SizedBox(width: 10),
          Expanded(child: TacticalButton(label: 'STABİLİZE', icon: Icons.settings_backup_restore, color: AppColors.cyan, onTap: () => _handleStabilize(context))),
        ]),
      ]),
    );
  }
}
