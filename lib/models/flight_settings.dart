/// Kullanıcının ayarlayabildiği uçuş parametreleri.
/// SettingsService tarafından persist edilir.
class FlightSettings {
  final double followAltitude;     // Takip irtifası (m) — varsayılan 30m
  final double followDistanceNear; // MC geçiş mesafesi (m) — varsayılan 150m
  final double followDistanceFar;  // FW yaklaşma mesafesi (m) — varsayılan 300m
  final double defaultOrbitRadius; // Orbit varsayılan yarıçap (m) — varsayılan 50m
  final double defaultTakeoffAlt;  // Kalkış varsayılan irtifa (m) — varsayılan 10m

  const FlightSettings({
    this.followAltitude     = 30.0,
    this.followDistanceNear = 150.0,
    this.followDistanceFar  = 300.0,
    this.defaultOrbitRadius = 50.0,
    this.defaultTakeoffAlt  = 10.0,
  });

  FlightSettings copyWith({
    double? followAltitude,
    double? followDistanceNear,
    double? followDistanceFar,
    double? defaultOrbitRadius,
    double? defaultTakeoffAlt,
  }) {
    return FlightSettings(
      followAltitude:     followAltitude     ?? this.followAltitude,
      followDistanceNear: followDistanceNear ?? this.followDistanceNear,
      followDistanceFar:  followDistanceFar  ?? this.followDistanceFar,
      defaultOrbitRadius: defaultOrbitRadius ?? this.defaultOrbitRadius,
      defaultTakeoffAlt:  defaultTakeoffAlt  ?? this.defaultTakeoffAlt,
    );
  }
}
