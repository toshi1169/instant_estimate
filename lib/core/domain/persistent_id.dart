import 'dart:math';

/// Generates a random RFC 4122 version 4 ID without depending on the clock.
abstract final class PersistentId {
  static String create({Iterable<String> excluding = const []}) {
    final reserved = excluding.toSet();
    final random = Random.secure();
    while (true) {
      final bytes = List<int>.generate(16, (_) => random.nextInt(256));
      bytes[6] = (bytes[6] & 0x0f) | 0x40;
      bytes[8] = (bytes[8] & 0x3f) | 0x80;
      final hex = bytes
          .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
          .join();
      final id =
          '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
          '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
      if (!reserved.contains(id)) return id;
    }
  }
}
