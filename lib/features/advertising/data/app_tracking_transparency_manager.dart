import 'package:flutter/services.dart';

enum TrackingAuthorizationStatus {
  notDetermined,
  restricted,
  denied,
  authorized,
}

abstract interface class TrackingAuthorizationManager {
  Future<TrackingAuthorizationStatus> status();

  Future<TrackingAuthorizationStatus> requestAuthorization();
}

class PlatformTrackingAuthorizationManager
    implements TrackingAuthorizationManager {
  const PlatformTrackingAuthorizationManager({
    this._channel = const MethodChannel(
      'com.matsumotoboundary.constructioncalc/tracking_authorization',
    ),
  });

  final MethodChannel _channel;

  @override
  Future<TrackingAuthorizationStatus> status() => _invoke('status');

  @override
  Future<TrackingAuthorizationStatus> requestAuthorization() =>
      _invoke('requestAuthorization');

  Future<TrackingAuthorizationStatus> _invoke(String method) async {
    final value = await _channel.invokeMethod<String>(method);
    return TrackingAuthorizationStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => TrackingAuthorizationStatus.restricted,
    );
  }
}
