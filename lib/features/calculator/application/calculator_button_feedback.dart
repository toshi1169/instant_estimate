import 'package:flutter/services.dart';

abstract interface class CalculatorButtonFeedback {
  Future<void> playTapSound();

  Future<void> performLightHaptic();
}

class SystemCalculatorButtonFeedback implements CalculatorButtonFeedback {
  const SystemCalculatorButtonFeedback();

  @override
  Future<void> playTapSound() async {
    try {
      await SystemSound.play(SystemSoundType.click);
    } catch (_) {
      // 端末側でシステム音を利用できなくても電卓操作は続行する。
    }
  }

  @override
  Future<void> performLightHaptic() async {
    try {
      await HapticFeedback.selectionClick();
    } catch (_) {
      // Haptic非対応端末やSimulatorでも電卓操作は続行する。
    }
  }
}
