import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../models/follow_state.dart';
import 'follow_me_button.dart';
import 'tactical_button.dart';
import 'confirm_dialog.dart';
import 'orbit_dialog.dart';

/// Ana komut paneli — Follow Me, Orbit, Hold, Back To Land butonları.
/// Hold hariç tüm komutlar onay dialogu gösterir.
class CommandPanel extends StatelessWidget {
  final bool          followActive;
  final FollowState   followState;
  final bool          isConnected;
  final VoidCallback  onFollowToggle;
  final VoidCallback  onHold;
  final VoidCallback  onLand;
  final VoidCallback  onStabilize;
  final void Function(double radius) onOrbit;
  final double        defaultOrbitRadius;

  const CommandPanel({
    super.key,
    required this.followActive,
    required this.followState,
    required this.isConnected,
    required this.onFollowToggle,
    required this.onHold,
    required this.onLand,
    required this.onStabilize,
    required this.onOrbit,
    this.defaultOrbitRadius = 50.0,
  });

  String _statusText() {
    if (!isConnected) return 'GPS ve QGC bağlantısı bekleniyor...';
    switch (followState) {
      case FollowState.approaching:   return 'Sabit kanat modunda hedefe yaklaşıyor...';
      case FollowState.transitioning: return 'Multicopter moduna geçiş yapılıyor...';
      case FollowState.following:     return 'Multicopter ile takip aktif.';
      case FollowState.idle:          return 'Sistem hazır.';
    }
  }

  Color _statusColor() {
    if (!isConnected) return AppColors.grey;
    switch (followState) {
      case FollowState.approaching:   return AppColors.amber;
      case FollowState.transitioning: return AppColors.cyan;
      case FollowState.following:     return AppColors.green;
      case FollowState.idle:          return AppColors.green;
    }
  }

  Widget _header(String title, IconData icon) => Row(children: [
    Container(width: 3, height: 16, color: AppColors.red, margin: const EdgeInsets.only(right: 8)),
    Icon(icon, color: AppColors.red, size: 13),
    const SizedBox(width: 6),
    Text(title, style: const TextStyle(color: AppColors.white, fontSize: 11, letterSpacing: 3, fontWeight: FontWeight.w600)),
  ]);

  /// Follow Me toggle — onay dialogu gösterir
  Future<void> _handleFollowToggle(BuildContext context) async {
    if (followActive) {
      // Kapatma — onay istenmez
      onFollowToggle();
      return;
    }
    final confirmed = await ConfirmDialog.show(
      context,
      title:       'FOLLOW ME',
      description: 'Follow Me modu etkinleştirilecek.\nDrone telefonunuzu takip etmeye başlayacak.',
      icon:        Icons.person_pin_circle,
      accentColor: AppColors.red,
    );
    if (confirmed) onFollowToggle();
  }

  /// Orbit — yarıçap dialogu gösterir
  Future<void> _handleOrbit(BuildContext context) async {
    final radius = await OrbitDialog.show(context, defaultRadius: defaultOrbitRadius);
    if (radius != null) onOrbit(radius);
  }

  /// Land — onay dialogu gösterir
  Future<void> _handleLand(BuildContext context) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title:       'BACK TO LAND',
      description: 'İniş komutu gönderilecek.\nDrone bulunduğu konumda iniş yapacak.',
      icon:        Icons.flight_land,
      accentColor: AppColors.redL,
    );
    if (confirmed) onLand();
  }

  /// Hold — onay dialogu gösterir
  Future<void> _handleHold(BuildContext context) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title:       'HOLD (HAVADA ASILI KAL)',
      description: 'Drone bulunduğu konumda havada asılı kalacak (LOITER).\nMevcut görev veya takip durdurulacak.',
      icon:        Icons.pause_circle_outline,
      accentColor: Colors.orange,
    );
    if (confirmed) onHold();
  }

  /// Stabilize — onay dialogu gösterir
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
        _header('KOMUT PANELİ', Icons.gamepad_outlined),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: FollowMeButton(active: followActive, onTap: () => _handleFollowToggle(context))),
          const SizedBox(width: 10),
          Expanded(child: TacticalButton(label: 'ORBİT', icon: Icons.rotate_right, color: AppColors.cyan, onTap: () => _handleOrbit(context))),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: TacticalButton(label: 'HOLD', icon: Icons.pause_circle_outline, color: Colors.orange, onTap: () => _handleHold(context))),
          const SizedBox(width: 10),
          Expanded(child: TacticalButton(label: 'STABİLİZE', icon: Icons.settings_backup_restore, color: AppColors.cyan, onTap: () => _handleStabilize(context))),
          const SizedBox(width: 10),
          Expanded(child: TacticalButton(label: 'BACK TO\nLAND', icon: Icons.flight_land, color: AppColors.redL, onTap: () => _handleLand(context))),
        ]),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.bg,
            border: Border.all(color: AppColors.greyD),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Row(children: [
            Icon(Icons.info_outline, color: _statusColor(), size: 12),
            const SizedBox(width: 8),
            Text(_statusText(), style: const TextStyle(color: AppColors.grey, fontSize: 10, letterSpacing: 0.5)),
          ]),
        ),
      ]),
    );
  }
}