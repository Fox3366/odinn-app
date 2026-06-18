/// Drone'dan gelen telemetri verilerini tutan değişmez veri sınıfı.
/// TelemetryService tarafından üretilir, UI katmanı tarafından okunur.
class DroneTelemetry {
  final double batteryVoltage;   // Volt
  final int    batteryPercent;   // 0-100 (-1 = bilinmiyor)
  final double groundSpeed;     // m/s
  final double altitude;        // metre (MSL)
  final double relativeAlt;     // metre (AGL — kalkış noktasına göre)
  final double distanceToGcs;   // metre (GCS-drone arası)
  final int    satelliteCount;  // GPS uydu sayısı
  final int    gpsFixType;      // 0=No, 2=2D, 3=3D, 4=DGPS, 5=RTK
  final String flightMode;      // İnsan-okunur uçuş modu
  final double heading;         // derece (0-360)
  final bool   isArmed;         // Motor silah durumu

  const DroneTelemetry({
    this.batteryVoltage = 0.0,
    this.batteryPercent = -1,
    this.groundSpeed    = 0.0,
    this.altitude       = 0.0,
    this.relativeAlt    = 0.0,
    this.distanceToGcs  = 0.0,
    this.satelliteCount = 0,
    this.gpsFixType     = 0,
    this.flightMode     = 'BİLİNMİYOR',
    this.heading        = 0.0,
    this.isArmed        = false,
  });

  /// Sadece değişen alanlarla yeni kopya oluşturur.
  DroneTelemetry copyWith({
    double? batteryVoltage,
    int?    batteryPercent,
    double? groundSpeed,
    double? altitude,
    double? relativeAlt,
    double? distanceToGcs,
    int?    satelliteCount,
    int?    gpsFixType,
    String? flightMode,
    double? heading,
    bool?   isArmed,
  }) {
    return DroneTelemetry(
      batteryVoltage: batteryVoltage ?? this.batteryVoltage,
      batteryPercent: batteryPercent ?? this.batteryPercent,
      groundSpeed:    groundSpeed    ?? this.groundSpeed,
      altitude:       altitude       ?? this.altitude,
      relativeAlt:    relativeAlt    ?? this.relativeAlt,
      distanceToGcs:  distanceToGcs  ?? this.distanceToGcs,
      satelliteCount: satelliteCount ?? this.satelliteCount,
      gpsFixType:     gpsFixType     ?? this.gpsFixType,
      flightMode:     flightMode     ?? this.flightMode,
      heading:        heading        ?? this.heading,
      isArmed:        isArmed        ?? this.isArmed,
    );
  }

  /// GPS fix kalitesini insan-okunur metin olarak döndürür.
  String get gpsFixLabel {
    switch (gpsFixType) {
      case 0:  return 'YOK';
      case 1:  return 'YOK';
      case 2:  return '2D';
      case 3:  return '3D';
      case 4:  return 'DGPS';
      case 5:  return 'RTK Float';
      case 6:  return 'RTK Fix';
      default: return '?';
    }
  }
}
