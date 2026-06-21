import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../models/follow_state.dart';

class FollowStateBar extends StatelessWidget {
  final FollowState currentState;

  const FollowStateBar({super.key, required this.currentState});

  Color _color(FollowState s) {
    switch (s) {
      case FollowState.approaching:   return AppColors.amber;
      case FollowState.transitioning: return AppColors.cyan;
      case FollowState.following:     return AppColors.green;
      case FollowState.idle:          return AppColors.grey;
    }
  }

  Widget _step(FollowState s, String label, IconData icon) {
    final active = currentState == s;
    final color  = active ? _color(s) : AppColors.greyD;
    return Expanded(
      child: Column(children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(height: 3),
        Text(label, textAlign: TextAlign.center,
            style: TextStyle(color: color, fontSize: 7, letterSpacing: 1.5,
                fontWeight: active ? FontWeight.w700 : FontWeight.normal)),
        if (active) Container(margin: const EdgeInsets.only(top: 3), height: 2, color: color),
      ]),
    );
  }

  Widget _arrow() => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 4),
    child: Icon(Icons.arrow_forward_ios, color: Color(0xFF333333), size: 10),
  );

  @override
  Widget build(BuildContext context) {
    final borderColor = _color(currentState).withValues(alpha: 0.4);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Row(children: [
        _step(FollowState.approaching,   'YAKLAŞIYOR', Icons.flight),
        _arrow(),
        _step(FollowState.transitioning, 'GEÇİŞ',     Icons.autorenew),
        _arrow(),
        _step(FollowState.following,     'TAKİP',      Icons.person_pin_circle),
      ]),
    );
  }
}
