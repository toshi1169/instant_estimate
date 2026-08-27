import '../../../core/domain/app_access_plan.dart';
import '../../subscription/data/app_access_state_store.dart';
import '../../subscription/domain/app_access_state.dart';
import '../domain/rewarded_ad_policy.dart';

enum RewardedAdResult { completed, dismissed, unavailable, failed }

abstract interface class RewardedAdPresenter {
  Future<RewardedAdResult> show(RewardedAdEntryPoint entryPoint);
}

class UnavailableRewardedAdPresenter implements RewardedAdPresenter {
  const UnavailableRewardedAdPresenter();

  @override
  Future<RewardedAdResult> show(RewardedAdEntryPoint entryPoint) async {
    return RewardedAdResult.unavailable;
  }
}

class RewardedAdAccessController {
  RewardedAdAccessController({
    required AppAccessState initialState,
    this.store,
    this.presenter = const UnavailableRewardedAdPresenter(),
    DateTime Function()? now,
  }) : _state = initialState,
       _now = now ?? DateTime.now;

  final AppAccessStateStore? store;
  final RewardedAdPresenter presenter;
  final DateTime Function() _now;
  final Map<RewardedAdGroup, Future<bool>> _pending = {};
  AppAccessState _state;

  AppAccessState get state => _state;

  void updateState(AppAccessState state) {
    _state = state;
  }

  bool requiresAd(RewardedAdEntryPoint entryPoint) {
    return _requiresAd(entryPoint, _now());
  }

  Future<bool> requestAccess(RewardedAdEntryPoint entryPoint) {
    final now = _now();
    final group = entryPoint.group;
    final day = _dayKey(now);
    if (!_requiresAd(entryPoint, now)) {
      return Future.value(true);
    }

    final existing = _pending[group];
    if (existing != null) return existing;

    final request = _requestAndRecord(entryPoint, group, day);
    _pending[group] = request;
    return request.whenComplete(() => _pending.remove(group));
  }

  bool _requiresAd(RewardedAdEntryPoint entryPoint, DateTime now) {
    if (!_state.effectivePlan(now: now).showsAds) return false;
    final group = entryPoint.group;
    final day = _dayKey(now);
    return _state.rewardedAccessDay != day ||
        !_state.rewardedAccessGroups.contains(group.name);
  }

  Future<bool> _requestAndRecord(
    RewardedAdEntryPoint entryPoint,
    RewardedAdGroup group,
    String day,
  ) async {
    RewardedAdResult result;
    try {
      result = await presenter.show(entryPoint);
    } catch (_) {
      result = RewardedAdResult.failed;
    }

    if (result == RewardedAdResult.dismissed) return false;

    final groups = _state.rewardedAccessDay == day
        ? <String>{..._state.rewardedAccessGroups}
        : <String>{};
    groups.add(group.name);
    _state = _state.copyWith(
      rewardedAccessDay: day,
      rewardedAccessGroups: groups.toList(growable: false),
    );

    try {
      await store?.save(_state);
    } catch (_) {
      // 広告状態を保存できない場合も、その場の利用は妨げない。
    }
    return true;
  }
}

String _dayKey(DateTime value) {
  final year = value.year.toString().padLeft(4, '0');
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}
