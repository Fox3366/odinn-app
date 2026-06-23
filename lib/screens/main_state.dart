import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';

import '../models/drone_telemetry.dart';
import '../models/flight_settings.dart';
import '../models/follow_state.dart';

class SnackBarMessage extends Equatable {
  final String text;
  final IconData icon;
  final Color color;
  final int timestamp; 

  const SnackBarMessage({
    required this.text,
    required this.icon,
    required this.color,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [text, icon, color, timestamp];
}

class MainState extends Equatable {
  final double lat;
  final double lon;
  final double alt;
  final bool isConnected;
  final bool followActive;
  final bool videoConnected;
  final bool mapFullscreen;
  final FollowState followState;
  final Uint8List? currentFrame;
  final DroneTelemetry droneTelemetry;
  final FlightSettings flightSettings;
  final Duration flightTime;
  final bool isCommandPending;
  final String ip;
  final int port;
  final SnackBarMessage? snackBarMessage;

  const MainState({
    this.lat = 0.0,
    this.lon = 0.0,
    this.alt = 0.0,
    this.isConnected = false,
    this.followActive = false,
    this.videoConnected = false,
    this.mapFullscreen = false,
    this.followState = FollowState.idle,
    this.currentFrame,
    this.droneTelemetry = const DroneTelemetry(),
    this.flightSettings = const FlightSettings(),
    this.flightTime = Duration.zero,
    this.isCommandPending = false,
    this.ip = '',
    this.port = 14540,
    this.snackBarMessage,
  });

  MainState copyWith({
    double? lat,
    double? lon,
    double? alt,
    bool? isConnected,
    bool? followActive,
    bool? videoConnected,
    bool? mapFullscreen,
    FollowState? followState,
    Uint8List? currentFrame,
    DroneTelemetry? droneTelemetry,
    FlightSettings? flightSettings,
    Duration? flightTime,
    bool? isCommandPending,
    String? ip,
    int? port,
    SnackBarMessage? snackBarMessage,
  }) {
    return MainState(
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      alt: alt ?? this.alt,
      isConnected: isConnected ?? this.isConnected,
      followActive: followActive ?? this.followActive,
      videoConnected: videoConnected ?? this.videoConnected,
      mapFullscreen: mapFullscreen ?? this.mapFullscreen,
      followState: followState ?? this.followState,
      currentFrame: currentFrame ?? this.currentFrame,
      droneTelemetry: droneTelemetry ?? this.droneTelemetry,
      flightSettings: flightSettings ?? this.flightSettings,
      flightTime: flightTime ?? this.flightTime,
      isCommandPending: isCommandPending ?? this.isCommandPending,
      ip: ip ?? this.ip,
      port: port ?? this.port,
      snackBarMessage: snackBarMessage,
    );
  }

  @override
  List<Object?> get props => [
        lat,
        lon,
        alt,
        isConnected,
        followActive,
        videoConnected,
        mapFullscreen,
        followState,
        currentFrame,
        droneTelemetry,
        flightSettings,
        flightTime,
        isCommandPending,
        ip,
        port,
        snackBarMessage,
      ];
}
