import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart'
    show CupertinoMagnifier, CupertinoTheme, cupertinoTextSelectionControls;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
import 'calculator_history_line.dart';
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
  final _expressionLineKey = GlobalKey<_EditableExpressionLineState>();
  Timer? _digitLimitVisibilityTimer;
  Timer? _digitLimitCooldownTimer;
  bool _digitLimitNoticeVisible = false;
  bool _digitLimitNoticeCoolingDown = false;
  ExpressionFragment? _internalClipboardFragment;
  String? _internalClipboardText;
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
    unawaited(_controller.loadHistory());
    unawaited(_loadEstimateItems());
    unawaited(_loadProductivityRecords());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _applyDisplaySettings();
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
      improperFractionResultEnabled:
          widget.settings.improperFractionResultEnabled,
      mixedFractionResultEnabled: widget.settings.mixedFractionResultEnabled,
      remainderResultEnabled: widget.settings.remainderResultEnabled,
      remainderResultFormatter: AppLocalizations.of(context).remainderText,
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
      _clearExpressionEditing();
      _scaffoldKey.currentState?.openDrawer();
      return;
    }
    if (key.kind == _KeyKind.settings) {
      _clearExpressionEditing();
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
          purchaseStore: widget.purchaseStore,
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
    _clearExpressionEditing();
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

  void _clearExpressionEditing() {
    _expressionLineKey.currentState?.clearTransientEditing();
  }

  void _changeAngleUnitFromFunctionList(AngleUnit angleUnit) {
    _controller.updateDisplaySettings(
      decimalPlaces: widget.settings.decimalPlaces,
      roundingMode: widget.settings.roundingMode,
      angleUnit: angleUnit,
      improperFractionResultEnabled:
          widget.settings.improperFractionResultEnabled,
      mixedFractionResultEnabled: widget.settings.mixedFractionResultEnabled,
      remainderResultEnabled: widget.settings.remainderResultEnabled,
      remainderResultFormatter: AppLocalizations.of(context).remainderText,
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

  Future<void> _handleSelectionMenuAction(_SelectionMenuAction action) async {
    switch (action) {
      case _SelectionMenuAction.copy:
        final fragment = _controller.copySelectionFragment();
        final text = _controller.selectedClipboardText;
        if (fragment == null || text.isEmpty) return;
        await Clipboard.setData(ClipboardData(text: text));
        _internalClipboardFragment = fragment;
        _internalClipboardText = text;
        if (mounted) _showMessage('コピーしました');
      case _SelectionMenuAction.cut:
        final fragment = _controller.copySelectionFragment();
        final text = _controller.selectedClipboardText;
        if (fragment == null || text.isEmpty) return;
        await Clipboard.setData(ClipboardData(text: text));
        _internalClipboardFragment = fragment;
        _internalClipboardText = text;
        _controller.deleteSelection();
        if (mounted) _showMessage('カットしました');
      case _SelectionMenuAction.paste:
        final data = await Clipboard.getData(Clipboard.kTextPlain);
        if (!mounted) return;
        final text = data?.text ?? '';
        final internalFragment = text == _internalClipboardText
            ? _internalClipboardFragment
            : null;
        final pasted = internalFragment != null
            ? _controller.pasteFragment(internalFragment)
            : _controller.pasteAtCaret(text);
        _showMessage(pasted ? 'ペーストしました' : '貼り付けできる計算式がありません');
      case _SelectionMenuAction.delete:
        _controller.deleteSelection();
      case _SelectionMenuAction.sendToEstimate:
        final selectedText = _controller.selectedClipboardText;
        if (selectedText.isEmpty) return;
        await _showSelectedEstimateTransferSheet(selectedText);
    }
  }

  Future<void> _showSelectedEstimateTransferSheet(String expression) async {
    final request = await showModalBottomSheet<_EstimateTransferRequest>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _EstimateTransferSheet(
        expressionText: expression,
        resultText: '',
        selectionOnly: true,
      ),
    );
    if (request == null || !mounted) return;
    final draft = EstimateItemDraft(
      name: request.destination == _EstimateDestination.name ? expression : '',
      specification: request.destination == _EstimateDestination.specification
          ? expression
          : '',
      description: request.destination == _EstimateDestination.description
          ? expression
          : '',
      calculationBasis: expression,
    );
    await _sendDraftToEstimate(draft);
    _controller.clearSelection();
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
          persist: false,
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
        onDrawerChanged: (isOpened) {
          if (isOpened) _clearExpressionEditing();
        },
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
                            onPointerDown: _dismissExpressionSelection,
                            onMenuPressed: _showHistoryMenu,
                            onLongPress: _openFullHistory,
                          ),
                        ),
                        const SizedBox(height: sectionGap),
                        SizedBox(
                          height: expressionHeight,
                          child: _ExpressionPanel(
                            controller: _controller,
                            expressionLineKey: _expressionLineKey,
                            onPointerDown: _dismissExpressionSelection,
                            onSelectionMenuAction: _handleSelectionMenuAction,
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

  void _dismissExpressionSelection() {
    if (!_controller.hasSelection) return;
    _expressionLineKey.currentState?.dismissSelectionForExternalTap();
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
    required this.onPointerDown,
    required this.onMenuPressed,
    required this.onLongPress,
    super.key,
  });

  final List<CalculationHistoryEntry> history;
  final VoidCallback onPointerDown;
  final ValueChanged<CalculationHistoryEntry> onMenuPressed;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) => onPointerDown(),
      child: GestureDetector(
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
                      child: CalculatorHistoryLine(
                        key: Key('historyText$index'),
                        expression: item.expression,
                        result: item.result,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
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
  const _ExpressionPanel({
    required this.controller,
    required this.expressionLineKey,
    required this.onPointerDown,
    required this.onSelectionMenuAction,
  });

  final CalculatorController controller;
  final GlobalKey<_EditableExpressionLineState> expressionLineKey;
  final VoidCallback onPointerDown;
  final Future<void> Function(_SelectionMenuAction action)
  onSelectionMenuAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      key: const Key('calculationSpace'),
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
            Expanded(
              child: _EditableExpressionLine(
                key: expressionLineKey,
                controller: controller,
                onSelectionMenuAction: onSelectionMenuAction,
              ),
            ),
            Expanded(
              child: Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: (_) => onPointerDown(),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: _ResultLine(controller: controller),
                ),
              ),
            ),
          ],
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
    if (controller.resultDisplayMode == ResultDisplayMode.remainder) {
      final strings = AppLocalizations.of(context);
      return Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text:
                  '=  ${controller.remainderQuotient}'
                  '${strings.remainderInlineSeparatorBefore}',
            ),
            TextSpan(
              text: strings.remainderInlineWord,
              style: resultStyle?.copyWith(fontSize: 21),
            ),
            TextSpan(text: ' ${controller.remainderValue}'),
          ],
        ),
        key: const Key('resultText'),
        maxLines: 1,
        textAlign: TextAlign.right,
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

enum _SelectionMenuAction { copy, cut, paste, delete, sendToEstimate }

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
    this.selectionOnly = false,
  });

  final String expressionText;
  final String resultText;
  final bool selectionOnly;

  @override
  State<_EstimateTransferSheet> createState() => _EstimateTransferSheetState();
}

