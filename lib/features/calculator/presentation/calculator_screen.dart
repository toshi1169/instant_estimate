import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/domain/app_access_plan.dart';
import '../../../core/domain/angle_unit.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../advertising/domain/rewarded_ad_policy.dart';
import '../../advertising/presentation/google_mobile_ads_banner.dart';
import '../application/calculator_button_feedback.dart';
import '../application/calculator_controller.dart';
import '../data/calculation_history_store.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../settings/domain/app_settings.dart';
import '../../onboarding/data/onboarding_preferences.dart';
import '../../estimate/domain/estimate_item_draft.dart';
import '../../estimate/presentation/estimate_item_editor_screen.dart';
import '../../estimate/application/estimate_controller.dart';
import '../../estimate/data/estimate_item_store.dart';
import '../../estimate/presentation/estimate_items_screen.dart';
import '../../estimate/presentation/estimate_documents_screen.dart';
import '../../estimate/presentation/unit_price_master_screen.dart';
import '../../productivity/application/productivity_controller.dart';
import '../../productivity/data/productivity_record_store.dart';
import '../../productivity/presentation/productivity_master_screen.dart';
import '../../estimate/presentation/duplicate_estimate_item_dialog.dart';
import '../../estimate/presentation/merge_estimate_quantity_dialog.dart';
import 'calculator_history_screen.dart';
import 'calculator_side_menu.dart';
import '../../construction_calculations/presentation/construction_calculations_screen.dart';
import '../../help/presentation/help_screen.dart';
import '../../unit_conversion/presentation/unit_conversion_screen.dart';
import '../../subscription/presentation/access_plan_screen.dart';
import '../../subscription/domain/purchase_store.dart';
import '../../backup/application/backup_snapshot_factory.dart';
import '../../backup/application/backup_restore_coordinator.dart';
import 'function_list_dialog.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({
    this.controller,
    this.historyStore,
    this.settings = const AppSettings(),
    this.onSettingsChanged,
    this.estimateItemStore,
    this.estimateController,
    this.productivityRecordStore,
    this.productivityController,
    this.accessPlan = AppAccessPlan.free,
    this.onRequestRewardedAdAccess,
    this.isRewardedAdRequired,
    this.onShowAdvertisingPrivacyOptions,
    this.enableGoogleMobileAds = false,
    this.purchaseStore,
    this.onboardingPreferences,
    this.backupRestoreCoordinator,
    this.buttonFeedback = const SystemCalculatorButtonFeedback(),
    super.key,
  });

  final CalculatorController? controller;
  final CalculationHistoryStore? historyStore;
  final AppSettings settings;
  final ValueChanged<AppSettings>? onSettingsChanged;
  final EstimateItemStore? estimateItemStore;
  final EstimateController? estimateController;
  final ProductivityRecordStore? productivityRecordStore;
  final ProductivityController? productivityController;
  final AppAccessPlan accessPlan;
  final Future<bool> Function(RewardedAdEntryPoint)? onRequestRewardedAdAccess;
  final bool Function(RewardedAdEntryPoint)? isRewardedAdRequired;
  final Future<void> Function()? onShowAdvertisingPrivacyOptions;
  final bool enableGoogleMobileAds;
  final PurchaseStore? purchaseStore;
  final OnboardingPreferences? onboardingPreferences;
  final BackupRestoreCoordinator? backupRestoreCoordinator;
  final CalculatorButtonFeedback buttonFeedback;

  static const _keys = <_CalculatorKey>[
    _CalculatorKey.menu(),
    _CalculatorKey.text('^'),
    _CalculatorKey.settings(),
    _CalculatorKey.operator('←'),
    _CalculatorKey.fraction(),
    _CalculatorKey.text('()'),
    _CalculatorKey.text('%'),
    _CalculatorKey.operator('÷'),
    _CalculatorKey.text('7'),
    _CalculatorKey.text('8'),
    _CalculatorKey.text('9'),
    _CalculatorKey.operator('×'),
    _CalculatorKey.text('4'),
    _CalculatorKey.text('5'),
    _CalculatorKey.text('6'),
    _CalculatorKey.operator('−'),
    _CalculatorKey.text('1'),
    _CalculatorKey.text('2'),
    _CalculatorKey.text('3'),
    _CalculatorKey.operator('+'),
    _CalculatorKey.text('0'),
    _CalculatorKey.text('00'),
    _CalculatorKey.text('.'),
    _CalculatorKey.fractionToggle('='),
  ];

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  Timer? _digitLimitVisibilityTimer;
  Timer? _digitLimitCooldownTimer;
  bool _digitLimitNoticeVisible = false;
  bool _digitLimitNoticeCoolingDown = false;
  late final CalculatorController _controller =
      widget.controller ??
      CalculatorController(historyStore: widget.historyStore);
  late final bool _ownsController = widget.controller == null;
  late final EstimateController _estimateController =
      widget.estimateController ??
      EstimateController(
        store: widget.estimateItemStore,
        accessPlan: widget.accessPlan,
      );
  late final bool _ownsEstimateController = widget.estimateController == null;
  late final ProductivityController _productivityController =
      widget.productivityController ??
      ProductivityController(
        store: widget.productivityRecordStore,
        accessPlan: widget.accessPlan,
      );
  late final bool _ownsProductivityController =
      widget.productivityController == null;

  @override
  void initState() {
    super.initState();
    _applyDisplaySettings();
    unawaited(_controller.loadHistory());
    unawaited(_loadEstimateItems());
    unawaited(_loadProductivityRecords());
  }

  @override
  void didUpdateWidget(CalculatorScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings != widget.settings) _applyDisplaySettings();
    if (oldWidget.accessPlan != widget.accessPlan) {
      final accessPlan = widget.accessPlan;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || widget.accessPlan != accessPlan) return;
        _estimateController.updateAccessPlan(accessPlan);
        _productivityController.updateAccessPlan(accessPlan);
      });
    }
  }

  void _applyDisplaySettings() {
    _controller.updateDisplaySettings(
      decimalPlaces: widget.settings.decimalPlaces,
      roundingMode: widget.settings.roundingMode,
      angleUnit: widget.settings.angleUnit,
    );
  }

  @override
  void dispose() {
    _digitLimitVisibilityTimer?.cancel();
    _digitLimitCooldownTimer?.cancel();
    if (_ownsController) _controller.dispose();
    if (_ownsEstimateController) _estimateController.dispose();
    if (_ownsProductivityController) _productivityController.dispose();
    super.dispose();
  }

  Future<void> _loadEstimateItems() async {
    try {
      await _estimateController.load();
    } catch (_) {
      if (mounted) _showMessage('見積明細を読み込めませんでした');
    }
  }

  Future<void> _loadProductivityRecords() async {
    try {
      await _productivityController.load();
    } catch (_) {
      if (mounted) _showMessage('歩掛・生産性実績を読み込めませんでした');
    }
  }

  void _pressKey(_CalculatorKey key) {
    if (key.kind == _KeyKind.menu) {
      _scaffoldKey.currentState?.openDrawer();
      return;
    }
    if (key.kind == _KeyKind.settings) {
      unawaited(_openSettings());
      return;
    }
    unawaited(_provideButtonFeedback());
    final notice = _controller.press(key.label);
    if (notice == CalculatorController.digitLimitNotice) {
      _showDigitLimitNotice();
    } else if (notice != null) {
      _showMessage(notice);
    }
  }

  void _showDigitLimitNotice() {
    if (!mounted || _digitLimitNoticeVisible || _digitLimitNoticeCoolingDown) {
      return;
    }
    setState(() => _digitLimitNoticeVisible = true);
    _digitLimitVisibilityTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _digitLimitNoticeVisible = false;
        _digitLimitNoticeCoolingDown = true;
      });
      _digitLimitCooldownTimer = Timer(const Duration(seconds: 10), () {
        if (!mounted) return;
        setState(() => _digitLimitNoticeCoolingDown = false);
      });
    });
  }

  Future<void> _provideButtonFeedback() async {
    final feedback = widget.buttonFeedback;
    final futures = <Future<void>>[];
    if (widget.settings.calculatorTapSoundEnabled) {
      futures.add(feedback.playTapSound());
    }
    if (widget.settings.calculatorHapticsEnabled) {
      futures.add(feedback.performLightHaptic());
    }
    if (futures.isNotEmpty) await Future.wait(futures);
  }

  Future<void> _openSettings() {
    final historyStore = widget.historyStore;
    final estimateStore = widget.estimateItemStore;
    final productivityStore = widget.productivityRecordStore;
    final onboardingPreferences = widget.onboardingPreferences;
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SettingsScreen(
          settings: widget.settings,
          accessPlan: widget.accessPlan,
          onSettingsChanged: widget.onSettingsChanged ?? (_) {},
          onClearHistory: _controller.clearHistory,
          onShowAdvertisingPrivacyOptions:
              widget.onShowAdvertisingPrivacyOptions,
          onboardingPreferences: widget.onboardingPreferences,
          backupSnapshotFactory:
              historyStore != null &&
                  estimateStore != null &&
                  productivityStore != null &&
                  onboardingPreferences != null
              ? BackupSnapshotFactory(
                  historyStore: historyStore,
                  estimateStore: estimateStore,
                  productivityStore: productivityStore,
                  onboardingPreferences: onboardingPreferences,
                )
              : null,
          backupRestoreCoordinator: widget.backupRestoreCoordinator,
          onBackupRestored: (_) => _reloadRestoredData(),
        ),
      ),
    );
  }

  Future<void> _reloadRestoredData() async {
    await Future.wait([
      _controller.reloadHistory(),
      _estimateController.reload(),
      _productivityController.reload(),
    ]);
  }

  Future<void> _openFunctionList() async {
    final function = await showDialog<String>(
      context: context,
      builder: (_) => FunctionListDialog(
        angleUnit: widget.settings.angleUnit,
        onAngleUnitChanged: _changeAngleUnitFromFunctionList,
      ),
    );
    if (function != null && mounted) {
      unawaited(_provideButtonFeedback());
      final notice = _controller.insertFunction(function);
      if (notice != null) _showMessage(notice);
    }
  }

  void _changeAngleUnitFromFunctionList(AngleUnit angleUnit) {
    _controller.updateDisplaySettings(
      decimalPlaces: widget.settings.decimalPlaces,
      roundingMode: widget.settings.roundingMode,
      angleUnit: angleUnit,
    );
    widget.onSettingsChanged?.call(
      widget.settings.copyWith(angleUnit: angleUnit),
    );
  }

  void _selectSideMenu(CalculatorSideMenuDestination destination) {
    Navigator.of(context).pop();

    if (destination == CalculatorSideMenuDestination.settings) {
      unawaited(_openFromSideMenu(_openSettings));
      return;
    }
    if (destination == CalculatorSideMenuDestination.help) {
      unawaited(
        _openFromSideMenu(
          () => Navigator.of(
            context,
          ).push(MaterialPageRoute<void>(builder: (_) => const HelpScreen())),
        ),
      );
      return;
    }
    if (destination == CalculatorSideMenuDestination.instantEstimate) {
      unawaited(
        _openFromSideMenu(
          () => _openWithRewardedAccess(
            RewardedAdEntryPoint.instantEstimate,
            _openEstimateDocuments,
          ),
        ),
      );
      return;
    }
    if (destination == CalculatorSideMenuDestination.unitPriceMaster) {
      unawaited(
        _openFromSideMenu(
          () => _openWithRewardedAccess(
            RewardedAdEntryPoint.unitPriceMaster,
            _openUnitPriceMaster,
          ),
        ),
      );
      return;
    }
    if (destination == CalculatorSideMenuDestination.productivityMaster) {
      unawaited(
        _openFromSideMenu(
          () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) =>
                  ProductivityMasterScreen(controller: _productivityController),
            ),
          ),
        ),
      );
      return;
    }
    if (destination == CalculatorSideMenuDestination.constructionCalculations) {
      unawaited(
        _openFromSideMenu(
          () => _openWithRewardedAccess(
            RewardedAdEntryPoint.convenientCalculation,
            () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ConstructionCalculationsScreen(
                  onSendToEstimate: _sendDraftToEstimate,
                  productivityController: _productivityController,
                  settings: widget.settings,
                  onSettingsChanged: widget.onSettingsChanged,
                ),
              ),
            ),
          ),
        ),
      );
      return;
    }
    if (destination == CalculatorSideMenuDestination.unitConversion) {
      unawaited(
        _openFromSideMenu(
          () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => UnitConversionScreen(settings: widget.settings),
            ),
          ),
        ),
      );
      return;
    }
    if (destination == CalculatorSideMenuDestination.adFree ||
        destination == CalculatorSideMenuDestination.full) {
      final plan = destination == CalculatorSideMenuDestination.adFree
          ? AppAccessPlan.adFree
          : AppAccessPlan.full;
      unawaited(
        _openFromSideMenu(
          () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => AccessPlanScreen(
                plan: plan,
                currentPlan: widget.accessPlan,
                purchaseStore: widget.purchaseStore,
              ),
            ),
          ),
        ),
      );
      return;
    }

    final label = switch (destination) {
      CalculatorSideMenuDestination.settings => '設定',
      CalculatorSideMenuDestination.help => 'ヘルプ',
      CalculatorSideMenuDestination.adFree => '広告なし版',
      CalculatorSideMenuDestination.full => '完全版',
      CalculatorSideMenuDestination.constructionCalculations => '便利計算一覧',
      CalculatorSideMenuDestination.unitConversion => '単位変換',
      CalculatorSideMenuDestination.instantEstimate => 'インスタント見積',
      CalculatorSideMenuDestination.unitPriceMaster => '単価マスタ',
      CalculatorSideMenuDestination.productivityMaster => '歩掛・生産性マスタ',
    };
    _showMessage('$labelは今後の工程で追加します');
  }

  Future<void> _openFromSideMenu(Future<void> Function() openScreen) async {
    await openScreen();
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _scaffoldKey.currentState?.openDrawer();
    });
  }

  Future<void> _openWithRewardedAccess(
    RewardedAdEntryPoint entryPoint,
    Future<void> Function() openScreen,
  ) async {
    final requestAccess = widget.onRequestRewardedAdAccess;
    if (requestAccess != null && !await requestAccess(entryPoint)) return;
    if (!mounted) return;
    await openScreen();
  }

  Future<void> _openUnitPriceMaster() async {
    try {
      await _estimateController.load();
    } catch (_) {
      if (mounted) _showMessage('単価マスタを読み込めませんでした');
      return;
    }
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => UnitPriceMasterScreen(controller: _estimateController),
      ),
    );
  }

  Future<void> _openEstimateDocuments() async {
    try {
      await _estimateController.load();
    } catch (_) {
      if (mounted) _showMessage('見積明細を読み込めませんでした');
      return;
    }
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => EstimateDocumentsScreen(
          controller: _estimateController,
          settings: widget.settings,
          onSettingsChanged: widget.onSettingsChanged,
          onRequestRewardedAdAccess: widget.onRequestRewardedAdAccess,
        ),
      ),
    );
  }

  Future<void> _openActiveEstimate() async {
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => EstimateItemsScreen(
          controller: _estimateController,
          settings: widget.settings,
          onSettingsChanged: widget.onSettingsChanged,
          onRequestRewardedAdAccess: widget.onRequestRewardedAdAccess,
        ),
      ),
    );
  }

  Future<void> _showCalculationMenu() async {
    final action = await showModalBottomSheet<_CalculationMenuAction>(
      context: context,
      showDragHandle: true,
      builder: (context) => const _CalculationMenuSheet(),
    );
    if (action == null || !mounted) return;

    switch (action) {
      case _CalculationMenuAction.copy:
        await Clipboard.setData(ClipboardData(text: _controller.clipboardText));
        _showMessage('コピーしました');
      case _CalculationMenuAction.cut:
        await Clipboard.setData(
          ClipboardData(text: _controller.displayExpression),
        );
        _controller.clear();
        _showMessage('カットしました');
      case _CalculationMenuAction.paste:
        final data = await Clipboard.getData(Clipboard.kTextPlain);
        if (!mounted) return;
        final pasted = _controller.pasteAtCaret(data?.text ?? '');
        _showMessage(pasted ? 'ペーストしました' : '貼り付けできる計算式がありません');
      case _CalculationMenuAction.clear:
        _controller.clear();
      case _CalculationMenuAction.sendToEstimate:
        await _showEstimateTransferSheet();
    }
  }

  Future<void> _showEstimateTransferSheet({
    String? expressionText,
    String? resultText,
    double? quantityValue,
  }) async {
    final expression = expressionText ?? _controller.estimateExpressionText;
    final result = resultText ?? _controller.estimateResultText;
    final quantity = quantityValue ?? _controller.estimateQuantityValue;
    if (expression.isEmpty) {
      _showMessage('見積へ送る計算式がありません');
      return;
    }

    final request = await showModalBottomSheet<_EstimateTransferRequest>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _EstimateTransferSheet(
        expressionText: expression,
        resultText: result,
      ),
    );
    if (request == null || !mounted) return;

    final transferText = switch (request.content) {
      _EstimateContent.expression => expression,
      _EstimateContent.result => result,
      _EstimateContent.expressionAndResult => '$expression = $result',
    };
    final draft = EstimateItemDraft(
      name: request.destination == _EstimateDestination.name
          ? transferText
          : '',
      specification: request.destination == _EstimateDestination.specification
          ? transferText
          : '',
      quantity: request.destination == _EstimateDestination.quantity
          ? quantity
          : null,
      description: request.destination == _EstimateDestination.description
          ? transferText
          : '',
      calculationBasis: '$expression = $result',
      originalQuantity: quantity,
    );
    await _sendDraftToEstimate(draft);
  }

  Future<void> _sendDraftToEstimate(EstimateItemDraft draft) async {
    try {
      await _estimateController.load();
    } catch (_) {
      if (mounted) _showMessage('見積明細を読み込めませんでした');
      return;
    }
    if (!mounted) return;
    final editorResult = await Navigator.of(context)
        .push<EstimateItemEditorResult>(
          MaterialPageRoute(
            builder: (_) => EstimateItemEditorScreen(
              initialDraft: draft,
              settings: widget.settings,
              estimateTitle: _estimateController.info.displayName,
              estimates: _estimateController.estimates,
              initialEstimateId: _estimateController.info.id,
              unitPriceMasters: _estimateController.unitPriceMasters,
            ),
          ),
        );
    if (editorResult == null || !mounted) return;
    var addedToMaster = false;
    String? addedItemId;
    var updatedExisting = false;
    double? mergedQuantity;
    try {
      final estimateId = editorResult.estimateId;
      if (estimateId != null && estimateId != _estimateController.info.id) {
        await _estimateController.selectEstimate(estimateId);
      }
      if (!mounted) return;
      final duplicate = _estimateController.findDuplicate(editorResult.draft);
      if (duplicate != null) {
        final action = await showDuplicateEstimateItemDialog(
          context,
          duplicate,
        );
        if (!mounted || action == DuplicateEstimateItemAction.cancel) return;
        if (action == DuplicateEstimateItemAction.updateExisting) {
          await _estimateController.update(duplicate.id, editorResult.draft);
          updatedExisting = true;
        } else {
          final addedItem = await _estimateController.add(editorResult.draft);
          addedItemId = addedItem.id;
        }
      } else {
        final mergeCandidate = _estimateController.findQuantityMergeCandidate(
          editorResult.draft,
        );
        if (mergeCandidate != null) {
          final action = await showMergeEstimateQuantityDialog(
            context,
            existing: mergeCandidate,
            incoming: editorResult.draft,
          );
          if (!mounted || action == MergeEstimateQuantityAction.cancel) return;
          if (action == MergeEstimateQuantityAction.merge) {
            final merged = await _estimateController.mergeQuantity(
              mergeCandidate.id,
              editorResult.draft,
            );
            mergedQuantity = merged.quantity;
          } else {
            final addedItem = await _estimateController.add(editorResult.draft);
            addedItemId = addedItem.id;
          }
        } else {
          final addedItem = await _estimateController.add(editorResult.draft);
          addedItemId = addedItem.id;
        }
      }
      if (editorResult.saveToUnitPriceMaster) {
        addedToMaster = await _estimateController
            .addEstimateItemToUnitPriceMasterIfAbsent(editorResult.draft);
      }
    } catch (_) {
      if (mounted) _showMessage('見積明細を保存できませんでした');
      return;
    }
    if (!mounted) return;
    if (editorResult.action == EstimateItemEditorAction.openEstimate) {
      await _openActiveEstimate();
      return;
    }
    if (updatedExisting) {
      _showMessage(addedToMaster ? '既存明細を更新し単価マスタへ追加しました' : '既存の見積明細を更新しました');
      return;
    }
    if (mergedQuantity != null) {
      _showMessage(
        addedToMaster
            ? '数量を加算し単価マスタへ追加しました'
            : '既存明細の数量を${_displayEstimateQuantity(mergedQuantity)}へ加算しました',
      );
      return;
    }
    _showEstimateAddedMessage(
      addedToMaster
          ? '見積明細と単価マスタへ追加しました'
          : '見積明細へ追加しました（${_estimateController.items.length}件）',
      itemId: addedItemId,
    );
  }

  Future<void> _showHistoryMenu(
    CalculationHistoryEntry entry, {
    bool returnToCalculatorOnEdit = false,
  }) async {
    final action = await showModalBottomSheet<_HistoryMenuAction>(
      context: context,
      showDragHandle: true,
      builder: (context) => const _HistoryMenuSheet(),
    );
    if (action == null || !mounted) return;

    switch (action) {
      case _HistoryMenuAction.copy:
        await Clipboard.setData(
          ClipboardData(text: '${entry.expression} = ${entry.result}'),
        );
        _showMessage('履歴をコピーしました');
      case _HistoryMenuAction.share:
        final box = context.findRenderObject() as RenderBox?;
        await SharePlus.instance.share(
          ShareParams(
            text: '${entry.expression} = ${entry.result}',
            sharePositionOrigin: box == null
                ? null
                : box.localToGlobal(Offset.zero) & box.size,
          ),
        );
      case _HistoryMenuAction.edit:
        _controller.editHistoryEntry(entry);
        if (returnToCalculatorOnEdit && mounted) {
          Navigator.of(context).pop();
        }
        _showMessage('計算式を編集欄へ戻しました');
      case _HistoryMenuAction.delete:
        if (await _confirmHistoryDeletion()) {
          _controller.deleteHistoryEntry(entry);
          _showMessage('履歴を削除しました');
        }
      case _HistoryMenuAction.star:
        _showMessage('スターはアルティメット版で利用できます');
      case _HistoryMenuAction.sendToEstimate:
        await _showEstimateTransferSheet(
          expressionText: entry.expression,
          resultText: entry.result,
          quantityValue: _parseEstimateNumber(entry.decimalResult),
        );
    }
  }

  Future<bool> _confirmHistoryDeletion() async {
    if (!widget.settings.confirmHistoryDeletion) return true;
    final strings = AppLocalizations.of(context);
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(strings.text('履歴を削除')),
            content: Text(strings.text('この計算履歴を削除しますか？')),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(strings.text('キャンセル')),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(strings.text('削除')),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _openFullHistory() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CalculatorHistoryScreen(
          controller: _controller,
          initialSortOrder: widget.settings.historySortOrder,
          onSortOrderChanged: (value) => widget.onSettingsChanged?.call(
            widget.settings.copyWith(historySortOrder: value),
          ),
          onMenuPressed: (entry) =>
              _showHistoryMenu(entry, returnToCalculatorOnEdit: true),
        ),
      ),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    final localizedMessage = AppLocalizations.of(context).text(message);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(localizedMessage),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  void _showEstimateAddedMessage(String message, {required String? itemId}) {
    if (!mounted || itemId == null) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 5),
          content: Row(
            children: [
              Expanded(child: Text(message)),
              TextButton(
                key: const Key('openAddedEstimate'),
                onPressed: () {
                  messenger.hideCurrentSnackBar();
                  unawaited(_openActiveEstimate());
                },
                child: Text(AppLocalizations.of(context).text('見積を開く')),
              ),
            ],
          ),
          action: SnackBarAction(
            key: const Key('undoEstimateItemAdd'),
            label: AppLocalizations.of(context).text('元に戻す'),
            onPressed: () async {
              try {
                await _estimateController.delete(itemId);
                if (mounted) _showMessage('直前の追加を取り消しました');
              } catch (_) {
                if (mounted) _showMessage('追加を取り消せませんでした');
              }
            },
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Scaffold(
        key: _scaffoldKey,
        drawer: CalculatorSideMenu(
          showAds: widget.accessPlan.showsAds,
          accessPlan: widget.accessPlan,
          isRewardedAdRequired: widget.isRewardedAdRequired,
          enableGoogleMobileAds: widget.enableGoogleMobileAds,
          onSelected: _selectSideMenu,
        ),
        body: Stack(
          fit: StackFit.expand,
          children: [
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxHeight < 700;
                  final gap = compact ? 4.0 : 6.0;
                  const sectionGap = 4.0;
                  final horizontalContentWidth = constraints.maxWidth - gap * 2;
                  final desiredKeypadHeight = _calculatorKeypadHeight(
                    width: horizontalContentWidth,
                    gap: gap,
                  );
                  final adHeight = compact ? 50.0 : 58.0;
                  final contentHeight = constraints.maxHeight - 4 - gap;
                  final desiredExpressionHeight = (constraints.maxHeight * 0.21)
                      .clamp(compact ? 96.0 : 148.0, compact ? 114.0 : 168.0)
                      .toDouble();
                  final historyRowCount = widget.accessPlan.showsAds
                      ? _freeHistoryRowCount
                      : _adFreeHistoryRowCount;
                  final desiredHistoryHeight = _calculatorHistoryPanelHeight(
                    rowCount: historyRowCount,
                  );
                  final reservedAdBlockHeight = widget.accessPlan.showsAds
                      ? adHeight + sectionGap
                      : 0.0;
                  final minimumExpressionHeight = compact
                      ? 72.0
                      : desiredExpressionHeight;
                  final keypadBudget =
                      contentHeight -
                      reservedAdBlockHeight -
                      sectionGap * 2 -
                      desiredHistoryHeight -
                      minimumExpressionHeight;
                  final keypadHeight = desiredKeypadHeight
                      .clamp(0.0, keypadBudget.clamp(0.0, double.infinity))
                      .toDouble();
                  final upperContentBudget =
                      contentHeight -
                      reservedAdBlockHeight -
                      sectionGap * 2 -
                      keypadHeight;
                  final historyHeight = desiredHistoryHeight
                      .clamp(
                        0.0,
                        (upperContentBudget - minimumExpressionHeight).clamp(
                          0.0,
                          double.infinity,
                        ),
                      )
                      .toDouble();
                  final expressionHeight = (upperContentBudget - historyHeight)
                      .clamp(0.0, double.infinity)
                      .toDouble();
                  return Padding(
                    padding: EdgeInsets.fromLTRB(gap, 4, gap, gap),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (widget.accessPlan.showsAds) ...[
                          _AdBanner(
                            key: const Key('calculatorAdBanner'),
                            height: adHeight,
                            enableGoogleMobileAds: widget.enableGoogleMobileAds,
                            onUpgrade: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => AccessPlanScreen(
                                  plan: AppAccessPlan.adFree,
                                  currentPlan: widget.accessPlan,
                                  purchaseStore: widget.purchaseStore,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: sectionGap),
                        ],
                        SizedBox(
                          height: historyHeight,
                          child: _HistoryPanel(
                            key: const Key('historyPanel'),
                            history: _controller.history,
                            onMenuPressed: _showHistoryMenu,
                            onLongPress: _openFullHistory,
                          ),
                        ),
                        const SizedBox(height: sectionGap),
                        SizedBox(
                          height: expressionHeight,
                          child: _ExpressionPanel(
                            controller: _controller,
                            onLongPress: _showCalculationMenu,
                          ),
                        ),
                        const SizedBox(height: sectionGap),
                        SizedBox(
                          key: const Key('calculatorKeypadArea'),
                          height: keypadHeight,
                          child: _Keypad(
                            gap: gap,
                            canCycleFraction: _controller.canCycleFraction,
                            onPressed: _pressKey,
                            onBackLongPressed: _controller.clearLeftOfCaret,
                            onMenuFunctionsRequested: () =>
                                unawaited(_openFunctionList()),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            if (_digitLimitNoticeVisible)
              Positioned(
                left: 16,
                right: 16,
                bottom: MediaQuery.viewPaddingOf(context).bottom + 8,
                child: const IgnorePointer(
                  key: Key('digitLimitNoticeIgnorePointer'),
                  child: _DigitLimitNotice(key: Key('digitLimitNotice')),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DigitLimitNotice extends StatelessWidget {
  const _DigitLimitNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return Center(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: (dark ? Colors.grey.shade700 : Colors.grey.shade300)
              .withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: dark ? Colors.white24 : Colors.black12),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(
            AppLocalizations.of(context).calculatorDigitLimitNotice,
            key: const Key('digitLimitNoticeText'),
            style: TextStyle(
              color: dark ? Colors.white : Colors.black87,
              fontSize: 13,
              height: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}

double _calculatorKeypadHeight({required double width, required double gap}) {
  const columnCount = 4;
  const rowCount = 6;
  const childAspectRatio = 1.52;
  final buttonWidth = (width - gap * (columnCount - 1)) / columnCount;
  final buttonHeight = buttonWidth / childAspectRatio;
  return buttonHeight * rowCount + gap * (rowCount - 1);
}

const _historyRowHeight = 24.0;
const _historyVerticalPadding = 5.0;
const _freeHistoryRowCount = 3;
const _adFreeHistoryRowCount = 5;

double _calculatorHistoryPanelHeight({required int rowCount}) {
  return _historyRowHeight * rowCount + _historyVerticalPadding * 2;
}

String _displayEstimateQuantity(double? value) {
  if (value == null) return '';
  return value == value.truncateToDouble()
      ? value.toInt().toString()
      : value.toString();
}

class _AdBanner extends StatelessWidget {
  const _AdBanner({
    required this.height,
    required this.onUpgrade,
    required this.enableGoogleMobileAds,
    super.key,
  });

  final double height;
  final VoidCallback onUpgrade;
  final bool enableGoogleMobileAds;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final strings = AppLocalizations.of(context);
    final fallback = SizedBox(
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          border: Border.all(color: colors.outlineVariant),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Row(
          children: [
            Container(
              width: 72,
              decoration: const BoxDecoration(
                color: AppColors.adLabelBackground,
                borderRadius: BorderRadius.horizontal(left: Radius.circular(6)),
              ),
              alignment: Alignment.center,
              child: Text(
                strings.text('広告スペース'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  height: 1.15,
                  fontSize: 13,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  strings.text('広告なし版で非表示に！'),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(5),
              child: FilledButton(
                onPressed: onUpgrade,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(74, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 7),
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
                child: Text(
                  strings.text('今すぐ\nアップグレード'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11, height: 1.1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    if (!enableGoogleMobileAds) return fallback;
    return GoogleMobileAdsBanner(height: height, fallback: fallback);
  }
}

class _HistoryPanel extends StatelessWidget {
  const _HistoryPanel({
    required this.history,
    required this.onMenuPressed,
    required this.onLongPress,
    super.key,
  });

  final List<CalculationHistoryEntry> history;
  final ValueChanged<CalculationHistoryEntry> onMenuPressed;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: onLongPress,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.dark
              ? AppColors.darkHistory
              : AppColors.lightHistory,
          borderRadius: BorderRadius.circular(8),
        ),
        child: ListView.builder(
          reverse: true,
          padding: const EdgeInsets.symmetric(
            horizontal: 9,
            vertical: _historyVerticalPadding,
          ),
          itemCount: history.length,
          itemBuilder: (context, reversedIndex) {
            final index = history.length - 1 - reversedIndex;
            final item = history[index];
            return SizedBox(
              height: _historyRowHeight,
              child: Row(
                children: [
                  GestureDetector(
                    key: Key('historyMenuButton$index'),
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onMenuPressed(item),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: Icon(
                        Icons.more_vert,
                        size: 17,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: '${item.expression} = '),
                          TextSpan(
                            text: item.result,
                            style: const TextStyle(color: AppColors.accent),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge?.copyWith(fontSize: 15),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

enum _HistoryMenuAction { copy, share, edit, delete, star, sendToEstimate }

class _HistoryMenuSheet extends StatelessWidget {
  const _HistoryMenuSheet();

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    const items = <(_HistoryMenuAction, IconData, String)>[
      (_HistoryMenuAction.copy, Icons.copy_outlined, 'コピー'),
      (_HistoryMenuAction.share, Icons.share_outlined, '共有'),
      (_HistoryMenuAction.edit, Icons.edit_outlined, '編集'),
      (_HistoryMenuAction.delete, Icons.delete_outline, '削除'),
      (_HistoryMenuAction.star, Icons.star_border, 'スター'),
      (_HistoryMenuAction.sendToEstimate, Icons.receipt_long_outlined, '見積へ送る'),
    ];
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          for (final item in items)
            ListTile(
              leading: Icon(item.$2),
              title: Text(strings.text(item.$3)),
              onTap: () => Navigator.of(context).pop(item.$1),
            ),
        ],
      ),
    );
  }
}

class _ExpressionPanel extends StatelessWidget {
  const _ExpressionPanel({required this.controller, required this.onLongPress});

  final CalculatorController controller;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      key: const Key('calculationSpace'),
      behavior: HitTestBehavior.opaque,
      onLongPress: onLongPress,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.dark
              ? Colors.black
              : Colors.white,
          border: Border.all(color: theme.colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: _EditableExpressionLine(controller: controller)),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: _ResultLine(controller: controller),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultLine extends StatelessWidget {
  const _ResultLine({required this.controller});

  final CalculatorController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (controller.state == CalculatorState.error) {
      return Text(
        AppLocalizations.of(context).text(controller.errorMessage!),
        key: const Key('resultText'),
        maxLines: 1,
        style: theme.textTheme.displaySmall?.copyWith(
          color: theme.colorScheme.error,
          fontSize: 23,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    final resultStyle = theme.textTheme.displaySmall?.copyWith(
      color: AppColors.accent.withValues(
        alpha: controller.isPreviewResult ? 0.55 : 1,
      ),
      fontSize: 42,
      height: 1,
      fontWeight: FontWeight.w500,
    );
    if (controller.resultDisplayMode == ResultDisplayMode.decimal) {
      return Text(
        '=  ${controller.result}',
        key: const Key('resultText'),
        maxLines: 1,
        style: resultStyle,
      );
    }

    final signedNumerator = controller.resultFractionNumerator!;
    final denominator = controller.resultFractionDenominator!;
    var numeratorText = signedNumerator.toString().replaceFirst('-', '−');
    String? wholeNumberText;
    if (controller.resultDisplayMode == ResultDisplayMode.mixedFraction) {
      final absoluteNumerator = signedNumerator.abs();
      final wholeNumber = absoluteNumerator ~/ denominator;
      final remainder = absoluteNumerator % denominator;
      if (wholeNumber > 0) {
        wholeNumberText = '${signedNumerator < 0 ? '−' : ''}$wholeNumber';
        numeratorText = remainder.toString();
      } else {
        numeratorText = '${signedNumerator < 0 ? '−' : ''}$remainder';
      }
    }

    return Row(
      key: const Key('resultText'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text('=', style: resultStyle),
        const SizedBox(width: 18),
        if (wholeNumberText != null) ...[
          Text(wholeNumberText, style: resultStyle),
          const SizedBox(width: 6),
        ],
        _StackedResultFraction(
          numerator: numeratorText,
          denominator: denominator.toString(),
          style: resultStyle!,
        ),
      ],
    );
  }
}

class _StackedResultFraction extends StatelessWidget {
  const _StackedResultFraction({
    required this.numerator,
    required this.denominator,
    required this.style,
  });

  final String numerator;
  final String denominator;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return IntrinsicWidth(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(numerator, textAlign: TextAlign.center, style: style),
          Container(height: 2, color: AppColors.accent),
          Text(denominator, textAlign: TextAlign.center, style: style),
        ],
      ),
    );
  }
}

double? _parseEstimateNumber(String value) {
  final parsed = double.tryParse(value.replaceAll(',', '').trim());
  return parsed != null && parsed.isFinite ? parsed : null;
}

enum _CalculationMenuAction { copy, cut, paste, clear, sendToEstimate }

class _CalculationMenuSheet extends StatelessWidget {
  const _CalculationMenuSheet();

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    const items = <(_CalculationMenuAction, IconData, String)>[
      (_CalculationMenuAction.copy, Icons.copy_outlined, 'コピー'),
      (_CalculationMenuAction.cut, Icons.content_cut, 'カット'),
      (_CalculationMenuAction.paste, Icons.content_paste, 'ペースト'),
      (_CalculationMenuAction.clear, Icons.delete_outline, '消去'),
      (
        _CalculationMenuAction.sendToEstimate,
        Icons.receipt_long_outlined,
        '見積へ送る',
      ),
    ];

    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          for (final item in items)
            ListTile(
              leading: Icon(item.$2),
              title: Text(strings.text(item.$3)),
              onTap: () => Navigator.of(context).pop(item.$1),
            ),
        ],
      ),
    );
  }
}

enum _EstimateContent {
  expression('式'),
  result('解'),
  expressionAndResult('式＋解');

  const _EstimateContent(this.label);
  final String label;
}

enum _EstimateDestination {
  name('名称'),
  specification('仕様'),
  quantity('数量'),
  description('摘要');

  const _EstimateDestination(this.label);
  final String label;
}

class _EstimateTransferRequest {
  const _EstimateTransferRequest({
    required this.content,
    required this.destination,
  });

  final _EstimateContent content;
  final _EstimateDestination destination;
}

class _EstimateTransferSheet extends StatefulWidget {
  const _EstimateTransferSheet({
    required this.expressionText,
    required this.resultText,
  });

  final String expressionText;
  final String resultText;

  @override
  State<_EstimateTransferSheet> createState() => _EstimateTransferSheetState();
}

class _EstimateTransferSheetState extends State<_EstimateTransferSheet> {
  _EstimateContent _content = _EstimateContent.expressionAndResult;
  _EstimateDestination _destination = _EstimateDestination.description;

  String get _preview {
    return switch (_content) {
      _EstimateContent.expression => widget.expressionText,
      _EstimateContent.result => widget.resultText,
      _EstimateContent.expressionAndResult =>
        '${widget.expressionText} = ${widget.resultText}',
    };
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              strings.text('見積へ送る'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Text(strings.text('送信内容')),
            const SizedBox(height: 8),
            SegmentedButton<_EstimateContent>(
              key: const Key('estimateContentSelector'),
              segments: [
                for (final content in _EstimateContent.values)
                  ButtonSegment(
                    value: content,
                    label: Text(strings.text(content.label)),
                  ),
              ],
              selected: {_content},
              onSelectionChanged: (selection) {
                setState(() => _content = selection.first);
              },
            ),
            const SizedBox(height: 16),
            Text(strings.text('送信先')),
            const SizedBox(height: 8),
            DropdownButtonFormField<_EstimateDestination>(
              key: const Key('estimateDestinationSelector'),
              initialValue: _destination,
              items: [
                for (final destination in _EstimateDestination.values)
                  DropdownMenuItem(
                    value: destination,
                    child: Text(strings.text(destination.label)),
                  ),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _destination = value);
              },
            ),
            const SizedBox(height: 16),
            Text(
              strings.text('送信内容の確認'),
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 6),
            DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  _preview,
                  key: const Key('estimateTransferPreview'),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(strings.text('キャンセル')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    key: const Key('estimateTransferNext'),
                    onPressed: () {
                      Navigator.of(context).pop(
                        _EstimateTransferRequest(
                          content: _content,
                          destination: _destination,
                        ),
                      );
                    },
                    child: Text(strings.text('次へ')),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EditableExpressionLine extends StatefulWidget {
  const _EditableExpressionLine({required this.controller});

  final CalculatorController controller;
  static const double _expressionFontSize = 42;

  @override
  State<_EditableExpressionLine> createState() =>
      _EditableExpressionLineState();
}

class _EditableExpressionLineState extends State<_EditableExpressionLine> {
  final ScrollController _scrollController = ScrollController();
  String _lastExpressionSignature = '';

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.headlineMedium!.copyWith(
      fontSize: _EditableExpressionLine._expressionFontSize,
      fontWeight: FontWeight.w400,
    );
    final segments = widget.controller.displaySegments;
    final lines = <List<ExpressionDisplaySegment>>[[]];
    for (final segment in segments) {
      if (segment is ExpressionLineBreakSegment) {
        lines.add([]);
      } else {
        lines.last.add(segment);
      }
    }
    final fractionSignature = segments
        .whereType<ExpressionFractionSegment>()
        .map(
          (segment) =>
              '${segment.marker}:${segment.wholeNumber}:'
              '${segment.numerator}:${segment.denominator}:'
              '${segment.activeField}:${segment.activeCaretOffset}',
        )
        .join('|');
    final signature =
        '${widget.controller.expression}|'
        '${widget.controller.caretPosition}|$fractionSignature';
    if (signature != _lastExpressionSignature) {
      _lastExpressionSignature = signature;
      if (lines.length > 2) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || !_scrollController.hasClients) return;
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        });
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final visibleLineCount = math.min(2, math.max(1, lines.length));
        final lineHeight = constraints.maxHeight / visibleLineCount;
        return ClipRect(
          child: SingleChildScrollView(
            key: const Key('expressionVerticalScroll'),
            controller: _scrollController,
            scrollDirection: Axis.vertical,
            child: SizedBox(
              key: const Key('expressionText'),
              width: constraints.maxWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var lineIndex = 0; lineIndex < lines.length; lineIndex++)
                    SizedBox(
                      key: Key('expressionLine-$lineIndex'),
                      height: lineHeight,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: FittedBox(
                          key: Key('expressionLineScale-$lineIndex'),
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              for (final segment in lines[lineIndex])
                                _buildSegment(segment, style),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSegment(ExpressionDisplaySegment segment, TextStyle style) {
    return switch (segment) {
      ExpressionTextSegment() => _EditableExpressionText(
        segment: segment,
        style: style,
        onRawOffsetTap: widget.controller.moveCaretToRawOffset,
      ),
      ExpressionCaretSegment() => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 2),
        child: SizedBox(
          key: Key('calculatorCaret'),
          width: 2,
          height: 46,
          child: ColoredBox(color: AppColors.accent),
        ),
      ),
      ExpressionFractionSegment() => _InlineFraction(
        segment: segment,
        fontSize: _EditableExpressionLine._expressionFontSize,
        onBeforeFractionTap: () {
          widget.controller.moveCaretBeforeFraction(segment.marker);
        },
        onAfterFractionTap: () {
          widget.controller.moveCaretAfterFraction(segment.marker);
        },
        onFieldTap: (field, caretOffset) {
          widget.controller.activateFraction(
            segment.marker,
            field,
            caretOffset: caretOffset,
          );
        },
      ),
      ExpressionLineBreakSegment() => const SizedBox.shrink(),
    };
  }
}

class _EditableExpressionText extends StatelessWidget {
  const _EditableExpressionText({
    required this.segment,
    required this.style,
    required this.onRawOffsetTap,
  });

  final ExpressionTextSegment segment;
  final TextStyle style;
  final ValueChanged<int> onRawOffsetTap;

  @override
  Widget build(BuildContext context) {
    final painter = TextPainter(
      text: TextSpan(text: segment.text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: (details) {
        final localX = details.localPosition.dx.clamp(0.0, painter.width);
        final textOffset = painter
            .getPositionForOffset(Offset(localX, 0))
            .offset
            .clamp(0, segment.text.length);
        onRawOffsetTap(segment.rawOffsets[textOffset]);
      },
      child: Padding(
        // A small vertical expansion makes short digits and operators easier
        // to hit without changing their visual spacing.
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(segment.text, style: style, maxLines: 1),
      ),
    );
  }
}

class _InlineFraction extends StatelessWidget {
  const _InlineFraction({
    required this.segment,
    required this.fontSize,
    required this.onBeforeFractionTap,
    required this.onAfterFractionTap,
    required this.onFieldTap,
  });

  final ExpressionFractionSegment segment;
  final double fontSize;
  final VoidCallback onBeforeFractionTap;
  final VoidCallback onAfterFractionTap;
  final void Function(FractionField field, int caretOffset) onFieldTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            key: const Key('fractionBeforeTapArea'),
            behavior: HitTestBehavior.opaque,
            onTap: onBeforeFractionTap,
            child: SizedBox(width: 14, height: fontSize * 2.1),
          ),
          if (segment.wholeNumber.isNotEmpty) ...[
            _FractionFieldDisplay(
              key: const Key('mixedFractionWholeNumber'),
              caretSlotKey: const Key('mixedFractionWholeNumberCaretSlot'),
              value: segment.wholeNumber,
              active: segment.activeField == FractionField.wholeNumber,
              caretOffset: segment.activeField == FractionField.wholeNumber
                  ? segment.activeCaretOffset
                  : null,
              fontSize: fontSize,
              onTap: (offset) {
                onFieldTap(FractionField.wholeNumber, offset);
              },
            ),
            const SizedBox(width: 2),
          ],
          IntrinsicWidth(
            key: const Key('fractionDisplay'),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _FractionFieldDisplay(
                  key: const Key('fractionNumeratorField'),
                  caretSlotKey: const Key('fractionNumeratorCaretSlot'),
                  value: segment.numerator,
                  active: segment.activeField == FractionField.numerator,
                  caretOffset: segment.activeField == FractionField.numerator
                      ? segment.activeCaretOffset
                      : null,
                  fontSize: fontSize,
                  onTap: (offset) {
                    onFieldTap(FractionField.numerator, offset);
                  },
                ),
                Container(
                  key: const Key('fractionBar'),
                  height: 1.5,
                  color: AppColors.accent,
                ),
                _FractionFieldDisplay(
                  key: const Key('fractionDenominatorField'),
                  caretSlotKey: const Key('fractionDenominatorCaretSlot'),
                  value: segment.denominator,
                  active: segment.activeField == FractionField.denominator,
                  caretOffset: segment.activeField == FractionField.denominator
                      ? segment.activeCaretOffset
                      : null,
                  fontSize: fontSize,
                  onTap: (offset) {
                    onFieldTap(FractionField.denominator, offset);
                  },
                ),
              ],
            ),
          ),
          GestureDetector(
            key: const Key('fractionAfterTapArea'),
            behavior: HitTestBehavior.opaque,
            onTap: onAfterFractionTap,
            child: SizedBox(width: 24, height: fontSize * 2.1),
          ),
        ],
      ),
    );
  }
}

class _FractionFieldDisplay extends StatelessWidget {
  const _FractionFieldDisplay({
    required this.value,
    required this.active,
    required this.caretOffset,
    required this.caretSlotKey,
    required this.fontSize,
    required this.onTap,
    super.key,
  });

  final String value;
  final bool active;
  final int? caretOffset;
  final Key caretSlotKey;
  final double fontSize;
  final ValueChanged<int> onTap;

  static const double _caretGap = 2;
  static const double _caretWidth = 1.5;
  static const double _caretHeight = 32;

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    final textStyle = TextStyle(
      color: textColor,
      fontSize: fontSize,
      height: 1,
    );
    final placeholderStyle = textStyle.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    final offset = (caretOffset ?? value.length).clamp(0, value.length);
    final displayValue = value.isEmpty ? '□' : value;
    final displayOffset = value.isEmpty ? 0 : offset;
    final prefix = displayValue.substring(0, displayOffset);
    final suffix = displayValue.substring(displayOffset);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: (details) {
        if (value.isEmpty) {
          onTap(0);
          return;
        }
        final painter = TextPainter(
          text: TextSpan(text: value, style: textStyle),
          textDirection: TextDirection.ltr,
          maxLines: 1,
        )..layout();
        var localX = details.localPosition.dx - 5;
        if (active &&
            localX > _textWidth(value.substring(0, offset), textStyle)) {
          localX -= _caretGap + _caretWidth;
        }
        final position = painter.getPositionForOffset(
          Offset(localX.clamp(0.0, painter.width), 0),
        );
        onTap(position.offset.clamp(0, value.length));
      },
      child: SizedBox(
        height: fontSize * 1.05,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: Align(
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  prefix,
                  key: Key('${caretSlotKey.toString()}-prefix'),
                  style: value.isEmpty ? placeholderStyle : textStyle,
                  maxLines: 1,
                ),
                const SizedBox(width: _caretGap),
                Opacity(
                  opacity: active ? 1 : 0,
                  child: SizedBox(
                    key: caretSlotKey,
                    width: _caretWidth,
                    height: _caretHeight,
                    child: ColoredBox(
                      key: active ? const Key('fractionFieldCaret') : null,
                      color: AppColors.accent,
                    ),
                  ),
                ),
                Text(
                  suffix,
                  key: Key('${caretSlotKey.toString()}-suffix'),
                  style: value.isEmpty ? placeholderStyle : textStyle,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  double _textWidth(String text, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    return painter.width;
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad({
    required this.gap,
    required this.canCycleFraction,
    required this.onPressed,
    required this.onBackLongPressed,
    required this.onMenuFunctionsRequested,
  });

  final double gap;
  final bool canCycleFraction;
  final ValueChanged<_CalculatorKey> onPressed;
  final VoidCallback onBackLongPressed;
  final VoidCallback onMenuFunctionsRequested;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: CalculatorScreen._keys.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: gap,
        crossAxisSpacing: gap,
        childAspectRatio: 1.52,
      ),
      itemBuilder: (context, index) {
        final keyData = CalculatorScreen._keys[index];
        return _KeyButton(
          keyData: keyData,
          useFractionToggleColor:
              (keyData.kind == _KeyKind.fraction ||
                  keyData.kind == _KeyKind.fractionToggle) &&
              canCycleFraction,
          onPressed: () => onPressed(keyData),
          onDoublePressed: keyData.kind == _KeyKind.menu
              ? onMenuFunctionsRequested
              : null,
          onLongPressed: switch (keyData.kind) {
            _KeyKind.menu => onMenuFunctionsRequested,
            _ when keyData.label == '←' => onBackLongPressed,
            _ => null,
          },
        );
      },
    );
  }
}

class _KeyButton extends StatelessWidget {
  const _KeyButton({
    required this.keyData,
    required this.useFractionToggleColor,
    required this.onPressed,
    this.onLongPressed,
    this.onDoublePressed,
  });

  final _CalculatorKey keyData;
  final bool useFractionToggleColor;
  final VoidCallback onPressed;
  final VoidCallback? onLongPressed;
  final VoidCallback? onDoublePressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isGreen =
        keyData.kind == _KeyKind.operator ||
        keyData.kind == _KeyKind.fractionToggle;
    final isOrange = useFractionToggleColor;

    final backgroundColor = isOrange
        ? AppColors.fractionToggle
        : switch (keyData.kind) {
            _KeyKind.operator || _KeyKind.fractionToggle => AppColors.accent,
            _ => isDark ? AppColors.darkKey : AppColors.lightKey,
          };

    final foregroundColor = isGreen || isOrange
        ? Colors.white
        : theme.colorScheme.onSurface;

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(6),
      side: keyData.kind == _KeyKind.menu
          ? const BorderSide(color: AppColors.accent, width: 2)
          : BorderSide(
              color: isDark
                  ? AppColors.darkKeyBorder
                  : AppColors.lightKeyBorder,
            ),
    );
    final semanticLabel = switch (keyData.kind) {
      _KeyKind.menu => AppLocalizations.of(context).choose(
        japanese: 'メニュー',
        english: 'Menu',
        simplifiedChinese: '菜单',
        traditionalChinese: '選單',
      ),
      _KeyKind.settings => AppLocalizations.of(context).settings,
      _ => keyData.semanticLabel,
    };

    if (keyData.kind == _KeyKind.menu) {
      return Semantics(
        button: true,
        label: semanticLabel,
        excludeSemantics: true,
        child: Material(
          color: backgroundColor,
          shape: shape,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            onDoubleTap: onDoublePressed,
            onLongPress: onLongPressed,
            customBorder: shape,
            child: Center(child: _KeyContent(keyData: keyData)),
          ),
        ),
      );
    }

    return Semantics(
      button: true,
      label: semanticLabel,
      child: FilledButton(
        key: Key('calculatorKey${keyData.label}'),
        onPressed: onPressed,
        onLongPress: onLongPressed,
        style: FilledButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          shape: shape,
        ),
        child: _KeyContent(keyData: keyData),
      ),
    );
  }
}

class _KeyContent extends StatelessWidget {
  const _KeyContent({required this.keyData});

  final _CalculatorKey keyData;

  @override
  Widget build(BuildContext context) {
    return switch (keyData.kind) {
      _KeyKind.menu => const Text(
        '•••',
        style: TextStyle(fontSize: 21, letterSpacing: 2),
      ),
      _KeyKind.settings => const Icon(Icons.settings, size: 29),
      _KeyKind.fraction => const _FractionGlyph(),
      _ => Text(
        keyData.label,
        style: TextStyle(
          fontSize: keyData.label.length > 1 ? 23 : 28,
          fontWeight: FontWeight.w400,
        ),
      ),
    };
  }
}

class _FractionGlyph extends StatelessWidget {
  const _FractionGlyph();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    return SizedBox(
      width: 26,
      height: 42,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('a', style: TextStyle(color: color, fontSize: 16, height: 0.9)),
          Container(
            width: 24,
            height: 1.4,
            margin: const EdgeInsets.symmetric(vertical: 2),
            color: color,
          ),
          Text('b', style: TextStyle(color: color, fontSize: 16, height: 0.9)),
        ],
      ),
    );
  }
}

enum _KeyKind { text, menu, settings, fraction, operator, fractionToggle }

class _CalculatorKey {
  const _CalculatorKey._(this.label, this.kind, {this.semanticLabel});

  const _CalculatorKey.text(String label)
    : this._(label, _KeyKind.text, semanticLabel: label);

  const _CalculatorKey.menu()
    : this._('…', _KeyKind.menu, semanticLabel: 'メニュー');

  const _CalculatorKey.settings()
    : this._('⚙', _KeyKind.settings, semanticLabel: '設定');

  const _CalculatorKey.fraction()
    : this._('a/b', _KeyKind.fraction, semanticLabel: 'a/b');

  const _CalculatorKey.operator(String label)
    : this._(label, _KeyKind.operator, semanticLabel: label);

  const _CalculatorKey.fractionToggle(String label)
    : this._(label, _KeyKind.fractionToggle, semanticLabel: label);

  final String label;
  final _KeyKind kind;
  final String? semanticLabel;
}
