import 'package:latlong2/latlong.dart';

enum MissionCommandType {
  waypoint,
  takeoff,
  land,
  rtl,
  vtolTakeoff,
  vtolLand,
  loiterUnlim,
  loiterTime,
  roi,
  transitionToFw,
  transitionToMc
}

extension MissionCommandTypeExtension on MissionCommandType {
  int get mavCmd {
    switch (this) {
      case MissionCommandType.waypoint: return 16;
      case MissionCommandType.takeoff: return 22;
      case MissionCommandType.land: return 21;
      case MissionCommandType.rtl: return 20;
      case MissionCommandType.vtolTakeoff: return 84;
      case MissionCommandType.vtolLand: return 85;
      case MissionCommandType.loiterUnlim: return 17;
      case MissionCommandType.loiterTime: return 19;
      case MissionCommandType.roi: return 195;
      case MissionCommandType.transitionToFw: return 3000;
      case MissionCommandType.transitionToMc: return 3000;
    }
  }

  String get label {
    switch (this) {
      case MissionCommandType.waypoint: return 'Ara Nokta (Git)';
      case MissionCommandType.takeoff: return 'Kalkış (Sabit Kanat)';
      case MissionCommandType.land: return 'İniş (Sabit Kanat)';
      case MissionCommandType.rtl: return 'Eve Dönüş (RTL)';
      case MissionCommandType.vtolTakeoff: return 'VTOL Kalkış (Dikey)';
      case MissionCommandType.vtolLand: return 'VTOL İniş (Dikey)';
      case MissionCommandType.loiterUnlim: return 'Süresiz Bekleme (Daire)';
      case MissionCommandType.loiterTime: return 'Süreli Bekleme';
      case MissionCommandType.roi: return 'Kamerayı Çevir (ROI)';
      case MissionCommandType.transitionToFw: return 'Sabit Kanata Geç (FW)';
      case MissionCommandType.transitionToMc: return 'Multikoptere Geç (MC)';
    }
  }
}

class MissionWaypoint {
  LatLng position;
  double altitude;
  MissionCommandType commandType;
  double param1; // Default for delays/hold times
  double param2; // Acceptance radius / etc.
  double param3; // Pass radius
  double param4; // Yaw
  
  bool autoContinue;
  int frame; // MAV_FRAME, default to MAV_FRAME_GLOBAL_RELATIVE_ALT_INT (6)

  MissionWaypoint({
    required this.position, 
    this.altitude = 50.0,
    this.commandType = MissionCommandType.waypoint,
    this.param1 = 0.0,
    this.param2 = 0.0,
    this.param3 = 0.0,
    this.param4 = 0.0, // 0.0 or double.nan for default
    this.autoContinue = true,
    this.frame = 6, 
  });
}
