import 'package:flutter/material.dart';
import '../models/mission_waypoint.dart';

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
              title: Text('Item #${index + 1} Düzenle'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<MissionCommandType>(
                      isExpanded: true,
                      initialValue: currentCmd,
                      decoration: const InputDecoration(labelText: 'Görev Komutu'),
                      items: MissionCommandType.values.map((cmd) {
                        return DropdownMenuItem(
                          value: cmd,
                          child: Text(cmd.label, style: const TextStyle(fontSize: 14)),
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
                      decoration: const InputDecoration(labelText: 'İrtifa (m)'),
                    ),
                    if (currentCmd == MissionCommandType.loiterTime || currentCmd == MissionCommandType.waypoint || currentCmd == MissionCommandType.vtolTakeoff) ...[
                      const SizedBox(height: 10),
                      TextField(
                        controller: paramCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: currentCmd == MissionCommandType.vtolTakeoff ? 'Kalkış Sonrası Bekleme' : 'Bekleme Süresi (saniye)',
                        ),
                      ),
                    ]
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('İptal'),
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
                  child: const Text('Kaydet'),
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
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.all(8),
      child: Column(
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.blueGrey[900],
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Mission Items', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                Text('${waypoints.length} items', style: const TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
          ),
          
          // List Section
          Expanded(
            child: waypoints.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('Haritadan görev ekleyin veya sol menüden komut seçin.', 
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
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        margin: const EdgeInsets.only(bottom: 6.0),
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
                                    child: Text(wp.commandType.label, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                                  ),
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: const Icon(Icons.delete, color: Colors.white54, size: 20),
                                    onPressed: () => onDelete(index),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text('İrtifa: ${wp.altitude}m | Param: ${wp.param1}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                  ),
                                  InkWell(
                                    onTap: () => _showEditDialog(context, index),
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                      child: Text('Düzenle', style: TextStyle(color: Colors.blueAccent, fontSize: 13, fontWeight: FontWeight.w600)),
                                    ),
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
            decoration: BoxDecoration(
              color: Colors.blueGrey[900],
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(8), bottomRight: Radius.circular(8)),
            ),
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
