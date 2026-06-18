import 'dart:async';
import 'dart:typed_data';

class VideoService {
  final _frameCtrl = StreamController<Uint8List>.broadcast();
  final _connCtrl = StreamController<bool>.broadcast();

  Stream<Uint8List> get frameStream => _frameCtrl.stream;
  Stream<bool> get connectionStream => _connCtrl.stream;

  void start() {
    // Şimdilik mock bir servis: Video yayını bağlantısını simüle eder
    _connCtrl.add(false);
  }

  void dispose() {
    _frameCtrl.close();
    _connCtrl.close();
  }
}
