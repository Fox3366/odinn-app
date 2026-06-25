import 'package:flutter/material.dart';
import '../services/mission_service.dart';

class MissionListPanel extends StatelessWidget {
  final List<MissionWaypoint> waypoints;
  final Function(int, MissionCommandType, double, double) onEdit;
  final Function(int) onDelete;
  final VoidCallback onClearAll;
  final VoidCallback onUpload;

  const MissionListPanel({
    super.key,
    required this.waypoints,
    required this.onEdit,
    required this.onDelete,
    required this.onClearAll,
    required this.onUpload,
  });

  void _showEditDialog(BuildContext context, int index) {
    final wp = waypoints[index];
    double currentAlt = wp.altitude;
    MissionCommandType currentCmd = wp.commandType;
    double currentParam1 = wp.param1;

    TextEditingController altCtrl = TextEditingController(text: currentAlt.toString());
    TextEditingController paramCtrl = TextEditingController(text: currentParam1.toString());

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Noktayı Düzenle (WP ${index + 1})'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<MissionCommandType>(
                      initialValue: currentCmd,
                      decoration: const InputDecoration(labelText: 'Görev Tipi (Ne Yapılacak?)'),
                      items: MissionCommandType.values.map((cmd) {
                        return DropdownMenuItem(
                          value: cmd,
                          child: Text(cmd.label),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => currentCmd = val);
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: altCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'İrtifa / Yükseklik (metre)'),
                    ),
                    if (currentCmd == MissionCommandType.loiterTime || currentCmd == MissionCommandType.waypoint) ...[
                      const SizedBox(height: 10),
                      TextField(
                        controller: paramCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: currentCmd == MissionCommandType.waypoint ? 'Noktada Bekleme Süresi (saniye)' : 'Havada Tur Atma Süresi (saniye)',
                        ),
                      ),
                    ]
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('İPTAL'),
                ),
                ElevatedButton(
                  onPressed: () {
                    double? newAlt = double.tryParse(altCtrl.text);
                    double? newParam = double.tryParse(paramCtrl.text);
                    if (newAlt != null) {
                      onEdit(index, currentCmd, newAlt, newParam ?? 0.0);
                    }
                    Navigator.pop(ctx);
                  },
                  child: const Text('KAYDET'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black87,
      child: Column(
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.all(12.0),
            color: Colors.blueGrey[900],
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.route, color: Colors.white),
                SizedBox(width: 8),
                Text('Görev Noktaları', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),
          
          // List Section
          Expanded(
            child: waypoints.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('Haritaya dokunarak güzergah oluşturun.', 
                        style: TextStyle(color: Colors.white54), 
                        textAlign: TextAlign.center
                      ),
                    )
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                    itemCount: waypoints.length,
                    itemBuilder: (context, index) {
                      final wp = waypoints[index];
                      return Card(
                        color: Colors.blueGrey[800],
                        margin: const EdgeInsets.only(bottom: 8.0),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundColor: Colors.green,
                                    child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(wp.commandType.label, style: const TextStyle(color: Colors.orangeAccent, fontSize: 13, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text('İrtifa: ${wp.altitude} m\nParam: ${wp.param1}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        icon: const Icon(Icons.edit, color: Colors.amber, size: 20),
                                        onPressed: () => _showEditDialog(context, index),
                                      ),
                                      const SizedBox(width: 12),
                                      IconButton(
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                                        onPressed: () => onDelete(index),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Actions Section
          Container(
            padding: const EdgeInsets.all(12.0),
            color: Colors.blueGrey[900],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(
                  onPressed: waypoints.isEmpty ? null : onUpload,
                  icon: const Icon(Icons.upload),
                  label: const Text('GÖREV YÜKLE'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: waypoints.isEmpty ? null : onClearAll,
                  icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
                  label: const Text('Tümünü Temizle', style: TextStyle(color: Colors.redAccent)),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
