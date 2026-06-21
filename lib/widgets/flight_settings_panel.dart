import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../models/flight_settings.dart';

/// Follow Me irtifa/mesafe ve genel uçuş ayarları paneli.
/// Kullanıcı parametreleri görsel olarak düzenler, KAYDET ile callback çağrılır.
class FlightSettingsPanel extends StatefulWidget {
  final FlightSettings      settings;
  final ValueChanged<FlightSettings> onSave;

  const FlightSettingsPanel({
    super.key,
    required this.settings,
    required this.onSave,
  });

  @override
  State<FlightSettingsPanel> createState() => _FlightSettingsPanelState();
}

class _FlightSettingsPanelState extends State<FlightSettingsPanel> {
  late TextEditingController _followAltCtrl;
  late TextEditingController _nearCtrl;
  late TextEditingController _farCtrl;
  late TextEditingController _orbitCtrl;
  late TextEditingController _takeoffCtrl;

  @override
  void initState() {
    super.initState();
    final s = widget.settings;
    _followAltCtrl = TextEditingController(text: s.followAltitude.toStringAsFixed(0));
    _nearCtrl      = TextEditingController(text: s.followDistanceNear.toStringAsFixed(0));
    _farCtrl       = TextEditingController(text: s.followDistanceFar.toStringAsFixed(0));
    _orbitCtrl     = TextEditingController(text: s.defaultOrbitRadius.toStringAsFixed(0));
    _takeoffCtrl   = TextEditingController(text: s.defaultTakeoffAlt.toStringAsFixed(0));
  }

  @override
  void didUpdateWidget(FlightSettingsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings != widget.settings) {
      final s = widget.settings;
      _followAltCtrl.text = s.followAltitude.toStringAsFixed(0);
      _nearCtrl.text      = s.followDistanceNear.toStringAsFixed(0);
      _farCtrl.text       = s.followDistanceFar.toStringAsFixed(0);
      _orbitCtrl.text     = s.defaultOrbitRadius.toStringAsFixed(0);
      _takeoffCtrl.text   = s.defaultTakeoffAlt.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _followAltCtrl.dispose();
    _nearCtrl.dispose();
    _farCtrl.dispose();
    _orbitCtrl.dispose();
    _takeoffCtrl.dispose();
    super.dispose();
  }

  double _parse(TextEditingController c, double fallback) {
    final v = double.tryParse(c.text.trim());
    return (v != null && v > 0) ? v : fallback;
  }

  void _save() {
    final updated = FlightSettings(
      followAltitude:     _parse(_followAltCtrl, 30),
      followDistanceNear: _parse(_nearCtrl, 150),
      followDistanceFar:  _parse(_farCtrl, 300),
      defaultOrbitRadius: _parse(_orbitCtrl, 50),
      defaultTakeoffAlt:  _parse(_takeoffCtrl, 10),
    );
    widget.onSave(updated);
  }

  Widget _header(String title, IconData icon) => Row(children: [
    Container(width: 3, height: 16, color: AppColors.red, margin: const EdgeInsets.only(right: 8)),
    Icon(icon, color: AppColors.red, size: 13),
    const SizedBox(width: 6),
    Text(title, style: const TextStyle(color: AppColors.white, fontSize: 11, letterSpacing: 3, fontWeight: FontWeight.w600)),
  ]);

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String unit,
    required IconData icon,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: AppColors.grey, fontSize: 8, letterSpacing: 2)),
      const SizedBox(height: 6),
      TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: const TextStyle(color: AppColors.white, fontSize: 13, letterSpacing: 1),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: AppColors.grey, size: 15),
          suffixText: unit,
          suffixStyle: TextStyle(color: AppColors.grey.withValues(alpha: 0.5), fontSize: 11),
          filled: true, fillColor: AppColors.bg,
          border:        OutlineInputBorder(borderSide: BorderSide(color: AppColors.greyD), borderRadius: BorderRadius.circular(3)),
          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.greyD), borderRadius: BorderRadius.circular(3)),
          focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.red.withValues(alpha: 0.6)), borderRadius: BorderRadius.circular(3)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        ),
      ),
    ]);
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
        _header('UÇUŞ AYARLARI', Icons.tune),
        const SizedBox(height: 14),

        // Takip Ayarları
        Row(children: [
          Expanded(child: _field(controller: _followAltCtrl, label: 'TAKİP İRTİFASI', unit: 'm', icon: Icons.height)),
          const SizedBox(width: 10),
          Expanded(child: _field(controller: _orbitCtrl, label: 'ORBİT YARICAPI', unit: 'm', icon: Icons.rotate_right)),
        ]),
        const SizedBox(height: 10),

        Row(children: [
          Expanded(child: _field(controller: _nearCtrl, label: 'MC GEÇİŞ MESAFESİ', unit: 'm', icon: Icons.near_me)),
          const SizedBox(width: 10),
          Expanded(child: _field(controller: _farCtrl, label: 'FW YAKLAŞMA MESAFESİ', unit: 'm', icon: Icons.flight)),
        ]),
        const SizedBox(height: 10),

        Row(children: [
          Expanded(child: _field(controller: _takeoffCtrl, label: 'KALKIŞ İRTİFASI', unit: 'm', icon: Icons.flight_takeoff)),
          const Expanded(child: SizedBox()), // Boş alan — dengelemek için
        ]),
        const SizedBox(height: 14),

        // Kaydet butonu
        GestureDetector(
          onTap: _save,
          child: Container(
            width: double.infinity, height: 46,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.red.withValues(alpha: 0.15), Colors.transparent], begin: Alignment.centerLeft),
              border: Border.all(color: AppColors.red.withValues(alpha: 0.5)),
              borderRadius: BorderRadius.circular(3),
            ),
            child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.save_outlined, color: AppColors.red, size: 16),
              SizedBox(width: 8),
              Text('AYARLARI KAYDET', style: TextStyle(color: AppColors.red, fontSize: 12, letterSpacing: 4, fontWeight: FontWeight.w700)),
            ]),
          ),
        ),
      ]),
    );
  }
}
