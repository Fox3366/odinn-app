import 'package:flutter/material.dart';
import '../core/app_colors.dart';

/// Takeoff komutu için irtifa giriş dialogu.
/// Kullanıcı değer girmezse [defaultAltitude] kullanılır.
class TakeoffDialog extends StatefulWidget {
  final double defaultAltitude;

  const TakeoffDialog({super.key, this.defaultAltitude = 10.0});

  /// Dialogu gösterir. Onaylandıysa irtifa (double) döner, iptal edilirse null.
  static Future<double?> show(BuildContext context, {double defaultAltitude = 10.0}) {
    return showDialog<double>(
      context: context,
      barrierDismissible: false,
      builder: (_) => TakeoffDialog(defaultAltitude: defaultAltitude),
    );
  }

  @override
  State<TakeoffDialog> createState() => _TakeoffDialogState();
}

class _TakeoffDialogState extends State<TakeoffDialog> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.defaultAltitude.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    final value = double.tryParse(_ctrl.text.trim());
    final alt = (value != null && value > 0) ? value : widget.defaultAltitude;
    Navigator.of(context).pop(alt);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: BorderSide(color: AppColors.green.withOpacity(0.5)),
      ),
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // İkon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.green.withOpacity(0.1),
              border: Border.all(color: AppColors.green.withOpacity(0.3)),
            ),
            child: const Icon(Icons.flight_takeoff, color: AppColors.green, size: 28),
          ),
          const SizedBox(height: 14),

          // Başlık
          const Text('KALKIŞ İRTİFASI',
            style: TextStyle(
              color: AppColors.green,
              fontSize: 14,
              letterSpacing: 3,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text('Varsayılan: ${widget.defaultAltitude.toStringAsFixed(0)}m',
            style: TextStyle(color: AppColors.grey.withOpacity(0.6), fontSize: 10),
          ),
          const SizedBox(height: 16),

          // İrtifa girişi
          TextField(
            controller: _ctrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            autofocus: true,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
            decoration: InputDecoration(
              hintText: '10',
              hintStyle: TextStyle(color: AppColors.grey.withOpacity(0.3), fontSize: 24),
              suffixText: 'm',
              suffixStyle: TextStyle(color: AppColors.green.withOpacity(0.7), fontSize: 14),
              filled: true,
              fillColor: AppColors.bg,
              border: OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.greyD),
                borderRadius: BorderRadius.circular(3),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.greyD),
                borderRadius: BorderRadius.circular(3),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.green.withOpacity(0.6)),
                borderRadius: BorderRadius.circular(3),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 20),

          // Butonlar
          Row(children: [
            Expanded(
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(null),
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.grey.withOpacity(0.5)),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const Center(
                    child: Text('İPTAL',
                      style: TextStyle(color: AppColors.grey, fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: _submit,
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.green.withOpacity(0.15),
                    border: Border.all(color: AppColors.green.withOpacity(0.5)),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const Center(
                    child: Text('KALKIŞ',
                      style: TextStyle(color: AppColors.green, fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
            ),
          ]),
        ]),
        ),
      ),
    );
  }
}
