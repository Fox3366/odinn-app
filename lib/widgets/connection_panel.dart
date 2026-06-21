import 'package:flutter/material.dart';
import '../core/app_colors.dart';

class ConnectionPanel extends StatelessWidget {
  final TextEditingController ipCtrl;
  final TextEditingController portCtrl;
  final VoidCallback          onSave;

  const ConnectionPanel({
    super.key,
    required this.ipCtrl,
    required this.portCtrl,
    required this.onSave,
  });

  Widget _header(String title, IconData icon) => Row(children: [
    Container(width: 3, height: 16, color: AppColors.red, margin: const EdgeInsets.only(right: 8)),
    Icon(icon, color: AppColors.red, size: 13),
    const SizedBox(width: 6),
    Text(title, style: const TextStyle(color: AppColors.white, fontSize: 11, letterSpacing: 3, fontWeight: FontWeight.w600)),
  ]);

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required TextInputType keyboard,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: AppColors.grey, fontSize: 8, letterSpacing: 2)),
      const SizedBox(height: 6),
      TextField(
        controller: controller,
        keyboardType: keyboard,
        style: const TextStyle(color: AppColors.white, fontSize: 13, letterSpacing: 1),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: AppColors.grey.withValues(alpha: 0.3), fontSize: 12),
          prefixIcon: Icon(icon, color: AppColors.grey, size: 15),
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
        _header('BAĞLANTI AYARLARI', Icons.wifi),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(flex: 3, child: _field(controller: ipCtrl,   label: 'IP ADRESİ', hint: '10.0.2.2', icon: Icons.router_outlined, keyboard: TextInputType.url)),
          const SizedBox(width: 10),
          Expanded(flex: 2, child: _field(controller: portCtrl, label: 'PORT',      hint: '14540',    icon: Icons.numbers,          keyboard: TextInputType.number)),
        ]),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: onSave,
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
              Text('KAYDET', style: TextStyle(color: AppColors.red, fontSize: 12, letterSpacing: 4, fontWeight: FontWeight.w700)),
            ]),
          ),
        ),
      ]),
    );
  }
}
