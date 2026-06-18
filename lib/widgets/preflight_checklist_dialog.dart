import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../models/drone_telemetry.dart';

class PreflightChecklistDialog extends StatelessWidget {
  final DroneTelemetry telemetry;
  final bool isConnected;

  const PreflightChecklistDialog({
    super.key,
    required this.telemetry,
    required this.isConnected,
  });

  static Future<bool> show(BuildContext context, {
    required DroneTelemetry telemetry,
    required bool isConnected,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PreflightChecklistDialog(
        telemetry: telemetry,
        isConnected: isConnected,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final bool gpsOk = telemetry.satelliteCount >= 4;
    final bool batteryOk = telemetry.batteryPercent >= 20;
    final bool allOk = isConnected && gpsOk && batteryOk;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: allOk ? AppColors.green : AppColors.amber),
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.fact_check_outlined, color: allOk ? AppColors.green : AppColors.amber, size: 36),
            const SizedBox(height: 16),
            const Text(
              'UÇUŞ ÖNCESİ KONTROL',
              style: TextStyle(color: AppColors.white, fontSize: 14, letterSpacing: 2, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildCheckItem('Bağlantı', isConnected ? 'AKTİF' : 'YOK', isConnected),
            const SizedBox(height: 10),
            _buildCheckItem('GPS Uydu', '${telemetry.satelliteCount} (Min 4)', gpsOk),
            const SizedBox(height: 10),
            _buildCheckItem('Batarya', '${telemetry.batteryPercent}% (Min %20)', batteryOk),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.grey,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(3),
                        side: const BorderSide(color: AppColors.greyD),
                      ),
                    ),
                    child: const Text('İPTAL', style: TextStyle(letterSpacing: 2, fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: TextButton.styleFrom(
                      backgroundColor: allOk ? AppColors.green.withOpacity(0.2) : AppColors.red.withOpacity(0.2),
                      foregroundColor: allOk ? AppColors.green : AppColors.red,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(3),
                        side: BorderSide(color: allOk ? AppColors.green : AppColors.red),
                      ),
                    ),
                    child: Text(
                      allOk ? 'ONAYLA VE DEVAM ET' : 'YİNE DE BAŞLAT',
                      style: const TextStyle(letterSpacing: 1.5, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckItem(String label, String value, bool isOk) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.bg,
        border: Border.all(color: isOk ? AppColors.green.withOpacity(0.3) : AppColors.red.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Row(
        children: [
          Icon(
            isOk ? Icons.check_circle : Icons.error,
            color: isOk ? AppColors.green : AppColors.red,
            size: 16,
          ),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(color: AppColors.grey, fontSize: 12)),
          const Spacer(),
          Text(value, style: TextStyle(color: isOk ? AppColors.green : AppColors.red, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
