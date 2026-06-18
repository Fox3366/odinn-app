import 'package:flutter/material.dart';
import '../core/app_colors.dart';

/// Kritik komutlar için yeniden kullanılabilir onay dialogu.
/// HOLD hariç tüm komutlar bu dialogu kullanır.
class ConfirmDialog extends StatelessWidget {
  final String   title;
  final String   description;
  final IconData icon;
  final Color    accentColor;

  const ConfirmDialog({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    this.accentColor = AppColors.red,
  });

  /// Dialogu gösterir. Onaylandıysa true, iptal edildiyse false döner.
  static Future<bool> show(
    BuildContext context, {
    required String   title,
    required String   description,
    required IconData icon,
    Color accentColor = AppColors.red,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ConfirmDialog(
        title:       title,
        description: description,
        icon:        icon,
        accentColor: accentColor,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: BorderSide(color: accentColor.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // İkon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accentColor.withOpacity(0.1),
              border: Border.all(color: accentColor.withOpacity(0.3)),
            ),
            child: Icon(icon, color: accentColor, size: 28),
          ),
          const SizedBox(height: 14),

          // Başlık
          Text(title,
            style: TextStyle(
              color: accentColor,
              fontSize: 14,
              letterSpacing: 3,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),

          // Açıklama
          Text(description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.grey,
              fontSize: 11,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),

          // Butonlar
          Row(children: [
            Expanded(
              child: _DialogButton(
                label: 'İPTAL',
                color: AppColors.grey,
                onTap: () => Navigator.of(context).pop(false),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _DialogButton(
                label: 'ONAYLA',
                color: accentColor,
                filled: true,
                onTap: () => Navigator.of(context).pop(true),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}

class _DialogButton extends StatelessWidget {
  final String       label;
  final Color        color;
  final bool         filled;
  final VoidCallback onTap;

  const _DialogButton({
    required this.label,
    required this.color,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: filled ? color.withOpacity(0.15) : Colors.transparent,
          border: Border.all(color: color.withOpacity(0.5)),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Center(
          child: Text(label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              letterSpacing: 2,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
