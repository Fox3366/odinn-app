import 'package:flutter/material.dart';
import '../core/app_colors.dart';

class FollowMeButton extends StatefulWidget {
  final bool          active;
  final VoidCallback  onTap;

  const FollowMeButton({super.key, required this.active, required this.onTap});

  @override
  State<FollowMeButton> createState() => _FollowMeButtonState();
}

class _FollowMeButtonState extends State<FollowMeButton> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _scale;

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1.0, end: 0.94).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final c = widget.active ? AppColors.red : AppColors.greyD;
    return GestureDetector(
      onTapDown:  (_) => _ctrl.forward(),
      onTapUp:    (_) { _ctrl.reverse(); widget.onTap(); },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 76,
          decoration: BoxDecoration(
            color: widget.active ? AppColors.red.withValues(alpha: 0.12) : Colors.transparent,
            border: Border.all(color: c, width: widget.active ? 1.5 : 1),
            borderRadius: BorderRadius.circular(3),
            boxShadow: widget.active ? [BoxShadow(color: AppColors.red.withValues(alpha: 0.2), blurRadius: 12)] : [],
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(widget.active ? Icons.person_pin_circle : Icons.person_pin_circle_outlined,
                color: widget.active ? AppColors.red : AppColors.grey, size: 24),
            const SizedBox(height: 4),
            Text('FOLLOW ME', style: TextStyle(
              color: widget.active ? AppColors.red : AppColors.grey,
              fontSize: 8, letterSpacing: 1.5, fontWeight: FontWeight.w700,
            )),
            const SizedBox(height: 3),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: (widget.active ? AppColors.red : AppColors.grey).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Text(widget.active ? '● AKTİF' : '○ PASİF',
                  style: TextStyle(
                    color: widget.active ? AppColors.red : AppColors.grey,
                    fontSize: 7, letterSpacing: 1,
                  )),
            ),
          ]),
        ),
      ),
    );
  }
}
