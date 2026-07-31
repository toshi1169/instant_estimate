import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../application/calculator_controller.dart';

class CalculatorHistoryScreen extends StatefulWidget {
  const CalculatorHistoryScreen({
    required this.controller,
    required this.onMenuPressed,
    super.key,
  });

  final CalculatorController controller;
  final Future<void> Function(CalculationHistoryEntry entry) onMenuPressed;

  @override
  State<CalculatorHistoryScreen> createState() =>
      _CalculatorHistoryScreenState();
}

class _CalculatorHistoryScreenState extends State<CalculatorHistoryScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<CalculationHistoryEntry> _filteredHistory(
    List<CalculationHistoryEntry> history,
  ) {
    final query = _query.trim().toLowerCase();
    final newestFirst = history.reversed;
    if (query.isEmpty) return newestFirst.toList(growable: false);

    return newestFirst
        .where((entry) {
          return <String?>[
            entry.expression,
            entry.result,
            entry.decimalResult,
            entry.improperFractionResult,
            entry.mixedFractionResult,
          ].whereType<String>().any(
            (value) => value.toLowerCase().contains(query),
          );
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final history = _filteredHistory(widget.controller.history);
        return Scaffold(
          appBar: AppBar(
            title: const Text('計算履歴'),
            actions: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Text('${widget.controller.history.length}件'),
                ),
              ),
            ],
          ),
          body: SafeArea(
            top: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  child: TextField(
                    key: const Key('historySearchField'),
                    controller: _searchController,
                    onChanged: (value) => setState(() => _query = value),
                    decoration: InputDecoration(
                      hintText: '計算式・解を検索',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              tooltip: '検索を消去',
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _query = '');
                              },
                              icon: const Icon(Icons.close),
                            ),
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                Expanded(
                  child: history.isEmpty
                      ? _EmptyHistory(hasQuery: _query.trim().isNotEmpty)
                      : ListView.builder(
                          key: const Key('fullHistoryList'),
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                          itemCount: history.length,
                          itemBuilder: (context, index) => _HistoryCard(
                            entry: history[index],
                            index: index,
                            onMenuPressed: widget.onMenuPressed,
                          ),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory({required this.hasQuery});

  final bool hasQuery;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        hasQuery ? '一致する履歴がありません' : '計算履歴はまだありません',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.entry,
    required this.index,
    required this.onMenuPressed,
  });

  final CalculationHistoryEntry entry;
  final int index;
  final Future<void> Function(CalculationHistoryEntry entry) onMenuPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fractionRows = <(String, String?)>[
      ('仮分数', entry.improperFractionResult),
      ('帯分数', entry.mixedFractionResult),
    ].where((row) => row.$2 != null).toList(growable: false);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 6, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    entry.expression,
                    key: Key('fullHistoryExpression$index'),
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  key: Key('fullHistoryMenuButton$index'),
                  tooltip: '履歴メニュー',
                  onPressed: () => onMenuPressed(entry),
                  icon: const Icon(Icons.more_vert),
                ),
              ],
            ),
            _ResultRow(label: '小数', value: entry.decimalResult),
            for (final row in fractionRows)
              _ResultRow(label: row.$1, value: row.$2!),
          ],
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 5, right: 10),
      child: Row(
        children: [
          SizedBox(
            width: 58,
            child: Text(label, style: Theme.of(context).textTheme.labelMedium),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.accent,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
