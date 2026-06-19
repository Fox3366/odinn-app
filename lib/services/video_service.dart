import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

class VideoService {
  final _frameCtrl = StreamController<Uint8List>.broadcast();
  final _connCtrl = StreamController<bool>.broadcast();

  Stream<Uint8List> get frameStream => _frameCtrl.stream;
  Stream<bool> get connectionStream => _connCtrl.stream;

  RawDatagramSocket? _socket;
  Timer? _timeoutTimer;
  Timer? _pingTimer;
  String? _targetIp;

  // Frame montajı için
  int _currentFrameId = -1;
  final Map<int, Uint8List> _chunks = {};
  int _expectedChunks = 0;

  void setTarget(String ip) {
    _targetIp = ip;
  }

  Future<void> start() async {
    try {
      _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 5600);
      _socket!.listen((event) {
        if (event == RawSocketEvent.read) {
          final dg = _socket?.receive();
          if (dg != null) _processDatagram(dg.data);
        }
      });
      
      // Otonom (Zero-Config) Keşif için Ping
      _pingTimer = Timer.periodic(const Duration(seconds: 2), (_) {
        if (_targetIp != null && _targetIp!.isNotEmpty && _socket != null) {
          try {
            _socket!.send([1], InternetAddress(_targetIp!), 5600);
          } catch (_) {}
        }
      });
      
      debugPrint('✅ Video servisi başlatıldı (Port: 5600)');
    } catch (e) {
      debugPrint('❌ Video soket hatası: $e');
    }
  }

  void _processDatagram(Uint8List data) {
    if (data.length < 8) return;

    final bd = ByteData.view(data.buffer, data.offsetInBytes, data.length);
    final frameId = bd.getUint32(0, Endian.big);
    final chunkIdx = bd.getUint16(4, Endian.big);
    final totalChunks = bd.getUint16(6, Endian.big);

    final chunkData = data.sublist(8);

    // Yeni frame geldiyse eski parçaları temizle
    if (frameId != _currentFrameId) {
      _currentFrameId = frameId;
      _chunks.clear();
      _expectedChunks = totalChunks;
    }

    _chunks[chunkIdx] = chunkData;

    _updateConnection();

    // Tüm parçalar geldiyse resmi birleştir
    if (_chunks.length == _expectedChunks && _expectedChunks > 0) {
      _assembleFrame();
    }
  }

  void _assembleFrame() {
    int totalLen = 0;
    for (int i = 0; i < _expectedChunks; i++) {
      if (!_chunks.containsKey(i)) return; // Eksik parça varsa iptal
      totalLen += _chunks[i]!.length;
    }

    final frameData = Uint8List(totalLen);
    int offset = 0;
    for (int i = 0; i < _expectedChunks; i++) {
      final c = _chunks[i]!;
      frameData.setAll(offset, c);
      offset += c.length;
    }

    _frameCtrl.add(frameData);
    _chunks.clear();
  }

  void _updateConnection() {
    _connCtrl.add(true);
    _timeoutTimer?.cancel();
    // 3 saniye veri gelmezse bağlantı koptu say
    _timeoutTimer = Timer(const Duration(seconds: 3), () {
      if (!_connCtrl.isClosed) _connCtrl.add(false);
    });
  }

  void dispose() {
    _pingTimer?.cancel();
    _timeoutTimer?.cancel();
    _socket?.close();
    _frameCtrl.close();
    _connCtrl.close();
  }
}
