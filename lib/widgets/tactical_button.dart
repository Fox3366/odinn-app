import 'package:flutter/material.dart';
import '../core/app_colors.dart';

class TacticalButton extends StatefulWidget {
  final String        label;
  final IconData      icon;
  final Color         color;
  final VoidCallback  onTap;

  const TacticalButton({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  State<TacticalButton> createState() => _TacticalButtonState();
}

class _TacticalButtonState extends State<TacticalButton> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _scale;
  bool _pressed = false;

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
    return GestureDetector(
      onTapDown:   (_) { _ctrl.forward(); setState(() => _pressed = true); },
      onTapUp:     (_) { _ctrl.reverse(); setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: ()  { _ctrl.reverse(); setState(() => _pressed = false); },
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 76,
          decoration: BoxDecoration(
            color: _pressed ? widget.color.withOpacity(0.1) : Colors.transparent,
            border: Border.all(color: _pressed ? widget.color : AppColors.greyD, width: _pressed ? 1.5 : 1),
            borderRadius: BorderRadius.circular(3),
            boxShadow: _pressed ? [BoxShadow(color: widget.color.withOpacity(0.25), blurRadius: 10)] : [],
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(widget.icon, color: widget.color, size: 24),
            const SizedBox(height: 4),
            Text(widget.label, textAlign: TextAlign.center,
                style: TextStyle(color: widget.color, fontSize: 8, letterSpacing: 1.5, fontWeight: FontWeight.w700)),
          ]),
        ),
      ),
    );
  }
}