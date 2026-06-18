import 'package:flutter/material.dart';
import '../core/app_colors.dart';

/// Splash ekranındaki yükleme çubuğu widget'ı.
class LoadingBar extends StatefulWidget {
  const LoadingBar({super.key});

  @override
  State<LoadingBar> createState() => _LoadingBarState();
}

class _LoadingBarState extends State<LoadingBar> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _fill;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..forward();
    _fill = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fill,
      builder: (_, __) => SizedBox(
        width: 190,
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('INITIALIZING', style: TextStyle(color: AppColors.grey, fontSize: 9, letterSpacing: 2)),
            Text('${(_fill.value * 100).toInt()}%', style: const TextStyle(color: AppColors.red, fontSize: 9, letterSpacing: 1)),
          ]),
          const SizedBox(height: 6),
          Stack(children: [
            Container(height: 2, color: AppColors.grey.withOpacity(0.2)),
            FractionallySizedBox(
              widthFactor: _fill.value,
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                  color: AppColors.red,
                  boxShadow: [BoxShadow(color: AppColors.red.withOpacity(0.6), blurRadius: 6)],
                ),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}