class _EstimateTransferSheetState extends State<_EstimateTransferSheet> {
  late _EstimateContent _content = widget.selectionOnly
      ? _EstimateContent.expression
      : _EstimateContent.expressionAndResult;
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
            if (!widget.selectionOnly) ...[
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
            ],
            Text(strings.text('送信先')),
            const SizedBox(height: 8),
            DropdownButtonFormField<_EstimateDestination>(
              key: const Key('estimateDestinationSelector'),
              initialValue: _destination,
              items: [
                for (final destination in _EstimateDestination.values)
                  if (!widget.selectionOnly ||
                      destination != _EstimateDestination.quantity)
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
  const _EditableExpressionLine({
    required this.controller,
    required this.onSelectionMenuAction,
    super.key,
  });

  final CalculatorController controller;
  final Future<void> Function(_SelectionMenuAction action)
  onSelectionMenuAction;
  static const double _expressionFontSize = 54.6;

  @override
  State<_EditableExpressionLine> createState() =>
      _EditableExpressionLineState();
}

enum _ExpressionHitTargetKind {
  text,
  fractionBefore,
  fractionField,
  fractionAfter,
  currentCaret,
}

class _ExpressionHitTarget {
  const _ExpressionHitTarget({
    required this.key,
    required this.lineKey,
    required this.kind,
    this.geometryKey,
    this.text = '',
    this.rawOffsets = const [],
    this.style,
    this.marker,
    this.field,
    this.fieldValue = '',
    this.activeCaretOffset,
    this.fractionCaretInserted = false,
    this.rawOffset,
  });

  final GlobalKey key;
  final GlobalKey? geometryKey;
  final GlobalKey lineKey;
  final _ExpressionHitTargetKind kind;
  final String text;
  final List<int> rawOffsets;
  final TextStyle? style;
  final String? marker;
  final FractionField? field;
  final String fieldValue;
  final int? activeCaretOffset;
  final bool fractionCaretInserted;
  final int? rawOffset;
}

class _ResolvedExpressionPosition {
  const _ResolvedExpressionPosition({
    required this.position,
    required this.caretRect,
    required this.lineBounds,
  });

  final ExpressionPosition position;
  final Rect caretRect;
  final Rect lineBounds;
}

enum _SelectionEndpoint { base, extent }

class _EditableExpressionLineState extends State<_EditableExpressionLine> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _fieldKey = GlobalKey();
  final Map<String, GlobalKey> _targetKeys = {};
  final Map<int, GlobalKey> _lineKeys = {};
  final MagnifierController _magnifierController = MagnifierController();
  final ValueNotifier<MagnifierInfo> _magnifierInfo = ValueNotifier(
    MagnifierInfo.empty,
  );
  List<_ExpressionHitTarget> _hitTargets = const [];
  String _lastExpressionSignature = '';
  OverlayEntry? _selectionHandlesOverlay;
  OverlayEntry? _selectionToolbarOverlay;
  OverlayEntry? _caretToolbarOverlay;
  Rect? _baseSelectionCaretRect;
  Rect? _extentSelectionCaretRect;
  double _baseSelectionDisplayScale = 1;
  double _extentSelectionDisplayScale = 1;
  double _baseSelectionDisplayHeight =
      _EditableExpressionLine._expressionFontSize;
  double _extentSelectionDisplayHeight =
      _EditableExpressionLine._expressionFontSize;
  Rect? _caretToolbarRect;
  bool _selectionToolbarRequested = false;
  bool _caretToolbarRequested = false;
  bool _selectionOverlaySyncScheduled = false;
  bool _selectionHandleDragActive = false;
  _SelectionEndpoint? _activeSelectionEndpoint;
  int? _activeSelectionPointer;
  Offset? _activeSelectionPointerToEndpointDelta;
  ExpressionPosition? _selectionDragAnchor;
  ExpressionPosition? _collapsedDragPosition;
  Duration? _lastPointerDownTime;
  Offset? _lastPointerDownPosition;
  int? _selectionDismissPointer;
  Offset? _selectionDismissStart;
  bool _selectionDismissMoved = false;
  bool _suppressNextExpressionTap = false;
  Timer? _tapSuppressionTimer;

  @override
  void dispose() {
    _selectionHandlesOverlay?.remove();
    _selectionHandlesOverlay = null;
    _selectionToolbarOverlay?.remove();
    _selectionToolbarOverlay = null;
    _caretToolbarOverlay?.remove();
    _caretToolbarOverlay = null;
    _tapSuppressionTimer?.cancel();
    unawaited(_magnifierController.hide().whenComplete(_magnifierInfo.dispose));
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = DefaultTextStyle.of(context).style.copyWith(
      color: theme.colorScheme.onSurface,
      fontSize: _EditableExpressionLine._expressionFontSize,
      fontWeight: FontWeight.w400,
    );
    final segments = widget.controller.displaySegments;
    final hitTargets = <_ExpressionHitTarget>[];
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
        _hitTargets = hitTargets;
        _scheduleSelectionOverlaySync();
        return Listener(
          key: _fieldKey,
          behavior: HitTestBehavior.opaque,
          onPointerDown: _handleExpressionPointerDown,
          onPointerMove: _handleExpressionPointerMove,
          onPointerUp: _handleExpressionPointerUp,
          onPointerCancel: (event) {
            _cancelSelectionDismiss(event.pointer);
            _clearPendingDoubleTap();
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: _handleExpressionBackgroundTap,
            onLongPressStart: _startCaretDrag,
            onLongPressMoveUpdate: _updateCaretDrag,
            onLongPressEnd: _endCaretDrag,
            onLongPressCancel: _cancelCaretDrag,
            child: ClipRect(
              child: NotificationListener<ScrollNotification>(
                onNotification: _handleExpressionScroll,
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
                        for (
                          var lineIndex = 0;
                          lineIndex < lines.length;
                          lineIndex++
                        )
                          KeyedSubtree(
                            key: Key('expressionLine-$lineIndex'),
                            child: SizedBox(
                              key: _lineKeys.putIfAbsent(
                                lineIndex,
                                () => GlobalKey(
                                  debugLabel: 'expressionLine-$lineIndex',
                                ),
                              ),
                              height: lineHeight,
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: FittedBox(
                                  key: Key('expressionLineScale-$lineIndex'),
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerRight,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      for (
                                        var segmentIndex = 0;
                                        segmentIndex < lines[lineIndex].length;
                                        segmentIndex++
                                      )
                                        _buildSegment(
                                          lines[lineIndex][segmentIndex],
                                          style,
                                          lineIndex,
                                          segmentIndex,
                                          hitTargets,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSegment(
    ExpressionDisplaySegment segment,
    TextStyle style,
    int lineIndex,
    int segmentIndex,
    List<_ExpressionHitTarget> hitTargets,
  ) {
    final lineKey = _lineKeys.putIfAbsent(
      lineIndex,
      () => GlobalKey(debugLabel: 'expressionLine-$lineIndex'),
    );
    return switch (segment) {
      ExpressionTextSegment() => _buildTextSegment(
        segment,
        style,
        lineKey,
        lineIndex,
        segmentIndex,
        hitTargets,
      ),
      ExpressionCaretSegment() => _buildCaretSegment(
        lineKey,
        lineIndex,
        segmentIndex,
        hitTargets,
      ),
      ExpressionFractionSegment() => _buildFractionSegment(
        segment,
        style,
        lineKey,
        lineIndex,
        segmentIndex,
        hitTargets,
      ),
      ExpressionLineBreakSegment() => const SizedBox.shrink(),
    };
  }

  Widget _buildTextSegment(
    ExpressionTextSegment segment,
    TextStyle style,
    GlobalKey lineKey,
    int lineIndex,
    int segmentIndex,
    List<_ExpressionHitTarget> hitTargets,
  ) {
    final key = _targetKey('text-$lineIndex-$segmentIndex');
    hitTargets.add(
      _ExpressionHitTarget(
        key: key,
        lineKey: lineKey,
        kind: _ExpressionHitTargetKind.text,
        text: segment.text,
        rawOffsets: segment.rawOffsets,
        style: style,
      ),
    );
    return _EditableExpressionText(
      gestureKey: key,
      segment: segment,
      style: style,
      selectedRawRange: _selectedRawRange,
      onRawOffsetTap: (offset) {
        if (_consumeSuppressedTap()) return;
        if (_showSelectionToolbarForTap(RawExpressionPosition(offset))) {
          return;
        }
        _hideEditingToolbars();
        widget.controller.moveCaretToRawOffset(offset);
      },
    );
  }

  Widget _buildCaretSegment(
    GlobalKey lineKey,
    int lineIndex,
    int segmentIndex,
    List<_ExpressionHitTarget> hitTargets,
  ) {
    final key = _targetKey('caret-$lineIndex-$segmentIndex');
    hitTargets.add(
      _ExpressionHitTarget(
        key: key,
        lineKey: lineKey,
        kind: _ExpressionHitTargetKind.currentCaret,
        rawOffset: widget.controller.caretPosition,
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: SizedBox(
        key: key,
        width: 2,
        height: 46,
        child: const ColoredBox(
          key: Key('calculatorCaret'),
          color: AppColors.accent,
        ),
      ),
    );
  }

  Widget _buildFractionSegment(
    ExpressionFractionSegment segment,
    TextStyle expressionStyle,
    GlobalKey lineKey,
    int lineIndex,
    int segmentIndex,
    List<_ExpressionHitTarget> hitTargets,
  ) {
    final prefix =
        'fraction-$lineIndex-$segmentIndex-${segment.marker.codeUnitAt(0)}';
    final beforeKey = _targetKey('$prefix-before');
    final afterKey = _targetKey('$prefix-after');
    final wholeKey = _targetKey('$prefix-whole');
    final numeratorKey = _targetKey('$prefix-numerator');
    final denominatorKey = _targetKey('$prefix-denominator');
    final wholeGeometryKey = _targetKey('$prefix-whole-geometry');
    final numeratorGeometryKey = _targetKey('$prefix-numerator-geometry');
    final denominatorGeometryKey = _targetKey('$prefix-denominator-geometry');
    hitTargets
      ..add(
        _ExpressionHitTarget(
          key: beforeKey,
          lineKey: lineKey,
          kind: _ExpressionHitTargetKind.fractionBefore,
          marker: segment.marker,
        ),
      )
      ..add(
        _ExpressionHitTarget(
          key: numeratorKey,
          geometryKey: numeratorGeometryKey,
          lineKey: lineKey,
          kind: _ExpressionHitTargetKind.fractionField,
          marker: segment.marker,
          field: FractionField.numerator,
          fieldValue: segment.numerator,
          activeCaretOffset: segment.activeField == FractionField.numerator
              ? segment.activeCaretOffset
              : null,
          fractionCaretInserted:
              segment.activeField == FractionField.numerator &&
              _fractionFieldSelection(
                    segment.marker,
                    FractionField.numerator,
                  ) ==
                  null,
          style: _fractionTextStyle(context, expressionStyle),
        ),
      )
      ..add(
        _ExpressionHitTarget(
          key: denominatorKey,
          geometryKey: denominatorGeometryKey,
          lineKey: lineKey,
          kind: _ExpressionHitTargetKind.fractionField,
          marker: segment.marker,
          field: FractionField.denominator,
          fieldValue: segment.denominator,
          activeCaretOffset: segment.activeField == FractionField.denominator
              ? segment.activeCaretOffset
              : null,
          fractionCaretInserted:
              segment.activeField == FractionField.denominator &&
              _fractionFieldSelection(
                    segment.marker,
                    FractionField.denominator,
                  ) ==
                  null,
          style: _fractionTextStyle(context, expressionStyle),
        ),
      )
      ..add(
        _ExpressionHitTarget(
          key: afterKey,
          lineKey: lineKey,
          kind: _ExpressionHitTargetKind.fractionAfter,
          marker: segment.marker,
        ),
      );
    if (segment.wholeNumber.isNotEmpty) {
      hitTargets.add(
        _ExpressionHitTarget(
          key: wholeKey,
          geometryKey: wholeGeometryKey,
          lineKey: lineKey,
          kind: _ExpressionHitTargetKind.fractionField,
          marker: segment.marker,
          field: FractionField.wholeNumber,
          fieldValue: segment.wholeNumber,
          activeCaretOffset: segment.activeField == FractionField.wholeNumber
              ? segment.activeCaretOffset
              : null,
          fractionCaretInserted:
              segment.activeField == FractionField.wholeNumber &&
              _fractionFieldSelection(
                    segment.marker,
                    FractionField.wholeNumber,
                  ) ==
                  null,
          style: _fractionTextStyle(context, expressionStyle),
        ),
      );
    }
    return _InlineFraction(
      segment: segment,
      fontSize: _EditableExpressionLine._expressionFontSize,
      textStyle: _fractionTextStyle(context, expressionStyle),
      fullySelected: _isFractionFullySelected(segment.marker),
      wholeNumberSelection: _fractionFieldSelection(
        segment.marker,
        FractionField.wholeNumber,
      ),
      numeratorSelection: _fractionFieldSelection(
        segment.marker,
        FractionField.numerator,
      ),
      denominatorSelection: _fractionFieldSelection(
        segment.marker,
        FractionField.denominator,
      ),
      beforeKey: beforeKey,
      afterKey: afterKey,
      wholeNumberKey: wholeKey,
      numeratorKey: numeratorKey,
      denominatorKey: denominatorKey,
      wholeNumberGeometryKey: wholeGeometryKey,
      numeratorGeometryKey: numeratorGeometryKey,
      denominatorGeometryKey: denominatorGeometryKey,
      onBeforeFractionTap: () {
        if (_consumeSuppressedTap()) return;
        final position = RawExpressionPosition(
          widget.controller.expression.indexOf(segment.marker),
        );
        if (_showSelectionToolbarForTap(position)) return;
        _hideEditingToolbars();
        widget.controller.moveCaretBeforeFraction(segment.marker);
      },
      onAfterFractionTap: () {
        if (_consumeSuppressedTap()) return;
        final position = RawExpressionPosition(
          widget.controller.expression.indexOf(segment.marker) + 1,
        );
        if (_showSelectionToolbarForTap(position)) return;
        _hideEditingToolbars();
        widget.controller.moveCaretAfterFraction(segment.marker);
      },
      onFieldTap: (field, caretOffset) {
        if (_consumeSuppressedTap()) return;
        final position = FractionExpressionPosition(
          marker: segment.marker,
          field: field,
          offset: caretOffset,
        );
        if (_showSelectionToolbarForTap(position)) return;
        _hideEditingToolbars();
        widget.controller.activateFraction(
          segment.marker,
          field,
          caretOffset: caretOffset,
        );
      },
    );
  }

  TextStyle _fractionTextStyle(
    BuildContext context,
    TextStyle expressionStyle,
  ) => expressionStyle.copyWith(
    color: Theme.of(context).colorScheme.onSurface,
    height: 1,
  );

  (int, int)? get _selectedRawRange {
    final selection = widget.controller.selection;
    if (selection == null ||
        selection.base is! RawExpressionPosition ||
        selection.extent is! RawExpressionPosition) {
      return null;
    }
    final base = (selection.base as RawExpressionPosition).offset;
    final extent = (selection.extent as RawExpressionPosition).offset;
    return (math.min(base, extent), math.max(base, extent));
  }

  TextRange? _fractionFieldSelection(String marker, FractionField field) {
    final selection = widget.controller.selection;
    if (selection == null ||
        selection.base is! FractionExpressionPosition ||
        selection.extent is! FractionExpressionPosition) {
      return null;
    }
    final base = selection.base as FractionExpressionPosition;
    final extent = selection.extent as FractionExpressionPosition;
    if (base.marker != marker || extent.marker != marker) {
      return null;
    }
    if (base.field != extent.field) {
      final numeratorPosition = base.field == FractionField.numerator
          ? base
          : extent.field == FractionField.numerator
          ? extent
          : null;
      final denominatorPosition = base.field == FractionField.denominator
          ? base
          : extent.field == FractionField.denominator
          ? extent
          : null;
      if (numeratorPosition == null || denominatorPosition == null) return null;
      final fraction = widget.controller.fractionInputForDisplay(marker);
      if (fraction == null) return null;
      return switch (field) {
        FractionField.numerator => TextRange(
          start: numeratorPosition.offset,
          end: fraction.numeratorText.length,
        ),
        FractionField.denominator => TextRange(
          start: 0,
          end: denominatorPosition.offset,
        ),
        FractionField.wholeNumber => null,
      };
    }
    if (base.field != field) return null;
    return TextRange(
      start: math.min(base.offset, extent.offset),
      end: math.max(base.offset, extent.offset),
    );
  }

  bool _isFractionFullySelected(String marker) {
    final range = _selectedRawRange;
    if (range == null) return false;
    final index = widget.controller.expression.indexOf(marker);
    return index >= range.$1 && index < range.$2;
  }

  GlobalKey _targetKey(String id) => _targetKeys.putIfAbsent(
    id,
    () => GlobalKey(debugLabel: 'expressionTarget-$id'),
  );

  void _handleExpressionPointerDown(PointerDownEvent event) {
    if (widget.controller.hasSelection) {
      _selectionDismissPointer = event.pointer;
      _selectionDismissStart = event.position;
      _selectionDismissMoved = false;
      return;
    }
    final previousTime = _lastPointerDownTime;
    final previousPosition = _lastPointerDownPosition;
    _lastPointerDownTime = event.timeStamp;
    _lastPointerDownPosition = event.position;
    if (previousTime == null || previousPosition == null) return;
    final elapsed = event.timeStamp - previousTime;
    if (elapsed > const Duration(milliseconds: 300) ||
        (event.position - previousPosition).distance > 24) {
      return;
    }
    _lastPointerDownTime = null;
    _lastPointerDownPosition = null;
    _suppressNextExpressionTap = true;
    _handleDoubleTapAt(event.position);
    _tapSuppressionTimer?.cancel();
    _tapSuppressionTimer = Timer(const Duration(milliseconds: 400), () {
      _suppressNextExpressionTap = false;
    });
  }

  void _handleExpressionPointerMove(PointerMoveEvent event) {
    if (_selectionDismissPointer == event.pointer) {
      final start = _selectionDismissStart;
      if (start != null && (event.position - start).distance > 8) {
        _selectionDismissMoved = true;
      }
      return;
    }
    final previousPosition = _lastPointerDownPosition;
    if (previousPosition != null &&
        (event.position - previousPosition).distance > 24) {
      _clearPendingDoubleTap();
    }
  }

  void _handleExpressionPointerUp(PointerUpEvent event) {
    if (_selectionDismissPointer != event.pointer) return;
    final shouldDismiss =
        !_selectionDismissMoved &&
        _activeSelectionPointer != event.pointer &&
        widget.controller.hasSelection;
    _cancelSelectionDismiss(event.pointer);
    if (shouldDismiss) dismissSelectionForExternalTap();
  }

  void _cancelSelectionDismiss(int pointer) {
    if (_selectionDismissPointer != pointer) return;
    _selectionDismissPointer = null;
    _selectionDismissStart = null;
    _selectionDismissMoved = false;
  }

  void _handleExpressionBackgroundTap(TapUpDetails details) {
    if (_consumeSuppressedTap()) return;
    if (widget.controller.hasSelection &&
        !_hitTargetContains(details.globalPosition)) {
      _hideEditingToolbars();
      widget.controller.clearSelection();
      return;
    }
    final resolved = _resolvePosition(details.globalPosition);
    _hideEditingToolbars();
    if (resolved != null) {
      widget.controller.moveCaretToPosition(resolved.position);
    } else if (widget.controller.hasSelection) {
      widget.controller.clearSelection();
    }
  }

  bool _hitTargetContains(Offset globalPosition) {
    for (final target in _hitTargets) {
      if (target.kind == _ExpressionHitTargetKind.fractionBefore ||
          target.kind == _ExpressionHitTargetKind.fractionAfter) {
        continue;
      }
      final box = _coordinateBoxForTarget(target);
      if (box == null || !box.hasSize) continue;
      final rect = box.localToGlobal(Offset.zero) & box.size;
      if (rect.contains(globalPosition)) return true;
    }
    return false;
  }

  void clearTransientEditing() {
    _clearPendingDoubleTap();
    _suppressNextExpressionTap = false;
    _tapSuppressionTimer?.cancel();
    _tapSuppressionTimer = null;
    _selectionHandleDragActive = false;
    _activeSelectionEndpoint = null;
    _activeSelectionPointer = null;
    _activeSelectionPointerToEndpointDelta = null;
    _selectionDragAnchor = null;
    _collapsedDragPosition = null;
    _selectionDismissPointer = null;
    _selectionDismissStart = null;
    _selectionDismissMoved = false;
    _hideEditingToolbars();
    _selectionHandlesOverlay?.remove();
    _selectionHandlesOverlay = null;
    if (widget.controller.hasSelection) widget.controller.clearSelection();
    unawaited(_magnifierController.hide());
  }

  void dismissSelectionForExternalTap() {
    if (!widget.controller.hasSelection) return;
    _clearPendingDoubleTap();
    _suppressNextExpressionTap = true;
    _tapSuppressionTimer?.cancel();
    _tapSuppressionTimer = Timer(const Duration(milliseconds: 400), () {
      _suppressNextExpressionTap = false;
    });
    _hideEditingToolbars();
    _selectionHandlesOverlay?.remove();
    _selectionHandlesOverlay = null;
    widget.controller.clearSelection();
  }

  void _showSelectionToolbar() {
    _caretToolbarRequested = false;
    _removeCaretToolbar();
    _selectionToolbarRequested = true;
    _syncSelectionHandlesOverlay();
  }

  void _clearPendingDoubleTap() {
    _lastPointerDownTime = null;
    _lastPointerDownPosition = null;
  }

  bool _consumeSuppressedTap() {
    if (!_suppressNextExpressionTap) return false;
    _suppressNextExpressionTap = false;
    _tapSuppressionTimer?.cancel();
    _tapSuppressionTimer = null;
    return true;
  }

  void _handleDoubleTapAt(Offset globalPosition) {
    final target = _closestHitTarget(globalPosition);
    final resolved = target == null
        ? null
        : _resolveTarget(target, globalPosition);
    if (target == null || resolved == null) return;
    final targetBox =
        target.key.currentContext?.findRenderObject() as RenderBox?;
    if (targetBox == null || !targetBox.hasSize) return;
    final targetRect = targetBox.localToGlobal(Offset.zero) & targetBox.size;
    if (!targetRect.contains(globalPosition)) {
      _hideEditingToolbars();
      widget.controller.moveCaretToPosition(resolved.position);
      return;
    }
    if (target.kind == _ExpressionHitTargetKind.text) {
      final index = _characterIndexAt(target, globalPosition);
      if (index != null && index < target.text.length) {
        final rawIndex = target.rawOffsets[index];
        if (rawIndex < widget.controller.expression.length &&
            _isSelectableNumberCharacter(
              widget.controller.expression[rawIndex],
            )) {
          final expression = widget.controller.expression;
          var start = rawIndex;
          var end = rawIndex + 1;
          while (start > 0 &&
              _isSelectableNumberCharacter(expression[start - 1])) {
            start--;
          }
          while (end < expression.length &&
              _isSelectableNumberCharacter(expression[end])) {
            end++;
          }
          _caretToolbarRequested = false;
          _removeCaretToolbar();
          _selectionToolbarRequested = true;
          widget.controller.selectRange(
            RawExpressionPosition(start),
            RawExpressionPosition(end),
          );
          return;
        }
      }
    } else if (target.kind == _ExpressionHitTargetKind.fractionField) {
      final index = _characterIndexAt(target, globalPosition);
      final value = target.fieldValue;
      if (index != null &&
          index < value.length &&
          _isSelectableNumberCharacter(value[index])) {
        var start = index;
        var end = index + 1;
        while (start > 0 && _isSelectableNumberCharacter(value[start - 1])) {
          start--;
        }
        while (end < value.length && _isSelectableNumberCharacter(value[end])) {
          end++;
        }
        _caretToolbarRequested = false;
        _removeCaretToolbar();
        _selectionToolbarRequested = true;
        widget.controller.selectRange(
          FractionExpressionPosition(
            marker: target.marker!,
            field: target.field!,
            offset: start,
          ),
          FractionExpressionPosition(
            marker: target.marker!,
            field: target.field!,
            offset: end,
          ),
        );
        return;
      }
    }
    _hideEditingToolbars();
    widget.controller.moveCaretToPosition(resolved.position);
    _caretToolbarRequested = true;
    _scheduleSelectionOverlaySync();
  }

  bool _isSelectableNumberCharacter(String value) =>
      value.length == 1 &&
      ((value.codeUnitAt(0) >= 48 && value.codeUnitAt(0) <= 57) ||
          value == '.');

  int? _characterIndexAt(_ExpressionHitTarget target, Offset globalPosition) {
    final box = _coordinateBoxForTarget(target);
    final style = target.style;
    final text = target.kind == _ExpressionHitTargetKind.text
        ? target.text
        : target.fieldValue;
    if (box == null || !box.hasSize || style == null || text.isEmpty) {
      return null;
    }
    final local = box.globalToLocal(globalPosition);
    if (target.kind == _ExpressionHitTargetKind.fractionField &&
        box is RenderParagraph) {
      return box.getPositionForOffset(local).offset.clamp(0, text.length - 1);
    }
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final textX = local.dx;
    for (var index = 0; index < text.length; index++) {
      final boxes = painter.getBoxesForSelection(
        TextSelection(baseOffset: index, extentOffset: index + 1),
      );
      if (boxes.any((box) => textX >= box.left && textX <= box.right)) {
        return index;
      }
    }
    return null;
  }

  bool _showSelectionToolbarForTap(ExpressionPosition position) {
    final selection = widget.controller.selection;
    if (selection == null || !_selectionContainsPosition(selection, position)) {
      return false;
    }
    _showSelectionToolbar();
    return true;
  }

  bool _selectionContainsPosition(
    ExpressionSelection selection,
    ExpressionPosition position,
  ) {
    final base = selection.base;
    final extent = selection.extent;
    if (base is RawExpressionPosition && extent is RawExpressionPosition) {
      final start = math.min(base.offset, extent.offset);
      final end = math.max(base.offset, extent.offset);
      if (position is RawExpressionPosition) {
        return position.offset >= start && position.offset <= end;
      }
      if (position is FractionExpressionPosition) {
        final markerOffset = widget.controller.expression.indexOf(
          position.marker,
        );
        return markerOffset >= start && markerOffset < end;
      }
      return false;
    }
    if (base is FractionExpressionPosition &&
        extent is FractionExpressionPosition &&
        position is FractionExpressionPosition &&
        base.marker == extent.marker &&
        base.marker == position.marker &&
        base.marker == position.marker) {
      if (base.field == extent.field && base.field == position.field) {
        final start = math.min(base.offset, extent.offset);
        final end = math.max(base.offset, extent.offset);
        return position.offset >= start && position.offset <= end;
      }
      final numeratorPosition = base.field == FractionField.numerator
          ? base
          : extent.field == FractionField.numerator
          ? extent
          : null;
      final denominatorPosition = base.field == FractionField.denominator
          ? base
          : extent.field == FractionField.denominator
          ? extent
          : null;
      if (numeratorPosition == null || denominatorPosition == null) {
        return false;
      }
      if (position.field == FractionField.numerator) {
        return position.offset >= numeratorPosition.offset;
      }
      if (position.field == FractionField.denominator) {
        return position.offset <= denominatorPosition.offset;
      }
    }
    return false;
  }

  Rect? get _expressionViewportRect {
    final box = _fieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  bool _caretIsVisible(Rect rect) {
    final viewport = _expressionViewportRect;
    if (viewport == null) return false;
    final center = rect.center;
    return center.dx >= viewport.left &&
        center.dx <= viewport.right &&
        center.dy >= viewport.top &&
        center.dy <= viewport.bottom;
  }

  Rect _toolbarAnchorRect(Rect rect) {
    final viewport = _expressionViewportRect;
    if (viewport == null) return rect;
    final center = Offset(
      rect.center.dx.clamp(viewport.left, viewport.right),
      rect.center.dy.clamp(viewport.top, viewport.bottom),
    );
    return Rect.fromCenter(
      center: center,
      width: rect.width,
      height: math.min(rect.height, viewport.height),
    );
  }

  void _syncSelectionHandlesOverlay() {
    final selection = widget.controller.selection;
    if (selection == null) {
      _selectionHandlesOverlay?.remove();
      _selectionHandlesOverlay = null;
      _baseSelectionCaretRect = null;
      _extentSelectionCaretRect = null;
      _selectionToolbarRequested = false;
      _removeSelectionToolbar();
      return;
    }
    final baseRect = _caretRectForPosition(selection.base);
    final extentRect = _caretRectForPosition(selection.extent);
    if (baseRect == null || extentRect == null) {
      _selectionHandlesOverlay?.remove();
      _selectionHandlesOverlay = null;
      _baseSelectionCaretRect = null;
      _extentSelectionCaretRect = null;
      _selectionToolbarRequested = false;
      _removeSelectionToolbar();
      return;
    }
    final baseMetrics = _displayMetricsForPosition(selection.base);
    final extentMetrics = _displayMetricsForPosition(selection.extent);
    final handlesMoved =
        _baseSelectionCaretRect != baseRect ||
        _extentSelectionCaretRect != extentRect ||
        _baseSelectionDisplayScale != baseMetrics.scale ||
        _extentSelectionDisplayScale != extentMetrics.scale ||
        _baseSelectionDisplayHeight != baseMetrics.height ||
        _extentSelectionDisplayHeight != extentMetrics.height;
    _baseSelectionCaretRect = baseRect;
    _extentSelectionCaretRect = extentRect;
    _baseSelectionDisplayScale = baseMetrics.scale;
    _extentSelectionDisplayScale = extentMetrics.scale;
    _baseSelectionDisplayHeight = baseMetrics.height;
    _extentSelectionDisplayHeight = extentMetrics.height;
    final overlay = Overlay.of(context, rootOverlay: true);
    _selectionHandlesOverlay ??= OverlayEntry(
      builder: _buildSelectionHandlesOverlay,
    );
    if (!_selectionHandlesOverlay!.mounted) {
      overlay.insert(_selectionHandlesOverlay!);
    } else if (handlesMoved) {
      _selectionHandlesOverlay!.markNeedsBuild();
    }
    if (_selectionToolbarRequested && !_selectionHandleDragActive) {
      _selectionToolbarOverlay ??= OverlayEntry(
        builder: _buildSelectionToolbarOverlay,
      );
      if (!_selectionToolbarOverlay!.mounted) {
        overlay.insert(
          _selectionToolbarOverlay!,
          below: _selectionHandlesOverlay,
        );
      } else if (handlesMoved) {
        _selectionToolbarOverlay!.markNeedsBuild();
      }
    } else {
      _removeSelectionToolbar();
    }
  }

  void _scheduleSelectionOverlaySync() {
    if (_selectionOverlaySyncScheduled) return;
    _selectionOverlaySyncScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _selectionOverlaySyncScheduled = false;
      if (!mounted) return;
      _syncSelectionHandlesOverlay();
      _syncCaretToolbarOverlay();
    });
  }

  void _syncCaretToolbarOverlay() {
    if (!_caretToolbarRequested || widget.controller.hasSelection) {
      _removeCaretToolbar();
      return;
    }
    final caretRect = _caretRectForPosition(
      widget.controller.expressionPosition,
    );
    if (caretRect == null) {
      _removeCaretToolbar();
      return;
    }
    final moved = _caretToolbarRect != caretRect;
    _caretToolbarRect = caretRect;
    final overlay = Overlay.of(context, rootOverlay: true);
    _caretToolbarOverlay ??= OverlayEntry(builder: _buildCaretToolbarOverlay);
    if (!_caretToolbarOverlay!.mounted) {
      overlay.insert(_caretToolbarOverlay!);
    } else if (moved) {
      _caretToolbarOverlay!.markNeedsBuild();
    }
  }

  void _removeSelectionToolbar() {
    _selectionToolbarOverlay?.remove();
    _selectionToolbarOverlay = null;
  }

  void _removeCaretToolbar() {
    _caretToolbarOverlay?.remove();
    _caretToolbarOverlay = null;
    _caretToolbarRect = null;
  }

  void _hideEditingToolbars() {
    _selectionToolbarRequested = false;
    _caretToolbarRequested = false;
    _removeSelectionToolbar();
    _removeCaretToolbar();
  }

  Widget _buildCaretToolbarOverlay(BuildContext overlayContext) {
    final caretRect = _caretToolbarRect;
    if (caretRect == null) return const SizedBox.shrink();
    final strings = AppLocalizations.of(overlayContext);
    return KeyedSubtree(
      key: const Key('calculatorCaretToolbar'),
      child: AdaptiveTextSelectionToolbar.buttonItems(
        anchors: TextSelectionToolbarAnchors(
          primaryAnchor: caretRect.topCenter,
          secondaryAnchor: caretRect.bottomCenter,
        ),
        buttonItems: [
          ContextMenuButtonItem(
            label: strings.text('選択'),
            onPressed: _selectNumberFromCaretToolbar,
          ),
          ContextMenuButtonItem(
            type: ContextMenuButtonType.selectAll,
            label: MaterialLocalizations.of(
              overlayContext,
            ).selectAllButtonLabel,
            onPressed: _selectAllFromCaretToolbar,
          ),
          ContextMenuButtonItem(
            type: ContextMenuButtonType.paste,
            label: strings.text('ペースト'),
            onPressed: () => unawaited(_pasteAtCaretFromToolbar()),
          ),
        ],
      ),
    );
  }

  Future<void> _pasteAtCaretFromToolbar() async {
    _caretToolbarRequested = false;
    _removeCaretToolbar();
    await widget.onSelectionMenuAction(_SelectionMenuAction.paste);
  }

  void _selectNumberFromCaretToolbar() {
    _caretToolbarRequested = false;
    _removeCaretToolbar();
    if (!widget.controller.selectNumberNearCaret()) return;
    _selectionToolbarRequested = true;
    _scheduleSelectionOverlaySync();
  }

  void _selectAllFromCaretToolbar() {
    _caretToolbarRequested = false;
    _removeCaretToolbar();
    if (!widget.controller.selectAllExpression()) return;
    _selectionToolbarRequested = true;
    _scheduleSelectionOverlaySync();
  }

  Widget _buildSelectionToolbarOverlay(BuildContext overlayContext) {
    final baseRect = _baseSelectionCaretRect;
    final extentRect = _extentSelectionCaretRect;
    if (baseRect == null || extentRect == null) {
      return const SizedBox.shrink();
    }
    final anchoredBase = _toolbarAnchorRect(baseRect);
    final anchoredExtent = _toolbarAnchorRect(extentRect);
    final top = math.min(anchoredBase.top, anchoredExtent.top);
    final bottom = math.max(anchoredBase.bottom, anchoredExtent.bottom);
    final centerX = (anchoredBase.center.dx + anchoredExtent.center.dx) / 2;
    final strings = AppLocalizations.of(overlayContext);
    return KeyedSubtree(
      key: const Key('calculatorSelectionToolbar'),
      child: AdaptiveTextSelectionToolbar.buttonItems(
        anchors: TextSelectionToolbarAnchors(
          primaryAnchor: Offset(centerX, top),
          secondaryAnchor: Offset(centerX, bottom),
        ),
        buttonItems: [
          ContextMenuButtonItem(
            type: ContextMenuButtonType.copy,
            label: strings.text('コピー'),
            onPressed: () =>
                unawaited(_invokeSelectionAction(_SelectionMenuAction.copy)),
          ),
          ContextMenuButtonItem(
            type: ContextMenuButtonType.cut,
            label: strings.text('カット'),
            onPressed: () =>
                unawaited(_invokeSelectionAction(_SelectionMenuAction.cut)),
          ),
          ContextMenuButtonItem(
            type: ContextMenuButtonType.paste,
            label: strings.text('ペースト'),
            onPressed: () =>
                unawaited(_invokeSelectionAction(_SelectionMenuAction.paste)),
          ),
          ContextMenuButtonItem(
            type: ContextMenuButtonType.delete,
            label: strings.text('消去'),
            onPressed: () =>
                unawaited(_invokeSelectionAction(_SelectionMenuAction.delete)),
          ),
          ContextMenuButtonItem(
            label: strings.text('見積へ送る'),
            onPressed: () => unawaited(
              _invokeSelectionAction(_SelectionMenuAction.sendToEstimate),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _invokeSelectionAction(_SelectionMenuAction action) async {
    if (action != _SelectionMenuAction.copy) {
      _selectionToolbarRequested = false;
      _removeSelectionToolbar();
    }
    if (action == _SelectionMenuAction.sendToEstimate) {
      _selectionHandlesOverlay?.remove();
      _selectionHandlesOverlay = null;
    }
    await widget.onSelectionMenuAction(action);
    if (!mounted || !widget.controller.hasSelection) return;
    if (action != _SelectionMenuAction.copy) {
      _selectionToolbarRequested = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _syncSelectionHandlesOverlay();
      });
    }
  }

  Widget _buildSelectionHandlesOverlay(BuildContext overlayContext) {
    final baseRect = _baseSelectionCaretRect;
    final extentRect = _extentSelectionCaretRect;
    if (baseRect == null || extentRect == null) return const SizedBox.shrink();
    final baseBeforeExtent =
        baseRect.top < extentRect.top - 1 ||
        ((baseRect.top - extentRect.top).abs() <= 1 &&
            baseRect.left <= extentRect.left);
    final baseVisible = _caretIsVisible(baseRect);
    final extentVisible = _caretIsVisible(extentRect);
    return Stack(
      children: [
        if (baseVisible)
          _buildSelectionHandle(
            overlayContext,
            key: const Key('calculatorSelectionBaseHandle'),
            endpoint: baseRect.bottomCenter,
            otherEndpoint: extentRect.bottomCenter,
            type: baseBeforeExtent
                ? TextSelectionHandleType.left
                : TextSelectionHandleType.right,
            endpointRole: _SelectionEndpoint.base,
            displayScale: _baseSelectionDisplayScale,
            displayHeight: _baseSelectionDisplayHeight,
          ),
        if (extentVisible)
          _buildSelectionHandle(
            overlayContext,
            key: const Key('calculatorSelectionExtentHandle'),
            endpoint: extentRect.bottomCenter,
            otherEndpoint: baseRect.bottomCenter,
            type: baseBeforeExtent
                ? TextSelectionHandleType.right
                : TextSelectionHandleType.left,
            endpointRole: _SelectionEndpoint.extent,
            displayScale: _extentSelectionDisplayScale,
            displayHeight: _extentSelectionDisplayHeight,
          ),
      ],
    );
  }

  Widget _buildSelectionHandle(
    BuildContext overlayContext, {
    required Key key,
    required Offset endpoint,
    required Offset otherEndpoint,
    required TextSelectionHandleType type,
    required _SelectionEndpoint endpointRole,
    required double displayScale,
    required double displayHeight,
  }) {
    const touchSize = 48.0;
    final safeScale = displayScale.isFinite && displayScale > 0
        ? displayScale
        : 1.0;
    final lineHeight = displayHeight / safeScale;
    final screen = MediaQuery.sizeOf(overlayContext);
    final controls = Theme.of(overlayContext).platform == TargetPlatform.iOS
        ? cupertinoTextSelectionControls
        : materialTextSelectionControls;
    const hitLineHeight = _EditableExpressionLine._expressionFontSize;
    final hitAnchor = controls.getHandleAnchor(type, hitLineHeight);
    final hitHandleSize = controls.getHandleSize(hitLineHeight);
    final unscaledAnchor = controls.getHandleAnchor(type, lineHeight);
    final anchor = unscaledAnchor * safeScale;
    final handleSize = controls.getHandleSize(lineHeight) * safeScale;
    final hitVisualRect = Rect.fromLTWH(
      endpoint.dx - hitAnchor.dx,
      endpoint.dy - hitAnchor.dy,
      hitHandleSize.width,
      hitHandleSize.height,
    );
    // Match Flutter's selection-handle geometry: the interactive rectangle
    // encloses the actual platform handle and is expanded to the Material
    // minimum touch target. Cupertino's left handle circle sits at the top of
    // this tall visual rectangle, while the right handle is rotated; a square
    // centered only on [endpoint] therefore misses the visible left circle.
    final visualRect = Rect.fromLTWH(
      endpoint.dx - anchor.dx,
      endpoint.dy - anchor.dy,
      handleSize.width,
      handleSize.height,
    );
    final interactiveRect = hitVisualRect
        .expandToInclude(
          Rect.fromCircle(center: hitVisualRect.center, radius: touchSize / 2),
        )
        .expandToInclude(visualRect);
    var desiredLeft = interactiveRect.left;
    var desiredRight = interactiveRect.right;
    if ((endpoint.dy - otherEndpoint.dy).abs() < touchSize) {
      final midpoint = (endpoint.dx + otherEndpoint.dx) / 2;
      if (endpoint.dx < otherEndpoint.dx) {
        desiredRight = math.min(desiredRight, midpoint);
      } else if (endpoint.dx > otherEndpoint.dx) {
        desiredLeft = math.max(desiredLeft, midpoint);
      }
    }
    final left = desiredLeft
        .clamp(0.0, math.max(0.0, screen.width - 1))
        .toDouble();
    final right = desiredRight.clamp(left + 1, screen.width).toDouble();
    final top = interactiveRect.top.clamp(0.0, screen.height - 1).toDouble();
    final bottom = interactiveRect.bottom
        .clamp(top + 1, screen.height)
        .toDouble();
    final handle = controls.buildHandle(overlayContext, type, lineHeight);
    return Positioned(
      left: left,
      top: top,
      width: right - left,
      height: bottom - top,
      child: Listener(
        key: key,
        behavior: HitTestBehavior.opaque,
        onPointerDown: (event) => _startSelectionHandleDrag(
          endpointRole,
          event.pointer,
          pointerPosition: event.position,
          endpointPosition: endpoint,
        ),
        onPointerMove: (event) =>
            _updateSelectionHandleDrag(event.pointer, event.position),
        onPointerUp: (event) {
          _updateSelectionHandleDrag(event.pointer, event.position);
          _finishSelectionHandleDrag(event.pointer);
        },
        onPointerCancel: (event) => _finishSelectionHandleDrag(event.pointer),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: endpoint.dx - left,
              top: endpoint.dy - top,
              child: SizedBox(
                key: ValueKey(
                  endpointRole == _SelectionEndpoint.base
                      ? 'calculatorSelectionBaseHandleAnchor'
                      : 'calculatorSelectionExtentHandleAnchor',
                ),
              ),
            ),
            Positioned(
              left: endpoint.dx - left - anchor.dx,
              top: endpoint.dy - top - anchor.dy,
              child: Transform.scale(
                scale: safeScale,
                alignment: Alignment.topLeft,
                child: handle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startSelectionHandleDrag(
    _SelectionEndpoint endpoint,
    int pointer, {
    required Offset pointerPosition,
    required Offset endpointPosition,
  }) {
    final selection = widget.controller.selection;
    if (selection == null || _activeSelectionPointer != null) return;
    _selectionHandleDragActive = true;
    _activeSelectionEndpoint = endpoint;
    _activeSelectionPointer = pointer;
    _activeSelectionPointerToEndpointDelta = endpointPosition - pointerPosition;
    _selectionDragAnchor = endpoint == _SelectionEndpoint.base
        ? selection.extent
        : selection.base;
    _collapsedDragPosition = null;
    _selectionToolbarRequested = false;
    _removeSelectionToolbar();
  }

  void _updateSelectionHandleDrag(int pointer, Offset globalPosition) {
    if (_activeSelectionPointer != pointer) return;
    _dragSelectionHandle(
      globalPosition + (_activeSelectionPointerToEndpointDelta ?? Offset.zero),
    );
  }

  void _dragSelectionHandle(Offset globalPosition) {
    final anchor = _selectionDragAnchor;
    final endpoint = _activeSelectionEndpoint;
    final resolved = _resolveSelectionDragPosition(globalPosition, anchor);
    if (resolved == null || anchor == null || endpoint == null) return;
    if (resolved.position == anchor) {
      // Defer the collapsed selection until pointer-up. Keeping the current
      // handle alive lets the same gesture continue across the fixed endpoint.
      _collapsedDragPosition = resolved.position;
      return;
    }
    _collapsedDragPosition = null;
    if (endpoint == _SelectionEndpoint.base) {
      widget.controller.selectRange(resolved.position, anchor);
    } else {
      widget.controller.selectRange(anchor, resolved.position);
    }
  }

  _ResolvedExpressionPosition? _resolveSelectionDragPosition(
    Offset globalPosition,
    ExpressionPosition? anchor,
  ) {
    if (anchor is FractionExpressionPosition) {
      for (final target in _hitTargets) {
        if (target.kind != _ExpressionHitTargetKind.fractionField ||
            target.marker != anchor.marker ||
            target.field != anchor.field) {
          continue;
        }
        final gestureBox =
            target.key.currentContext?.findRenderObject() as RenderBox?;
        if (gestureBox == null || !gestureBox.hasSize) break;
        final gestureRect =
            gestureBox.localToGlobal(Offset.zero) & gestureBox.size;
        if (gestureRect.contains(globalPosition)) {
          return _resolveTarget(target, globalPosition);
        }
        break;
      }
    }
    return _resolvePosition(globalPosition);
  }

  void _finishSelectionHandleDrag(int pointer) {
    if (_activeSelectionPointer != pointer) return;
    final collapsedPosition = _collapsedDragPosition;
    _selectionHandleDragActive = false;
    _activeSelectionEndpoint = null;
    _activeSelectionPointer = null;
    _activeSelectionPointerToEndpointDelta = null;
    _selectionDragAnchor = null;
    _collapsedDragPosition = null;
    if (collapsedPosition != null) {
      _selectionToolbarRequested = false;
      widget.controller.moveCaretToPosition(collapsedPosition);
      _caretToolbarRequested = true;
      _scheduleSelectionOverlaySync();
      return;
    }
    if (!widget.controller.hasSelection) return;
    _selectionToolbarRequested = true;
    _syncSelectionHandlesOverlay();
  }

  Rect? _caretRectForPosition(ExpressionPosition position) {
    for (final target in _hitTargets) {
      if (position case RawExpressionPosition(:final offset)) {
        if (target.kind == _ExpressionHitTargetKind.currentCaret &&
            target.rawOffset == offset) {
          return _edgeCaretRect(target, trailing: false);
        }
        if (target.kind == _ExpressionHitTargetKind.text) {
          final index = target.rawOffsets.indexOf(offset);
          if (index >= 0) {
            return _caretRectForTargetOffset(target, index);
          }
        }
        if (target.marker != null) {
          final markerIndex = widget.controller.expression.indexOf(
            target.marker!,
          );
          if (target.kind == _ExpressionHitTargetKind.fractionBefore &&
              offset == markerIndex) {
            return _edgeCaretRect(target, trailing: true);
          }
          if (target.kind == _ExpressionHitTargetKind.fractionAfter &&
              offset == markerIndex + 1) {
            return _edgeCaretRect(target, trailing: false);
          }
        }
      } else if (position case FractionExpressionPosition(
        :final marker,
        :final field,
        :final offset,
      )) {
        if (target.kind == _ExpressionHitTargetKind.fractionField &&
            target.marker == marker &&
            target.field == field) {
          return _caretRectForTargetOffset(target, offset);
        }
      }
    }
    return null;
  }

  ({double scale, double height}) _displayMetricsForPosition(
    ExpressionPosition position,
  ) {
    for (final target in _hitTargets) {
      if (position case RawExpressionPosition(:final offset)) {
        if (target.kind == _ExpressionHitTargetKind.text &&
            target.rawOffsets.contains(offset)) {
          return _displayMetricsForTarget(target);
        }
        if (target.marker != null) {
          final markerIndex = widget.controller.expression.indexOf(
            target.marker!,
          );
          if ((target.kind == _ExpressionHitTargetKind.fractionBefore &&
                  offset == markerIndex) ||
              (target.kind == _ExpressionHitTargetKind.fractionAfter &&
                  offset == markerIndex + 1)) {
            return _displayMetricsForTarget(target);
          }
        }
      } else if (position case FractionExpressionPosition(
        :final marker,
        :final field,
      )) {
        if (target.kind == _ExpressionHitTargetKind.fractionField &&
            target.marker == marker &&
            target.field == field) {
          return _displayMetricsForTarget(target);
        }
      }
    }
    return (scale: 1, height: _EditableExpressionLine._expressionFontSize);
  }

  ({double scale, double height}) _displayMetricsForTarget(
    _ExpressionHitTarget target,
  ) {
    final box = _coordinateBoxForTarget(target);
    if (box == null || !box.hasSize || box.size.height <= 0) {
      return (scale: 1, height: _EditableExpressionLine._expressionFontSize);
    }
    final top = box.localToGlobal(Offset.zero);
    final bottom = box.localToGlobal(Offset(0, box.size.height));
    final renderedHeight = (bottom - top).distance;
    final transformScale = renderedHeight / box.size.height;
    final style = target.style;
    if (style == null) {
      return (scale: transformScale, height: renderedHeight);
    }
    if (target.kind == _ExpressionHitTargetKind.text) {
      final fontSize = style.fontSize;
      if (fontSize == null || fontSize <= 0) {
        return (scale: transformScale, height: renderedHeight);
      }
      final textScale =
          MediaQuery.textScalerOf(context).scale(fontSize) / fontSize;
      final painter = TextPainter(
        text: TextSpan(text: target.text, style: style),
        textDirection: TextDirection.ltr,
        textScaler: MediaQuery.textScalerOf(context),
        maxLines: 1,
      )..layout();
      return (
        scale: transformScale * textScale,
        height: painter.height * transformScale,
      );
    }
    final text = target.kind == _ExpressionHitTargetKind.text
        ? target.text
        : target.fieldValue.isEmpty
        ? '□'
        : target.fieldValue;
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textScaler: TextScaler.noScaling,
      maxLines: 1,
    )..layout();
    if (painter.height <= 0) {
      return (scale: 1, height: renderedHeight);
    }
    return (scale: renderedHeight / painter.height, height: renderedHeight);
  }

  Rect? _caretRectForTargetOffset(
    _ExpressionHitTarget target,
    int offset, {
    double horizontalInset = 0,
  }) {
    final coordinateKey = target.kind == _ExpressionHitTargetKind.fractionField
        ? target.geometryKey ?? target.key
        : target.key;
    final box = coordinateKey.currentContext?.findRenderObject() as RenderBox?;
    final style = target.style;
    if (box == null || !box.hasSize || style == null) return null;
    final text = target.kind == _ExpressionHitTargetKind.text
        ? target.text
        : target.fieldValue;
    if (target.kind == _ExpressionHitTargetKind.fractionField &&
        box is RenderParagraph) {
      final safeOffset = offset.clamp(0, text.length);
      final x = box
          .getOffsetForCaret(TextPosition(offset: safeOffset), Rect.zero)
          .dx;
      final top = box.localToGlobal(Offset(x, 0));
      final bottom = box.localToGlobal(Offset(x, box.size.height));
      return Rect.fromLTRB(top.dx - 1, top.dy, bottom.dx + 1, bottom.dy);
    }
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final safeOffset = offset.clamp(0, text.length);
    final x =
        horizontalInset +
        painter
            .getOffsetForCaret(TextPosition(offset: safeOffset), Rect.zero)
            .dx;
    final top = box.localToGlobal(Offset(x, 0));
    final bottom = box.localToGlobal(Offset(x, box.size.height));
    return Rect.fromLTRB(top.dx - 1, top.dy, bottom.dx + 1, bottom.dy);
  }

  Rect? _edgeCaretRect(_ExpressionHitTarget target, {required bool trailing}) {
    final coordinateKey = target.kind == _ExpressionHitTargetKind.fractionField
        ? target.geometryKey ?? target.key
        : target.key;
    final box = coordinateKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    final x = trailing ? box.size.width : 0.0;
    final top = box.localToGlobal(Offset(x, 0));
    final bottom = box.localToGlobal(Offset(x, box.size.height));
    return Rect.fromLTRB(top.dx - 1, top.dy, bottom.dx + 1, bottom.dy);
  }

  bool _handleExpressionScroll(ScrollNotification notification) {
    if (!widget.controller.hasSelection) return false;
    if (notification is ScrollStartNotification) {
      _selectionDismissMoved = true;
      _selectionToolbarRequested = false;
      _removeSelectionToolbar();
    }
    _scheduleSelectionOverlaySync();
    return false;
  }

  void _startCaretDrag(LongPressStartDetails details) {
    _hideEditingToolbars();
    _moveCaretForDrag(details.globalPosition);
    _showMagnifier();
  }

  void _updateCaretDrag(LongPressMoveUpdateDetails details) {
    _moveCaretForDrag(details.globalPosition);
  }

  void _endCaretDrag(LongPressEndDetails details) {
    _moveCaretForDrag(details.globalPosition);
    unawaited(_magnifierController.hide());
  }

  void _cancelCaretDrag() {
    unawaited(_magnifierController.hide());
  }

  void _showMagnifier() {
    if (_magnifierController.shown) return;
    unawaited(
      _magnifierController.show(
        context: context,
        debugRequiredFor: widget,
        builder: (overlayContext) {
          final platform = Theme.of(overlayContext).platform;
          final magnifier = switch (platform) {
            TargetPlatform.iOS => _CalculatorCupertinoTextMagnifier(
              controller: _magnifierController,
              magnifierInfo: _magnifierInfo,
            ),
            TargetPlatform.android => _CalculatorMaterialTextMagnifier(
              magnifierInfo: _magnifierInfo,
            ),
            _ => _CalculatorMaterialTextMagnifier(
              magnifierInfo: _magnifierInfo,
            ),
          };
          return KeyedSubtree(
            key: const Key('calculatorMagnifier'),
            child: magnifier,
          );
        },
      ),
    );
  }

  void _moveCaretForDrag(Offset globalPosition) {
    final resolved = _resolvePosition(globalPosition);
    if (resolved == null) return;
    if (widget.controller.expressionPosition != resolved.position) {
      widget.controller.moveCaretToPosition(resolved.position);
    }
    final fieldBox = _fieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (fieldBox == null || !fieldBox.hasSize) return;
    final fieldTopLeft = fieldBox.localToGlobal(Offset.zero);
    _magnifierInfo.value = MagnifierInfo(
      globalGesturePosition: globalPosition,
      caretRect: resolved.caretRect,
      fieldBounds: fieldTopLeft & fieldBox.size,
      currentLineBoundaries: resolved.lineBounds,
    );
  }

  _ResolvedExpressionPosition? _resolvePosition(Offset globalPosition) {
    final closest = _closestHitTarget(globalPosition);
    if (closest == null) return null;
    return _resolveTarget(closest, globalPosition);
  }

  _ExpressionHitTarget? _closestHitTarget(Offset globalPosition) {
    _ExpressionHitTarget? closest;
    var closestDistance = double.infinity;
    for (final target in _hitTargets) {
      final box = target.key.currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) continue;
      final topLeft = box.localToGlobal(Offset.zero);
      final bottomRight = box.localToGlobal(box.size.bottomRight(Offset.zero));
      final rect = Rect.fromPoints(topLeft, bottomRight);
      final dx = globalPosition.dx < rect.left
          ? rect.left - globalPosition.dx
          : globalPosition.dx > rect.right
          ? globalPosition.dx - rect.right
          : 0.0;
      final dy = globalPosition.dy < rect.top
          ? rect.top - globalPosition.dy
          : globalPosition.dy > rect.bottom
          ? globalPosition.dy - rect.bottom
          : 0.0;
      final distance = dx * dx + dy * dy;
      if (distance < closestDistance) {
        closestDistance = distance;
        closest = target;
      }
    }
    return closest;
  }

  _ResolvedExpressionPosition? _resolveTarget(
    _ExpressionHitTarget target,
    Offset globalPosition,
  ) {
    final box = _coordinateBoxForTarget(target);
    final lineBox =
        target.lineKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || lineBox == null || !box.hasSize || !lineBox.hasSize) {
      return null;
    }
    final local = box.globalToLocal(globalPosition);
    late final ExpressionPosition position;
    late final double caretX;
    switch (target.kind) {
      case _ExpressionHitTargetKind.text:
        final painter = TextPainter(
          text: TextSpan(text: target.text, style: target.style),
          textDirection: TextDirection.ltr,
          textScaler: MediaQuery.textScalerOf(context),
          maxLines: 1,
        )..layout();
        final textOffset = painter
            .getPositionForOffset(Offset(local.dx.clamp(0.0, painter.width), 0))
            .offset
            .clamp(0, target.text.length);
        position = RawExpressionPosition(target.rawOffsets[textOffset]);
        caretX = painter
            .getOffsetForCaret(TextPosition(offset: textOffset), Rect.zero)
            .dx;
      case _ExpressionHitTargetKind.fractionField:
        final value = target.fieldValue;
        final paragraph = box is RenderParagraph ? box : null;
        final fieldOffset = value.isEmpty || paragraph == null
            ? 0
            : paragraph
                  .getPositionForOffset(local)
                  .offset
                  .clamp(0, value.length);
        position = FractionExpressionPosition(
          marker: target.marker!,
          field: target.field!,
          offset: fieldOffset,
        );
        caretX = paragraph == null
            ? 0
            : paragraph
                  .getOffsetForCaret(
                    TextPosition(offset: fieldOffset),
                    Rect.zero,
                  )
                  .dx;
      case _ExpressionHitTargetKind.fractionBefore:
        position = RawExpressionPosition(
          widget.controller.expression.indexOf(target.marker!),
        );
        caretX = box.size.width;
      case _ExpressionHitTargetKind.fractionAfter:
        position = RawExpressionPosition(
          widget.controller.expression.indexOf(target.marker!) + 1,
        );
        caretX = 0;
      case _ExpressionHitTargetKind.currentCaret:
        position = RawExpressionPosition(target.rawOffset!);
        caretX = box.size.width / 2;
    }
    final caretTop = box.localToGlobal(Offset(caretX, 0));
    final caretBottom = box.localToGlobal(Offset(caretX, box.size.height));
    final lineTopLeft = lineBox.localToGlobal(Offset.zero);
    return _ResolvedExpressionPosition(
      position: position,
      caretRect: Rect.fromLTRB(
        caretTop.dx - 1,
        caretTop.dy,
        caretBottom.dx + 1,
        caretBottom.dy,
      ),
      lineBounds: lineTopLeft & lineBox.size,
    );
  }

  RenderBox? _coordinateBoxForTarget(_ExpressionHitTarget target) {
    final coordinateKey = target.kind == _ExpressionHitTargetKind.fractionField
        ? target.geometryKey ?? target.key
        : target.key;
    return coordinateKey.currentContext?.findRenderObject() as RenderBox?;
  }
}

class _EditableExpressionText extends StatelessWidget {
  const _EditableExpressionText({
    required this.gestureKey,
    required this.segment,
    required this.style,
    required this.selectedRawRange,
    required this.onRawOffsetTap,
  });

  final GlobalKey gestureKey;
  final ExpressionTextSegment segment;
  final TextStyle style;
  final (int, int)? selectedRawRange;
  final ValueChanged<int> onRawOffsetTap;

  @override
  Widget build(BuildContext context) {
    final textScaler = MediaQuery.textScalerOf(context);
    final painter = TextPainter(
      text: TextSpan(text: segment.text, style: style),
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
      maxLines: 1,
    )..layout();

    final selected = selectedRawRange;
    final textWidget = CustomPaint(
      painter: selected == null
          ? null
          : _ExpressionSelectionHighlightPainter(
              text: segment.text,
              rawOffsets: segment.rawOffsets,
              style: style,
              textScaler: textScaler,
              selected: selected,
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.28),
            ),
      child: Text.rich(
        TextSpan(text: segment.text, style: style),
        style: style,
        maxLines: 1,
      ),
    );
    return GestureDetector(
      key: gestureKey,
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
        child: textWidget,
      ),
    );
  }
}

const double _calculatorMagnificationScale = 1.3;

class _CalculatorCupertinoTextMagnifier extends StatefulWidget {
  const _CalculatorCupertinoTextMagnifier({
    required this.controller,
    required this.magnifierInfo,
  });

  final MagnifierController controller;
  final ValueNotifier<MagnifierInfo> magnifierInfo;

  @override
  State<_CalculatorCupertinoTextMagnifier> createState() =>
      _CalculatorCupertinoTextMagnifierState();
}

class _CalculatorCupertinoTextMagnifierState
    extends State<_CalculatorCupertinoTextMagnifier>
    with SingleTickerProviderStateMixin {
  static const _animationDuration = Duration(milliseconds: 150);
  static const _dragAnimationDuration = Duration(milliseconds: 45);
  static const _dragResistance = 10.0;
  static const _hideBelowThreshold = 48.0;
  static const _horizontalScreenEdgePadding = 10.0;

  Offset _position = Offset.zero;
  double _verticalFocalPointAdjustment = 0;
  late final AnimationController _animationController;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      value: 0,
      vsync: this,
      duration: _animationDuration,
    )..addListener(_rebuild);
    widget.controller.animationController = _animationController;
    widget.magnifierInfo.addListener(_updateGeometry);
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateGeometry();
  }

  @override
  void didUpdateWidget(_CalculatorCupertinoTextMagnifier oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.magnifierInfo != widget.magnifierInfo) {
      oldWidget.magnifierInfo.removeListener(_updateGeometry);
      widget.magnifierInfo.addListener(_updateGeometry);
    }
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.animationController = null;
      widget.controller.animationController = _animationController;
    }
  }

  @override
  void dispose() {
    widget.controller.animationController = null;
    widget.magnifierInfo.removeListener(_updateGeometry);
    _animationController
      ..removeListener(_rebuild)
      ..dispose();
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  void _updateGeometry() {
    if (!mounted) return;
    final info = widget.magnifierInfo.value;
    final lineCenterY = info.caretRect.center.dy;
    if (lineCenterY - info.globalGesturePosition.dy < -_hideBelowThreshold) {
      if (widget.controller.shown) {
        unawaited(widget.controller.hide(removeFromOverlay: false));
      }
      return;
    }
    if (!widget.controller.shown) _animationController.forward();
    final lensY = math.max(
      lineCenterY,
      lineCenterY -
          (lineCenterY - info.globalGesturePosition.dy) / _dragResistance,
    );
    final rawPosition = Offset(
      info.globalGesturePosition.dx - CupertinoMagnifier.kDefaultSize.width / 2,
      lensY -
          (CupertinoMagnifier.kDefaultSize.height -
              CupertinoMagnifier.kMagnifierAboveFocalPoint),
    );
    final screenRect = Offset.zero & MediaQuery.sizeOf(context);
    final adjusted = MagnifierController.shiftWithinBounds(
      bounds: Rect.fromLTRB(
        screenRect.left + _horizontalScreenEdgePadding,
        screenRect.top -
            (CupertinoMagnifier.kDefaultSize.height +
                CupertinoMagnifier.kMagnifierAboveFocalPoint),
        screenRect.right - _horizontalScreenEdgePadding,
        screenRect.bottom +
            (CupertinoMagnifier.kDefaultSize.height +
                CupertinoMagnifier.kMagnifierAboveFocalPoint),
      ),
      rect: rawPosition & CupertinoMagnifier.kDefaultSize,
    ).topLeft;
    setState(() {
      _position = adjusted;
      _verticalFocalPointAdjustment = lineCenterY - lensY;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: _dragAnimationDuration,
      curve: Curves.easeOut,
      left: _position.dx,
      top: _position.dy,
      child: CupertinoMagnifier(
        inOutAnimation: _animation,
        additionalFocalPointOffset: Offset(0, _verticalFocalPointAdjustment),
        borderSide: BorderSide(
          color: CupertinoTheme.of(context).primaryColor,
          width: 2,
        ),
        magnificationScale: _calculatorMagnificationScale,
      ),
    );
  }
}

class _CalculatorMaterialTextMagnifier extends StatefulWidget {
  const _CalculatorMaterialTextMagnifier({required this.magnifierInfo});

  final ValueNotifier<MagnifierInfo> magnifierInfo;

  @override
  State<_CalculatorMaterialTextMagnifier> createState() =>
      _CalculatorMaterialTextMagnifierState();
}

class _CalculatorMaterialTextMagnifierState
    extends State<_CalculatorMaterialTextMagnifier> {
  static const _size = Size(77.37, 37.9);
  static const _verticalFocalPointShift = 22.0;
  static const _lineJumpDuration = Duration(milliseconds: 70);

  Offset? _position;
  Offset _extraFocalPointOffset = Offset.zero;
  Timer? _lineJumpTimer;

  @override
  void initState() {
    super.initState();
    widget.magnifierInfo.addListener(_updateGeometry);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateGeometry();
  }

  @override
  void didUpdateWidget(_CalculatorMaterialTextMagnifier oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.magnifierInfo != widget.magnifierInfo) {
      oldWidget.magnifierInfo.removeListener(_updateGeometry);
      widget.magnifierInfo.addListener(_updateGeometry);
    }
  }

  @override
  void dispose() {
    widget.magnifierInfo.removeListener(_updateGeometry);
    _lineJumpTimer?.cancel();
    super.dispose();
  }

  void _updateGeometry() {
    if (!mounted) return;
    final info = widget.magnifierInfo.value;
    final screenRect = Offset.zero & MediaQuery.sizeOf(context);
    final magnifierX = info.globalGesturePosition.dx.clamp(
      info.currentLineBoundaries.left,
      info.currentLineBoundaries.right,
    );
    final basicOffset = Offset(
      _size.width / 2,
      _size.height + _verticalFocalPointShift,
    );
    final unadjusted =
        Offset(magnifierX, info.caretRect.center.dy) - basicOffset & _size;
    final adjusted = MagnifierController.shiftWithinBounds(
      bounds: screenRect,
      rect: unadjusted,
    );
    final horizontalInset = (_size.width / 2) / _calculatorMagnificationScale;
    final focalX = info.fieldBounds.width < horizontalInset * 2
        ? info.fieldBounds.center.dx
        : adjusted.center.dx.clamp(
            info.fieldBounds.left + horizontalInset,
            info.fieldBounds.right - horizontalInset,
          );
    final extraFocalPointOffset = Offset(
      focalX - adjusted.center.dx,
      unadjusted.top - adjusted.top,
    );
    final shouldAnimate =
        _position != null && adjusted.topLeft.dy != _position!.dy;
    if (shouldAnimate) {
      _lineJumpTimer?.cancel();
      _lineJumpTimer = Timer(_lineJumpDuration, () {
        if (!mounted) return;
        setState(() => _lineJumpTimer = null);
      });
    }
    setState(() {
      _position = adjusted.topLeft;
      _extraFocalPointOffset = extraFocalPointOffset;
    });
  }

  @override
  Widget build(BuildContext context) {
    final position = _position;
    if (position == null) return const SizedBox.shrink();
    return AnimatedPositioned(
      top: position.dy,
      left: position.dx,
      duration: _lineJumpTimer == null ? Duration.zero : _lineJumpDuration,
      child: RawMagnifier(
        size: _size,
        magnificationScale: _calculatorMagnificationScale,
        focalPointOffset:
            _extraFocalPointOffset +
            Offset(0, _verticalFocalPointShift + _size.height / 2),
        decoration: const MagnifierDecoration(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(40)),
          ),
          shadows: [
            BoxShadow(
              blurRadius: 1.5,
              offset: Offset(0, 2),
              spreadRadius: 0.75,
              color: Color.fromARGB(25, 0, 0, 0),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: const ColoredBox(color: Color.fromARGB(8, 158, 158, 158)),
      ),
    );
  }
}

class _ExpressionSelectionHighlightPainter extends CustomPainter {
  const _ExpressionSelectionHighlightPainter({
    required this.text,
    required this.rawOffsets,
    required this.style,
    required this.textScaler,
    required this.selected,
    required this.color,
  });

  final String text;
  final List<int> rawOffsets;
  final TextStyle style;
  final TextScaler textScaler;
  final (int, int) selected;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
      maxLines: 1,
    )..layout();
    final paint = Paint()..color = color;
    for (var index = 0; index < text.length; index++) {
      final rawStart = rawOffsets[index];
      final rawEnd = rawOffsets[index + 1];
      final isSelected = rawEnd > rawStart
          ? rawStart >= selected.$1 && rawEnd <= selected.$2
          : rawStart > selected.$1 && rawStart < selected.$2;
      if (!isSelected) continue;
      for (final box in painter.getBoxesForSelection(
        TextSelection(baseOffset: index, extentOffset: index + 1),
      )) {
        canvas.drawRect(box.toRect(), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_ExpressionSelectionHighlightPainter oldDelegate) =>
      text != oldDelegate.text ||
      rawOffsets != oldDelegate.rawOffsets ||
      style != oldDelegate.style ||
      textScaler != oldDelegate.textScaler ||
      selected != oldDelegate.selected ||
      color != oldDelegate.color;
}

class _InlineFraction extends StatelessWidget {
  const _InlineFraction({
    required this.segment,
    required this.fontSize,
    required this.textStyle,
    required this.fullySelected,
    required this.wholeNumberSelection,
    required this.numeratorSelection,
    required this.denominatorSelection,
    required this.beforeKey,
    required this.afterKey,
    required this.wholeNumberKey,
    required this.numeratorKey,
    required this.denominatorKey,
    required this.wholeNumberGeometryKey,
    required this.numeratorGeometryKey,
    required this.denominatorGeometryKey,
    required this.onBeforeFractionTap,
    required this.onAfterFractionTap,
    required this.onFieldTap,
  });

  final ExpressionFractionSegment segment;
  final double fontSize;
  final TextStyle textStyle;
  final bool fullySelected;
  final TextRange? wholeNumberSelection;
  final TextRange? numeratorSelection;
  final TextRange? denominatorSelection;
  final GlobalKey beforeKey;
  final GlobalKey afterKey;
  final GlobalKey wholeNumberKey;
  final GlobalKey numeratorKey;
  final GlobalKey denominatorKey;
  final GlobalKey wholeNumberGeometryKey;
  final GlobalKey numeratorGeometryKey;
  final GlobalKey denominatorGeometryKey;
  final VoidCallback onBeforeFractionTap;
  final VoidCallback onAfterFractionTap;
  final void Function(FractionField field, int caretOffset) onFieldTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: fullySelected ? const Key('selectedFractionNode') : null,
      decoration: BoxDecoration(
        color: fullySelected
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.28)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              key: beforeKey,
              behavior: HitTestBehavior.opaque,
              onTap: onBeforeFractionTap,
              child: SizedBox(
                key: const Key('fractionBeforeTapArea'),
                width: 14,
                height: fontSize * 2.1,
              ),
            ),
            if (segment.wholeNumber.isNotEmpty) ...[
              _FractionFieldDisplay(
                key: const Key('mixedFractionWholeNumber'),
                caretSlotKey: const Key('mixedFractionWholeNumberCaretSlot'),
                gestureKey: wholeNumberKey,
                geometryKey: wholeNumberGeometryKey,
                value: segment.wholeNumber,
                active: segment.activeField == FractionField.wholeNumber,
                caretOffset: segment.activeField == FractionField.wholeNumber
                    ? segment.activeCaretOffset
                    : null,
                fontSize: fontSize,
                textStyle: textStyle,
                selection: wholeNumberSelection,
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
                    gestureKey: numeratorKey,
                    geometryKey: numeratorGeometryKey,
                    value: segment.numerator,
                    active: segment.activeField == FractionField.numerator,
                    caretOffset: segment.activeField == FractionField.numerator
                        ? segment.activeCaretOffset
                        : null,
                    fontSize: fontSize,
                    textStyle: textStyle,
                    selection: numeratorSelection,
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
                    gestureKey: denominatorKey,
                    geometryKey: denominatorGeometryKey,
                    value: segment.denominator,
                    active: segment.activeField == FractionField.denominator,
                    caretOffset:
                        segment.activeField == FractionField.denominator
                        ? segment.activeCaretOffset
                        : null,
                    fontSize: fontSize,
                    textStyle: textStyle,
                    selection: denominatorSelection,
                    onTap: (offset) {
                      onFieldTap(FractionField.denominator, offset);
                    },
                  ),
                ],
              ),
            ),
            GestureDetector(
              key: afterKey,
              behavior: HitTestBehavior.opaque,
              onTap: onAfterFractionTap,
              child: SizedBox(
                key: const Key('fractionAfterTapArea'),
                width: 24,
                height: fontSize * 2.1,
              ),
            ),
          ],
        ),
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
    required this.gestureKey,
    required this.geometryKey,
    required this.fontSize,
    required this.textStyle,
    required this.selection,
    required this.onTap,
    super.key,
  });

  final String value;
  final bool active;
  final int? caretOffset;
  final Key caretSlotKey;
  final GlobalKey gestureKey;
  final GlobalKey geometryKey;
  final double fontSize;
  final TextStyle textStyle;
  final TextRange? selection;
  final ValueChanged<int> onTap;

  static const double _caretWidth = 1.5;
  static const double _caretHeight = 32;

  @override
  Widget build(BuildContext context) {
    final textScaler = MediaQuery.textScalerOf(context);
    final placeholderStyle = textStyle.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    final offset = (caretOffset ?? value.length).clamp(0, value.length);
    final displayValue = value.isEmpty ? '□' : value;
    final displayOffset = value.isEmpty ? 0 : offset;
    void handleTap(TapUpDetails details) {
      if (value.isEmpty) {
        onTap(0);
        return;
      }
      final gestureBox =
          gestureKey.currentContext?.findRenderObject() as RenderBox?;
      final geometryBox =
          geometryKey.currentContext?.findRenderObject() as RenderBox?;
      if (gestureBox == null || geometryBox is! RenderParagraph) return;
      final globalPosition = gestureBox.localToGlobal(details.localPosition);
      final position = geometryBox.getPositionForOffset(
        geometryBox.globalToLocal(globalPosition),
      );
      onTap(position.offset.clamp(0, value.length));
    }

    final range = selection == null || value.isEmpty
        ? null
        : TextRange(
            start: selection!.start.clamp(0, value.length),
            end: selection!.end.clamp(0, value.length),
          );
    final highlight = Theme.of(
      context,
    ).colorScheme.primary.withValues(alpha: 0.28);
    final caretPainter = TextPainter(
      text: TextSpan(text: displayValue, style: textStyle),
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
      maxLines: 1,
    )..layout();
    final caretX = caretPainter
        .getOffsetForCaret(TextPosition(offset: displayOffset), Rect.zero)
        .dx;
    final textSpan = range == null
        ? TextSpan(
            text: displayValue,
            style: value.isEmpty ? placeholderStyle : textStyle,
          )
        : TextSpan(
            style: textStyle,
            children: [
              TextSpan(text: value.substring(0, range.start)),
              TextSpan(
                text: value.substring(range.start, range.end),
                style: TextStyle(backgroundColor: highlight),
              ),
              TextSpan(text: value.substring(range.end)),
            ],
          );

    return GestureDetector(
      key: gestureKey,
      behavior: HitTestBehavior.opaque,
      onTapUp: handleTap,
      child: SizedBox(
        height: fontSize * 1.05,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: Align(
            alignment: Alignment.center,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Text.rich(textSpan, key: geometryKey, maxLines: 1),
                if (range == null)
                  Positioned(
                    left: caretX,
                    top: (fontSize * 1.05 - _caretHeight) / 2,
                    child: Opacity(
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
                  ),
              ],
            ),
          ),
        ),
      ),
    );
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
