import 'package:flutter/material.dart';

class MissionToolbar extends StatelessWidget {
  final VoidCallback onAddTakeoff;
  final VoidCallback onAddWaypoint;
  final VoidCallback onAddLand;
  final VoidCallback onAddRtl;
  final VoidCallback onAddVtolTakeoff;
  final VoidCallback onAddVtolLand;
  final VoidCallback onAddTransitionFw;
  final VoidCallback onAddTransitionMc;

  const MissionToolbar({
    super.key,
    required this.onAddTakeoff,
    required this.onAddWaypoint,
    required this.onAddLand,
    required this.onAddRtl,
    required this.onAddVtolTakeoff,
    required this.onAddVtolLand,
    required this.onAddTransitionFw,
    required this.onAddTransitionMc,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blueGrey[900]?.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToolButton(Icons.flight_takeoff, 'Kalkış', onAddTakeoff),
          _buildToolButton(Icons.arrow_upward, 'VTOL Kalkış', onAddVtolTakeoff),
          const Divider(color: Colors.white24),
          _buildToolButton(Icons.add_location_alt, 'Ara Nokta', onAddWaypoint),
          _buildToolButton(Icons.swap_horiz, 'Sabit Kanat Geçiş', onAddTransitionFw),
          _buildToolButton(Icons.swap_vert, 'Multikopter Geçiş', onAddTransitionMc),
          const Divider(color: Colors.white24),
          _buildToolButton(Icons.flight_land, 'İniş', onAddLand),
          _buildToolButton(Icons.arrow_downward, 'VTOL İniş', onAddVtolLand),
          _buildToolButton(Icons.home, 'RTL', onAddRtl),
        ],
      ),
    );
  }

  Widget _buildToolButton(IconData icon, String tooltip, VoidCallback onPressed) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onPressed,
      ),
    );
  }
}
