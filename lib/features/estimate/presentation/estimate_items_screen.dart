import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/localization/app_localizations.dart';
import '../../advertising/domain/rewarded_ad_policy.dart';
import '../../settings/domain/app_settings.dart';
import '../../settings/domain/company_profile.dart';
import '../../settings/presentation/company_profile_editor_screen.dart';
import '../application/estimate_controller.dart';
import '../application/estimate_export_file_name.dart';
import '../application/estimate_pdf_export.dart';
import '../application/estimate_pdf_share.dart';
import '../application/estimate_table_export.dart';
import '../domain/estimate_item.dart';
import '../domain/estimate_item_draft.dart';
import '../domain/estimate_item_group.dart';
import '../domain/estimate_info.dart';
import 'duplicate_estimate_item_dialog.dart';
import 'estimate_info_editor_screen.dart';
import 'estimate_item_editor_screen.dart';
import 'merge_estimate_quantity_dialog.dart';

enum _EstimateItemAction { duplicate, edit, delete }

class EstimateItemsScreen extends StatefulWidget {
  const EstimateItemsScreen({
    required this.controller,
    this.settings = const AppSettings(),
    this.onSettingsChanged,
    this.onRequestRewardedAdAccess,
    this.sharePdfBytes = shareEstimatePdfBytes,
    super.key,
  });

  final EstimateController controller;
  final AppSettings settings;
  final ValueChanged<AppSettings>? onSettingsChanged;
  final Future<bool> Function(RewardedAdEntryPoint)? onRequestRewardedAdAccess;
  final EstimatePdfBytesSharer sharePdfBytes;

  @override
  State<EstimateItemsScreen> createState() => _EstimateItemsScreenState();
}

class _EstimateItemsScreenState extends State<EstimateItemsScreen> {
  late AppSettings _settings = widget.settings;

  EstimateController get controller => widget.controller;
  AppSettings get settings => _settings;
  Future<bool> Function(RewardedAdEntryPoint)? get onRequestRewardedAdAccess =>
      widget.onRequestRewardedAdAccess;
  EstimatePdfBytesSharer get sharePdfBytes => widget.sharePdfBytes;

  @override
  void didUpdateWidget(EstimateItemsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings != widget.settings) _settings = widget.settings;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        actions: [
          TextButton(
            key: const Key('estimateOutputButton'),
            style: TextButton.styleFrom(
              foregroundColor: IconTheme.of(context).color,
              minimumSize: const Size(86, 48),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              tapTargetSize: MaterialTapTargetSize.padded,
            ),
            onPressed: () => _shareEstimatePdf(context),
            child: SizedBox(
              width: 78,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  children: [
                    const _EstimateOutputIcon(),
                    const SizedBox(width: 5),
                    Text(l10n.estimateOutput, maxLines: 1),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            key: const Key('copyEstimateTable'),
            tooltip: l10n.copyTableForExcel,
            onPressed: () => _copyTable(context),
            icon: const Icon(Icons.table_view_outlined),
          ),
          IconButton(
            key: const Key('editEstimateInfo'),
            tooltip: l10n.text('見積基本情報'),
            onPressed: () => _editInfo(context),
            icon: const Icon(Icons.edit_note_outlined),
          ),
          IconButton(
            key: const Key('editCompanyProfileFromEstimateItems'),
            tooltip: l10n.companyProfile,
            onPressed: () => _editCompanyProfile(context),
            icon: const Icon(Icons.business_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
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
                  ),
                ),
                const Divider(height: 1),
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
        ClipboardData(text: buildEstimateTableText(controller.items)),
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(
                context,
              ).copiedEstimateDetails(controller.items.length),
            ),
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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context).text(
                    addedToMaster ? '既存明細を更新し単価マスタへ追加しました' : '既存の見積明細を更新しました',
                  ),
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
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    addedToMaster
                        ? AppLocalizations.of(
                            context,
                          ).text('数量を加算し単価マスタへ追加しました')
                        : AppLocalizations.of(context).mergedEstimateQuantity(
                            _displayQuantity(merged.quantity),
                          ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).text('見積基本情報を保存しました')),
          ),
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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context).text(
                    addedToMaster ? '見積明細を更新し単価マスタへ追加しました' : '見積明細を更新しました',
                  ),
                ),
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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context).text('見積明細を削除しました')),
              ),
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppLocalizations.of(context).text('直前の追加を取り消しました'),
                      ),
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
  if (value == null) return '';
  return value == value.truncateToDouble()
      ? value.toInt().toString()
      : value.toString();
}

class _EstimateTotalsSummary extends StatelessWidget {
  const _EstimateTotalsSummary({
    required this.itemCount,
    required this.subtotal,
    required this.tax,
    required this.grandTotal,
  });

  final int itemCount;
  final int subtotal;
  final int tax;
  final int grandTotal;

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
            children: [
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
                  '${l10n.text('消費税（10%）')}  ¥ ${_money(tax.toDouble())}',
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
  });

  final EstimateItem item;
  final int index;
  final ValueChanged<_EstimateItemAction> onAction;

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
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                PopupMenuButton<_EstimateItemAction>(
                  key: Key('estimateItemMenu$index'),
                  onSelected: onAction,
                  itemBuilder: (_) => [
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
  });

  final EstimateItemGroup group;
  final int groupIndex;
  final int Function(EstimateItem item) itemIndex;
  final void Function(EstimateItem item, _EstimateItemAction action) onAction;

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
  if (value == value.truncateToDouble()) return value.toInt().toString();
  return value.toString();
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
