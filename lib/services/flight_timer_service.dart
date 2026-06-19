import 'dart:async';

/// ARM olduğu andan DISARM olana kadar geçen süreyi sayan servis.
/// QGC'deki uçuş süresi sayacının karşılığıdır.
///
/// Dışarıdan [updateArmState] ile arm durumu bildirilir.
/// [elapsedStream] üzerinden her saniye güncel süre yayınlanır.
class FlightTimerService {
  Timer? _timer;
  DateTime? _armTime;
  bool _isArmed = false;

  final _ctrl = StreamController<Duration>.broadcast();
  Stream<Duration> get elapsedStream => _ctrl.stream;

  Duration get elapsed =>
      (_armTime != null && _isArmed) ? DateTime.now().difference(_armTime!) : Duration.zero;

  /// Telemetri'den gelen arm durumunu günceller.
  /// ARM olduğu an sayaç başlar, DISARM olduğu an durur.
  void updateArmState(bool armed) {
    if (armed && !_isArmed) {
      // Yeni ARM — sayacı başlat
      _armTime = DateTime.now();
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!_ctrl.isClosed) _ctrl.add(elapsed);
      });
    } else if (!armed && _isArmed) {
      // DISARM — sayacı durdur, son değeri yayınla
      _timer?.cancel();
      if (!_ctrl.isClosed) _ctrl.add(elapsed);
    }
    _isArmed = armed;
  }

  void dispose() {
    _timer?.cancel();
    _ctrl.close();
  }
}
