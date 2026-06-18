import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';

/// Yalnızca UDP soket yaşam döngüsünü yönetir.
/// Veri parse işlemi bu sınıfın dışındadır.
class UdpSocketService {
  RawDatagramSocket? _socket;
  final int port;

  UdpSocketService({required this.port});

  /// Soketi açar ve gelen datagramları [onData] callback'ine iletir.
  Future<void> bind(void Function(Datagram) onData) async {
    try {
      _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, port);
      _socket!.listen((event) {
        if (event == RawSocketEvent.read) {
          final dg = _socket?.receive();
          if (dg != null) onData(dg);
        }
      });
      debugPrint('✅ UDP soket açıldı (port $port)');
    } catch (e) {
      debugPrint('❌ UDP soket hatası (port $port): $e');
    }
  }

  /// Veri gönderir. Soket kapalıysa sessizce geçer.
  bool send(List<int> data, String host, int destPort) {
    if (_socket == null) return false;
    try {
      _socket!.send(data, InternetAddress(host), destPort);
      return true;
    } catch (e) {
      debugPrint('❌ UDP gönderim hatası: $e');
      return false;
    }
  }

  void close() {
    _socket?.close();
    _socket = null;
  }
}