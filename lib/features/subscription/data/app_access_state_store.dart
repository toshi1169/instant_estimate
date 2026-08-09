import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/app_access_state.dart';

abstract interface class AppAccessStateStore {
  Future<AppAccessState> load();
  Future<void> save(AppAccessState state);
}

class PlatformAppAccessStateStore implements AppAccessStateStore {
  static const _channel = MethodChannel('jp.instant_estimate/app_access');

  @override
  Future<AppAccessState> load() async {
    final encoded = await _channel.invokeMethod<String>('loadAccessState');
    if (encoded == null || encoded.isEmpty) return const AppAccessState();

    try {
      final decoded = jsonDecode(encoded);
      if (decoded is Map<String, dynamic>) {
        return AppAccessState.fromJson(decoded);
      }
    } on FormatException {
      // 壊れた保存値は無料版へ安全に戻す。
    } on TypeError {
      // 旧形式など型が異なる保存値は無料版へ安全に戻す。
    }
    return const AppAccessState();
  }

  @override
  Future<void> save(AppAccessState state) {
    return _channel.invokeMethod<void>('saveAccessState', <String, Object>{
      'accessState': jsonEncode(state.toJson()),
    });
  }
}
