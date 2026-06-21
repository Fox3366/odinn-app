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
              title: Text('Duzenle (WP ${index + 1})'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<MissionCommandType>(
                      initialValue: currentCmd,
                      decoration: const InputDecoration(labelText: 'Gorev Tipi'),
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
                      decoration: const InputDecoration(labelText: 'Yukseklik (metre)'),
                    ),
                    if (currentCmd == MissionCommandType.loiterTime || currentCmd == MissionCommandType.waypoint) ...[
                      const SizedBox(height: 10),
                      TextField(
                        controller: paramCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: currentCmd == MissionCommandType.waypoint ? 'Bekleme Suresi (sn)' : 'Loiter Suresi (sn)',
                        ),
                      ),
                    ]
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('IPTAL'),
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
      height: 140,
      color: Colors.black87,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text('Gorev Noktalari', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: onClearAll,
                    icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
                    label: const Text('Temizle', style: TextStyle(color: Colors.redAccent)),
                  ),
                  ElevatedButton.icon(
                    onPressed: onUpload,
                    icon: const Icon(Icons.upload),
                    label: const Text('GOREV YUKLE'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              )
            ],
          ),
          Expanded(
            child: waypoints.isEmpty
                ? const Center(child: Text('Haritaya dokunarak guzergah olusturun.', style: TextStyle(color: Colors.white54)))
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: waypoints.length,
                    itemBuilder: (context, index) {
                      final wp = waypoints[index];
                      return Card(
                        color: Colors.blueGrey[800],
                        margin: const EdgeInsets.all(8.0),
                        child: Container(
                          width: 120,
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('WP ${index + 1}', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 2),
                              Text(wp.commandType.label, style: const TextStyle(color: Colors.orangeAccent, fontSize: 10), overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 2),
                              Text('${wp.altitude} m', style: const TextStyle(color: Colors.white)),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  InkWell(
                                    onTap: () => _showEditDialog(context, index),
                                    child: const Icon(Icons.edit, color: Colors.amber, size: 20),
                                  ),
                                  InkWell(
                                    onTap: () => onDelete(index),
                                    child: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
