import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/localization/app_localizations.dart';
import '../../advertising/domain/rewarded_ad_policy.dart';
import '../../settings/domain/app_settings.dart';
import '../../settings/domain/company_profile.dart';
import '../../settings/presentation/company_profile_editor_screen.dart';
import '../../settings/presentation/estimate_tax_settings_screen.dart';
import '../application/estimate_controller.dart';
import '../application/estimate_excel_export.dart';
import '../application/estimate_excel_share.dart';
import '../application/estimate_export_file_name.dart';
import '../application/estimate_pdf_export.dart';
import '../application/estimate_pdf_share.dart';
import '../application/estimate_print.dart';
import '../application/estimate_table_export.dart';
import '../domain/estimate_item.dart';
import '../domain/estimate_item_draft.dart';
import '../domain/estimate_item_group.dart';
import '../domain/estimate_info.dart';
import '../domain/estimate_quantity.dart';
import 'duplicate_estimate_item_dialog.dart';
import 'estimate_info_editor_screen.dart';
import 'estimate_item_editor_screen.dart';
import 'estimate_pdf_script_notice.dart';
import 'estimate_success_snack_bar.dart';
import 'merge_estimate_quantity_dialog.dart';

enum _EstimateItemAction { reorder, duplicate, edit, delete }

enum _EstimateReorderMode { none, items, groups }

enum _EstimateOutputAction { print, pdf, excel }

enum _EstimateMoreAction { editInfo, editCompanyProfile, copyTable, editTax }

class EstimateItemsScreen extends StatefulWidget {
  const EstimateItemsScreen({
    required this.controller,
    this.settings = const AppSettings(),
    this.onSettingsChanged,
    this.onRequestRewardedAdAccess,
    this.printPdfBytes = printEstimatePdfBytes,
    this.sharePdfBytes = shareEstimatePdfBytes,
    this.createWorkbookFile = createEstimateWorkbookFile,
    this.shareWorkbookFile = shareEstimateWorkbookFile,
    super.key,
  });

  final EstimateController controller;
  final AppSettings settings;
  final ValueChanged<AppSettings>? onSettingsChanged;
  final Future<bool> Function(RewardedAdEntryPoint)? onRequestRewardedAdAccess;
  final EstimatePdfBytesPrinter printPdfBytes;
  final EstimatePdfBytesSharer sharePdfBytes;
  final EstimateWorkbookFileCreator createWorkbookFile;
  final EstimateWorkbookFileSharer shareWorkbookFile;

  @override
  State<EstimateItemsScreen> createState() => _EstimateItemsScreenState();
}

class _EstimateItemsScreenState extends State<EstimateItemsScreen> {
  late AppSettings _settings = widget.settings;
  Future<void> _taxSettingsSave = Future<void>.value();
  _EstimateReorderMode _reorderMode = _EstimateReorderMode.none;
  List<EstimateItemGroup> _workingGroups = const [];
  EstimateItemGroup? _itemReorderGroup;
  List<EstimateItem> _workingItems = const [];

  EstimateController get controller => widget.controller;
  AppSettings get settings => _settings;
  Future<bool> Function(RewardedAdEntryPoint)? get onRequestRewardedAdAccess =>
      widget.onRequestRewardedAdAccess;
  EstimatePdfBytesPrinter get printPdfBytes => widget.printPdfBytes;
  EstimatePdfBytesSharer get sharePdfBytes => widget.sharePdfBytes;
  EstimateWorkbookFileCreator get createWorkbookFile =>
      widget.createWorkbookFile;
  EstimateWorkbookFileSharer get shareWorkbookFile => widget.shareWorkbookFile;

