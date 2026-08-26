import 'package:flutter/services.dart';

const supportedAppOrientations = <DeviceOrientation>[
  DeviceOrientation.portraitUp,
];

Future<void> configureAppOrientation() {
  return SystemChrome.setPreferredOrientations(supportedAppOrientations);
}