  @override
  void didUpdateWidget(EstimateItemsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings != widget.settings) _settings = widget.settings;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isReordering = _reorderMode != _EstimateReorderMode.none;
    return Scaffold(
      appBar: AppBar(
        leading: isReordering
            ? IconButton(
                key: const Key('cancelEstimateReorder'),
                onPressed: _cancelReorder,
                icon: const Icon(Icons.close),
              )
            : null,
        title: isReordering ? Text(l10n.text('並び替え')) : null,
        actions: [
          if (isReordering)
            TextButton(
              key: const Key('finishEstimateReorder'),
              onPressed: _finishReorder,
              child: Text(l10n.text('完了')),
            )
          else ...[
            TextButton(
              key: const Key('estimateOutputButton'),
              style: TextButton.styleFrom(
                foregroundColor: IconTheme.of(context).color,
                minimumSize: const Size(86, 48),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                tapTargetSize: MaterialTapTargetSize.padded,
              ),
              onPressed: () => _showOutputOptions(context),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _EstimateOutputIcon(),
                  const SizedBox(width: 5),
                  Text(l10n.estimateOutput, maxLines: 1),
                ],
              ),
            ),
            Semantics(
              container: true,
              button: true,
              label: l10n.estimateMoreActions,
              child: PopupMenuButton<_EstimateMoreAction>(
                key: const Key('estimateMoreActions'),
                tooltip: l10n.estimateMoreActions,
                onSelected: (action) => _handleMoreAction(context, action),
                itemBuilder: (_) => [
                  PopupMenuItem(
                    key: const Key('editEstimateInfo'),
                    value: _EstimateMoreAction.editInfo,
                    child: ListTile(
                      leading: const Icon(Icons.edit_note_outlined),
                      title: Text(l10n.editEstimateInformation),
                    ),
                  ),
                  PopupMenuItem(
                    key: const Key('editCompanyProfileFromEstimateItems'),
                    value: _EstimateMoreAction.editCompanyProfile,
                    child: ListTile(
                      leading: const Icon(Icons.business_outlined),
                      title: Text(l10n.editCompanyProfile),
                    ),
                  ),
                  PopupMenuItem(
                    key: const Key('copyEstimateTable'),
                    value: _EstimateMoreAction.copyTable,
                    child: ListTile(
                      leading: const Icon(Icons.table_view_outlined),
                      title: Text(l10n.copyTableForExcel),
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    key: const Key('editEstimateTaxSettings'),
                    value: _EstimateMoreAction.editTax,
                    child: ListTile(
                      leading: const Icon(Icons.percent_outlined),
                      title: Text(l10n.taxSettings),
                      subtitle: Text(
                        l10n.taxSettingsSummary(
                          enabled: controller.info.taxEnabled,
                          rate: formatTaxRateBasisPoints(
                            controller.info.taxRateBasisPoints,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      floatingActionButton: isReordering
          ? null
          : FloatingActionButton.extended(
              key: const Key('addEstimateItemDirect'),
              onPressed: () => _addItem(context),
              icon: const Icon(Icons.add),
              label: Text(l10n.text('明細を追加')),
            ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            if (!controller.isLoaded) {
              return const Center(child: CircularProgressIndicator());
            }
            if (_reorderMode == _EstimateReorderMode.groups) {
              return _buildGroupReorderList(context);
            }
            if (_reorderMode == _EstimateReorderMode.items) {
              return _buildItemReorderList(context);
            }
            return Column(
              children: [
                _EstimateInfoSummary(
                  info: controller.info,
                  onTap: () => _editInfo(context),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                  child: _EstimateTotalsSummary(
                    itemCount: controller.items.length,
                    subtotal: controller.subtotalAmount,
                    tax: controller.taxAmount,
                    grandTotal: controller.grandTotalAmount,
                    taxEnabled: controller.info.taxEnabled,
                    taxRateBasisPoints: controller.info.taxRateBasisPoints,
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 12, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.text('記号・施工場所'),
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      IconButton(
                        key: const Key('reorderEstimateGroups'),
                        tooltip: l10n.text('記号・施工場所を入替'),
                        onPressed: controller.items.isEmpty
                            ? null
                            : _startGroupReorder,
                        icon: const Icon(Icons.settings_outlined),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: controller.items.isEmpty
                      ? Center(
                          child: Text(
                            l10n.text('見積明細はまだありません'),
                            key: Key('emptyEstimateItems'),
                          ),
                        )
                      : ListView.separated(
                          key: const Key('estimateItemsList'),
                          padding: const EdgeInsets.all(12),
                          itemCount: controller.groups.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, groupIndex) =>
                              _EstimateGroupSection(
                                group: controller.groups[groupIndex],
                                groupIndex: groupIndex,
                                itemIndex: (item) =>
                                    controller.items.indexWhere(
                                      (candidate) => candidate.id == item.id,
                                    ),
                                onAction: (item, action) =>
                                    _handleAction(context, item, action),
                              ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _startGroupReorder() {
    setState(() {
      _workingGroups = List.of(controller.groups);
      _reorderMode = _EstimateReorderMode.groups;
    });
  }

  void _startItemReorder(EstimateItem item) {
    final group = controller.groups.firstWhere(
      (candidate) => candidate.items.any((entry) => entry.id == item.id),
    );
    setState(() {
      _itemReorderGroup = group;
      _workingItems = List.of(group.items);
      _reorderMode = _EstimateReorderMode.items;
    });
  }

  void _cancelReorder() {
    setState(() {
      _reorderMode = _EstimateReorderMode.none;
      _workingGroups = const [];
      _workingItems = const [];
      _itemReorderGroup = null;
    });
  }

  Future<void> _finishReorder() async {
    try {
      if (_reorderMode == _EstimateReorderMode.groups) {
        await controller.reorderGroups([
          for (final group in _workingGroups)
            [for (final item in group.items) item.id],
        ]);
      } else if (_reorderMode == _EstimateReorderMode.items) {
        final group = _itemReorderGroup!;
        await controller.reorderItemsInGroup(
          constructionSymbol: group.constructionSymbol,
          constructionLocation: group.constructionLocation,
          itemIds: [for (final item in _workingItems) item.id],
        );
      }
      if (mounted) _cancelReorder();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).text('並び順を保存できませんでした')),
        ),
      );
    }
  }

  Widget _buildGroupReorderList(BuildContext context) {
    return ReorderableListView.builder(
      key: const Key('estimateGroupReorderList'),
      padding: const EdgeInsets.all(12),
      buildDefaultDragHandles: false,
      autoScrollerVelocityScalar: 50,
      itemCount: _workingGroups.length,
      proxyDecorator: (child, _, animation) => Material(
        elevation: 6 * animation.value,
        color: Colors.transparent,
        child: child,
      ),
      onReorderItem: (oldIndex, newIndex) {
        setState(() {
          final group = _workingGroups.removeAt(oldIndex);
          _workingGroups.insert(newIndex, group);
        });
      },
      itemBuilder: (context, index) => Padding(
        key: ValueKey(
          'reorder-group-${_workingGroups[index].constructionSymbol}-${_workingGroups[index].constructionLocation}',
        ),
        padding: const EdgeInsets.only(bottom: 12),
        child: _EstimateGroupSection(
          group: _workingGroups[index],
          groupIndex: index,
          itemIndex: (item) =>
              controller.items.indexWhere((entry) => entry.id == item.id),
          onAction: (_, _) {},
          groupDragHandle: ReorderableDragStartListener(
            key: Key('estimateGroupDragHandle$index'),
            index: index,
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Icon(Icons.drag_handle),
            ),
          ),
          hideItemMenus: true,
        ),
      ),
    );
  }

  Widget _buildItemReorderList(BuildContext context) {
    final group = _itemReorderGroup!;
    final colors = Theme.of(context).colorScheme;
    return Column(
      children: [
        ColoredBox(
          color: colors.primaryContainer,
          child: ListTile(
            key: const Key('estimateItemReorderGroupHeader'),
            title: Text(
              group.displayName.isEmpty ? '—' : group.displayName,
              style: TextStyle(
                color: colors.onPrimaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        Expanded(
          child: ReorderableListView.builder(
            key: const Key('estimateItemReorderList'),
            padding: const EdgeInsets.all(12),
            buildDefaultDragHandles: false,
            autoScrollerVelocityScalar: 50,
            itemCount: _workingItems.length,
            onReorderItem: (oldIndex, newIndex) {
              setState(() {
                final item = _workingItems.removeAt(oldIndex);
                _workingItems.insert(newIndex, item);
              });
            },
            itemBuilder: (context, index) => Card(
              key: ValueKey(_workingItems[index].id),
              margin: const EdgeInsets.only(bottom: 8),
              child: _EstimateItemCard(
                item: _workingItems[index],
                index: controller.items.indexWhere(
                  (item) => item.id == _workingItems[index].id,
                ),
                onAction: (_) {},
                dragHandle: ReorderableDragStartListener(
                  key: Key('estimateItemDragHandle$index'),
                  index: index,
                  child: const Padding(
                    padding: EdgeInsets.all(12),
                    child: Icon(Icons.drag_handle),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showOutputOptions(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final action = await showModalBottomSheet<_EstimateOutputAction>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            key: const Key('estimateOutputSheet'),
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    l10n.estimateOutputMethods,
                    style: Theme.of(sheetContext).textTheme.titleMedium,
                  ),
                ),
              ),
              if (l10n.formalPdfScriptSupportNotice != null)
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: EstimatePdfScriptNotice(
                    key: Key('estimateOutputPdfScriptNotice'),
                  ),
                ),
              ListTile(
                key: const Key('printEstimatePdf'),
                leading: const Icon(Icons.print_outlined),
                title: Text(
                  l10n.printA4Landscape,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () =>
                    Navigator.pop(sheetContext, _EstimateOutputAction.print),
              ),
              ListTile(
                key: const Key('shareEstimatePdf'),
                leading: const Icon(Icons.picture_as_pdf_outlined),
                title: Text(
                  l10n.formalPdf,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () =>
                    Navigator.pop(sheetContext, _EstimateOutputAction.pdf),
              ),
              ListTile(
                key: const Key('exportEstimateExcel'),
                leading: const Icon(Icons.file_download_outlined),
                title: Text(
                  l10n.formalExcelXlsx,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () =>
                    Navigator.pop(sheetContext, _EstimateOutputAction.excel),
              ),
            ],
          ),
        ),
      ),
    );
    if (action == null || !context.mounted) return;
    switch (action) {
      case _EstimateOutputAction.print:
        await _printEstimate(context);
      case _EstimateOutputAction.pdf:
        await _shareEstimatePdf(context);
      case _EstimateOutputAction.excel:
        await _exportExcel(context);
    }
  }

  Future<void> _handleMoreAction(
    BuildContext context,
    _EstimateMoreAction action,
  ) async {
    switch (action) {
      case _EstimateMoreAction.editInfo:
        await _editInfo(context);
      case _EstimateMoreAction.editCompanyProfile:
        await _editCompanyProfile(context);
      case _EstimateMoreAction.copyTable:
        await _copyTable(context);
      case _EstimateMoreAction.editTax:
        await _editTaxSettings(context);
    }
  }

  Future<void> _editTaxSettings(BuildContext context) async {
    var info = controller.info;
    void save(EstimateInfo updated) {
      info = updated;
      _taxSettingsSave = _taxSettingsSave.then(
        (_) => controller.updateInfo(updated),
      );
    }

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => EstimateTaxSettingsScreen(
          title: AppLocalizations.of(context).estimateTaxSettings,
          keyPrefix: 'estimate',
          taxEnabled: info.taxEnabled,
          taxRateBasisPoints: info.taxRateBasisPoints,
          onTaxEnabledChanged: (value) {
            save(info.copyWith(taxEnabled: value));
          },
          onTaxRateBasisPointsChanged: (value) {
            save(info.copyWith(taxRateBasisPoints: value));
          },
        ),
      ),
    );
    await _taxSettingsSave;
  }

  Future<void> _printEstimate(BuildContext context) async {
    if (controller.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).text('印刷する明細がありません')),
        ),
      );
      return;
    }
    if (!await _requestOutputAccess(RewardedAdEntryPoint.printOutput)) return;
    if (!context.mounted) return;
    try {
      final pdfBytes = await _buildFormalPdf();
      if (!context.mounted) return;
      await printPdfBytes(
        bytes: pdfBytes,
        name: formalEstimatePdfFileName(controller.info.displayName),
      );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).text('印刷用PDFを作成できませんでした'),
            ),
          ),
        );
      }
    }
  }

  Future<void> _shareEstimatePdf(BuildContext context) async {
    if (controller.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).text('出力する明細がありません')),
        ),
      );
      return;
    }
    if (!await _requestOutputAccess(RewardedAdEntryPoint.pdfExport)) return;
    if (!context.mounted) return;
    try {
      final pdfBytes = await _buildFormalPdf();
      if (!context.mounted) return;
      final box = context.findRenderObject() as RenderBox?;
      await sharePdfBytes(
        bytes: pdfBytes,
        fileName: formalEstimatePdfFileName(controller.info.displayName),
        subject: controller.info.displayName,
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).pdfFileCreationFailed),
          ),
        );
      }
    }
  }

  Future<Uint8List> _buildFormalPdf() => buildEstimatePdf(
    info: controller.info,
    items: controller.items,
    companyProfile: settings.companyProfile,
    estimateDecimalPlaces: settings.estimateDecimalPlaces,
  );

  Future<void> _exportExcel(BuildContext context) async {
    if (controller.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).text('出力する明細がありません')),
        ),
      );
      return;
    }
    if (!await _requestOutputAccess(RewardedAdEntryPoint.excelExport)) return;
    if (!context.mounted) return;
    try {
      final file = await createWorkbookFile(
        info: controller.info,
        items: controller.items,
        companyProfile: settings.companyProfile,
        estimateDecimalPlaces: settings.estimateDecimalPlaces,
      );
      if (!context.mounted) return;
      final box = context.findRenderObject() as RenderBox?;
      await shareWorkbookFile(
        file: file,
        subject: controller.info.displayName,
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).text('Excelファイルを作成できませんでした'),
            ),
          ),
        );
      }
    }
  }

  Future<void> _copyTable(BuildContext context) async {
    if (controller.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).text('コピーする明細がありません')),
        ),
      );
      return;
    }
    if (!await _requestOutputAccess(RewardedAdEntryPoint.excelExport)) return;
    if (!context.mounted) return;
    try {
      await Clipboard.setData(
        ClipboardData(
          text: buildEstimateTableText(controller.items, info: controller.info),
        ),
      );
      if (context.mounted) {
        showEstimateSuccessSnackBar(
          context,
          content: Text(
            AppLocalizations.of(
              context,
            ).copiedEstimateDetails(controller.items.length),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).text('見積明細をコピーできませんでした'),
            ),
          ),
        );
      }
    }
  }

  Future<bool> _requestOutputAccess(RewardedAdEntryPoint entryPoint) async {
    return await onRequestRewardedAdAccess?.call(entryPoint) ?? true;
  }

  Future<void> _addItem(BuildContext context) async {
    final result = await Navigator.of(context).push<EstimateItemEditorResult>(
      MaterialPageRoute(
        builder: (_) => EstimateItemEditorScreen(
          initialDraft: const EstimateItemDraft(),
          settings: settings,
          estimateTitle: controller.info.displayName,
          estimates: controller.estimates,
          initialEstimateId: controller.info.id,
          showOpenEstimateAction: false,
          unitPriceMasters: controller.unitPriceMasters,
        ),
      ),
    );
    if (result == null || !context.mounted) return;
    try {
      await _selectEstimateDestination(result);
      if (!context.mounted) return;
      final duplicate = controller.findDuplicate(result.draft);
      if (duplicate != null) {
        final action = await showDuplicateEstimateItemDialog(
          context,
          duplicate,
        );
        if (!context.mounted || action == DuplicateEstimateItemAction.cancel) {
          return;
        }
        if (action == DuplicateEstimateItemAction.updateExisting) {
          await controller.update(duplicate.id, result.draft);
          final addedToMaster = result.saveToUnitPriceMaster
              ? await controller.addEstimateItemToUnitPriceMasterIfAbsent(
                  result.draft,
                )
              : false;
          if (context.mounted) {
            showEstimateSuccessSnackBar(
              context,
              content: Text(
                AppLocalizations.of(context).text(
                  addedToMaster ? '既存明細を更新し単価マスタへ追加しました' : '既存の見積明細を更新しました',
                ),
              ),
            );
          }
          return;
        }
      } else {
        final mergeCandidate = controller.findQuantityMergeCandidate(
          result.draft,
        );
        if (mergeCandidate != null) {
          final action = await showMergeEstimateQuantityDialog(
            context,
            existing: mergeCandidate,
            incoming: result.draft,
          );
          if (!context.mounted ||
              action == MergeEstimateQuantityAction.cancel) {
            return;
          }
          if (action == MergeEstimateQuantityAction.merge) {
            final merged = await controller.mergeQuantity(
              mergeCandidate.id,
              result.draft,
            );
            final addedToMaster = result.saveToUnitPriceMaster
                ? await controller.addEstimateItemToUnitPriceMasterIfAbsent(
                    result.draft,
                  )
                : false;
            if (context.mounted) {
              showEstimateSuccessSnackBar(
                context,
                content: Text(
                  addedToMaster
                      ? AppLocalizations.of(context).text('数量を加算し単価マスタへ追加しました')
                      : AppLocalizations.of(context).mergedEstimateQuantity(
                          _displayQuantity(merged.quantity),
                        ),
                ),
              );
            }
            return;
          }
        }
      }
      final addedItem = await controller.add(result.draft);
      final addedToMaster = result.saveToUnitPriceMaster
          ? await controller.addEstimateItemToUnitPriceMasterIfAbsent(
              result.draft,
            )
          : false;
      if (context.mounted) {
        _showAddedSnackBar(
          context,
          message: addedToMaster ? '見積明細と単価マスタへ追加しました' : '見積明細へ追加しました',
          itemId: addedItem.id,
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).text('見積明細を保存できませんでした')),
          ),
        );
      }
    }
  }

  Future<void> _editInfo(BuildContext context) async {
    final info = await Navigator.of(context).push<EstimateInfo>(
      MaterialPageRoute(
        builder: (_) => EstimateInfoEditorScreen(initialInfo: controller.info),
      ),
    );
    if (info == null || !context.mounted) return;
    try {
      await controller.updateInfo(info);
      if (context.mounted) {
        showEstimateSuccessSnackBar(
          context,
          content: Text(AppLocalizations.of(context).text('見積基本情報を保存しました')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).text('見積基本情報を保存できませんでした'),
            ),
          ),
        );
      }
    }
  }

  Future<void> _editCompanyProfile(BuildContext context) async {
    final profile = await Navigator.of(context).push<CompanyProfile>(
      MaterialPageRoute<CompanyProfile>(
        builder: (_) => CompanyProfileEditorScreen(
          initialProfile: _settings.companyProfile,
        ),
      ),
    );
    if (profile == null || !mounted) return;
    final updated = _settings.copyWith(companyProfile: profile);
    setState(() => _settings = updated);
    widget.onSettingsChanged?.call(updated);
  }

  Future<void> _handleAction(
    BuildContext context,
    EstimateItem item,
    _EstimateItemAction action,
  ) async {
    switch (action) {
      case _EstimateItemAction.reorder:
        _startItemReorder(item);
      case _EstimateItemAction.duplicate:
        final result = await Navigator.of(context)
            .push<EstimateItemEditorResult>(
              MaterialPageRoute(
                builder: (_) => EstimateItemEditorScreen(
                  initialDraft: item.toDraft(),
                  settings: settings,
                  estimateTitle: controller.info.displayName,
                  estimates: controller.estimates,
                  initialEstimateId: controller.info.id,
                  showOpenEstimateAction: false,
                  unitPriceMasters: controller.unitPriceMasters,
                ),
              ),
            );
        if (result == null || !context.mounted) return;
        try {
          await _selectEstimateDestination(result);
          final addedItem = await controller.add(result.draft);
          final addedToMaster = result.saveToUnitPriceMaster
              ? await controller.addEstimateItemToUnitPriceMasterIfAbsent(
                  result.draft,
                )
              : false;
          if (context.mounted) {
            _showAddedSnackBar(
              context,
              message: addedToMaster ? '見積明細を複製し単価マスタへ追加しました' : '見積明細を複製しました',
              itemId: addedItem.id,
            );
          }
        } catch (_) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context).text('見積明細を複製できませんでした'),
                ),
              ),
            );
          }
        }
      case _EstimateItemAction.edit:
        final result = await Navigator.of(context)
            .push<EstimateItemEditorResult>(
              MaterialPageRoute(
                builder: (_) => EstimateItemEditorScreen(
                  initialDraft: item.toDraft(),
                  settings: settings,
                  isEditing: true,
                  estimateTitle: controller.info.displayName,
                  estimates: controller.estimates,
                  initialEstimateId: controller.info.id,
                  unitPriceMasters: controller.unitPriceMasters,
                ),
              ),
            );
        if (result == null || !context.mounted) return;
        try {
          await controller.update(item.id, result.draft);
          final addedToMaster = result.saveToUnitPriceMaster
              ? await controller.addEstimateItemToUnitPriceMasterIfAbsent(
                  result.draft,
                )
              : false;
          if (context.mounted) {
            showEstimateSuccessSnackBar(
              context,
              content: Text(
                AppLocalizations.of(
                  context,
                ).text(addedToMaster ? '見積明細を更新し単価マスタへ追加しました' : '見積明細を更新しました'),
              ),
            );
          }
        } catch (_) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context).text('見積明細を更新できませんでした'),
                ),
              ),
            );
          }
        }
      case _EstimateItemAction.delete:
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(AppLocalizations.of(context).text('見積明細を削除')),
            content: Text(
              AppLocalizations.of(context).deleteEstimateItemQuestion(
                item.name.isEmpty
                    ? AppLocalizations.of(context).text('名称未入力')
                    : item.name,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(AppLocalizations.of(context).cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(AppLocalizations.of(context).delete),
              ),
            ],
          ),
        );
        if (confirmed != true || !context.mounted) return;
        try {
          await controller.delete(item.id);
          if (context.mounted) {
            showEstimateSuccessSnackBar(
              context,
              content: Text(AppLocalizations.of(context).text('見積明細を削除しました')),
            );
          }
        } catch (_) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context).text('見積明細を削除できませんでした'),
                ),
              ),
            );
          }
        }
    }
  }

  Future<void> _selectEstimateDestination(
    EstimateItemEditorResult result,
  ) async {
    final estimateId = result.estimateId;
    if (estimateId != null && estimateId != controller.info.id) {
      await controller.selectEstimate(estimateId);
    }
  }

  void _showAddedSnackBar(
    BuildContext context, {
    required String message,
    required String itemId,
  }) {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 5),
          persist: false,
          content: Text(
            l10n.estimateItemAddedWithCount(message, controller.items.length),
          ),
          action: SnackBarAction(
            key: const Key('undoEstimateItemAdd'),
            label: AppLocalizations.of(context).text('元に戻す'),
            onPressed: () async {
              try {
                await controller.delete(itemId);
                if (context.mounted) {
                  showEstimateSuccessSnackBar(
                    context,
                    content: Text(
                      AppLocalizations.of(context).text('直前の追加を取り消しました'),
                    ),
                  );
                }
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppLocalizations.of(context).text('追加を取り消せませんでした'),
                      ),
                    ),
                  );
                }
              }
            },
          ),
        ),
      );
  }
}

class _EstimateOutputIcon extends StatelessWidget {
  const _EstimateOutputIcon();

  @override
  Widget build(BuildContext context) => const SizedBox(
    width: 27,
    height: 24,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 0,
          bottom: 0,
          child: Icon(Icons.print_outlined, size: 19),
        ),
        Positioned(
          right: 0,
          top: 0,
          child: Icon(Icons.picture_as_pdf_outlined, size: 15),
        ),
        Positioned(
          right: 0,
          bottom: -1,
          child: Icon(Icons.arrow_downward_rounded, size: 13),
        ),
      ],
    ),
  );
}

String _displayQuantity(double? value) {
  return formatEstimateQuantity(value);
}

class _EstimateTotalsSummary extends StatelessWidget {
  const _EstimateTotalsSummary({
    required this.itemCount,
    required this.subtotal,
    required this.tax,
    required this.grandTotal,
    required this.taxEnabled,
    required this.taxRateBasisPoints,
  });

  final int itemCount;
  final int subtotal;
  final int tax;
  final int grandTotal;
  final bool taxEnabled;
  final int taxRateBasisPoints;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Text(l10n.itemCount(itemCount)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: taxEnabled
                ? [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${l10n.text('税抜合計')}  ¥ ${_money(subtotal.toDouble())}',
                        key: const Key('estimateSubtotalAmount'),
                        style: textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${l10n.taxAmountLabel(formatTaxRateBasisPoints(taxRateBasisPoints))}  ¥ ${_money(tax.toDouble())}',
                        key: const Key('estimateTaxAmount'),
                        style: textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(height: 3),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${l10n.text('税込総額')}  ¥ ${_money(grandTotal.toDouble())}',
                        key: const Key('estimateGrandTotalAmount'),
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ]
                : [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${l10n.estimateTotal}  ¥ ${_money(grandTotal.toDouble())}',
                        key: const Key('estimateGrandTotalAmount'),
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
          ),
        ),
      ],
    );
  }
}

class _EstimateInfoSummary extends StatelessWidget {
  const _EstimateInfoSummary({required this.info, required this.onTap});

  final EstimateInfo info;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final details = <String>['${l10n.text('作成日')}：${_date(info.createdDate)}'];
    return Card(
      key: const Key('estimateInfoSummary'),
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: const Key('editEstimateInfoFromSummary'),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.text(info.displayName),
                key: const Key('estimateInfoSummaryName'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(details.join('　')),
              if (info.notes.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text('${l10n.text('備考')}：${info.notes}'),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

String _date(DateTime date) =>
    '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';

class _EstimateItemCard extends StatelessWidget {
  const _EstimateItemCard({
    required this.item,
    required this.index,
    required this.onAction,
    this.dragHandle,
    this.hideMenu = false,
  });

  final EstimateItem item;
  final int index;
  final ValueChanged<_EstimateItemAction> onAction;
  final Widget? dragHandle;
  final bool hideMenu;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = item.name.isEmpty ? l10n.text('名称未入力') : item.name;
    return Card(
      key: Key('estimateItem$index'),
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: const RoundedRectangleBorder(),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                ?dragHandle,
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (!hideMenu)
                  PopupMenuButton<_EstimateItemAction>(
                    key: Key('estimateItemMenu$index'),
                    onSelected: onAction,
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: _EstimateItemAction.reorder,
                        child: ListTile(
                          leading: const Icon(Icons.settings_outlined),
                          title: Text(l10n.text('項目入替')),
                        ),
                      ),
                      PopupMenuItem(
                        value: _EstimateItemAction.duplicate,
                        child: ListTile(
                          leading: Icon(Icons.copy_outlined),
                          title: Text(l10n.text('複製')),
                        ),
                      ),
                      PopupMenuItem(
                        value: _EstimateItemAction.edit,
                        child: ListTile(
                          leading: Icon(Icons.edit_outlined),
                          title: Text(l10n.text('編集')),
                        ),
                      ),
                      PopupMenuItem(
                        value: _EstimateItemAction.delete,
                        child: ListTile(
                          leading: Icon(Icons.delete_outline),
                          title: Text(l10n.delete),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            if (item.specification.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(item.specification),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text('${_number(item.quantity)} ${item.unit}'.trim()),
                ),
                Text(
                  item.amount == null
                      ? l10n.text('金額未設定')
                      : '¥ ${_money(item.amount!)}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            if (item.description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('${l10n.text('摘要')}：${item.description}'),
            ],
            if (item.trade.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('${l10n.text('工種')}：${item.trade}'),
            ],
          ],
        ),
      ),
    );
  }
}

class _EstimateGroupSection extends StatelessWidget {
  const _EstimateGroupSection({
    required this.group,
    required this.groupIndex,
    required this.itemIndex,
    required this.onAction,
    this.groupDragHandle,
    this.hideItemMenus = false,
  });

  final EstimateItemGroup group;
  final int groupIndex;
  final int Function(EstimateItem item) itemIndex;
  final void Function(EstimateItem item, _EstimateItemAction action) onAction;
  final Widget? groupDragHandle;
  final bool hideItemMenus;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      key: Key('estimateGroup$groupIndex'),
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ColoredBox(
            color: colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  ?groupDragHandle,
                  Expanded(
                    child: Text(
                      group.displayName.isEmpty ? '—' : group.displayName,
                      key: Key('estimateGroupName$groupIndex'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(l10n.itemCount(group.items.length)),
                ],
              ),
            ),
          ),
          for (var index = 0; index < group.items.length; index++) ...[
            if (index > 0) const Divider(height: 1, indent: 12, endIndent: 12),
            _EstimateItemCard(
              item: group.items[index],
              index: itemIndex(group.items[index]),
              onAction: (action) => onAction(group.items[index], action),
              hideMenu: hideItemMenus,
            ),
          ],
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.text('小計'),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  '¥ ${_money(group.subtotal)}',
                  key: Key('estimateGroupSubtotal$groupIndex'),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _number(double? value) {
  if (value == null) return '—';
  return formatEstimateQuantity(value);
}

String _money(num value) {
  final rounded = value.round();
  final digits = rounded.abs().toString();
  final grouped = digits.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  return rounded < 0 ? '-$grouped' : grouped;
}
