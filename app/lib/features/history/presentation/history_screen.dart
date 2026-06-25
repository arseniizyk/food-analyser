import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_loading_view.dart';
import '../../analysis/domain/analysis.dart';
import '../../analysis/presentation/analysis_result_bottom_sheet.dart';
import 'history_controller.dart';
import 'history_item_tile.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  _HistoryFilter _filter = _HistoryFilter.all;

  @override
  Widget build(BuildContext context) {
    final historyState = ref.watch(historyControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () =>
                ref.read(historyControllerProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: historyState.when(
        loading: () => const AppLoadingView(message: 'Loading history...'),
        error: (error, stackTrace) => AppErrorView(
          message: error.toString(),
          onRetry: () => ref.read(historyControllerProvider.notifier).refresh(),
        ),
        data: (items) {
          final filteredItems = _applyFilter(items);

          if (items.isEmpty) {
            return _EmptyHistory(onScan: () => context.go('/app/scan'));
          }

          return RefreshIndicator(
            onRefresh: () =>
                ref.read(historyControllerProvider.notifier).refresh(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                _SyncBanner(isOffline: false),
                const SizedBox(height: 12),
                _FilterBar(
                  selected: _filter,
                  onSelected: (filter) => setState(() => _filter = filter),
                ),
                const SizedBox(height: 12),
                if (filteredItems.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: Text('No scans match this filter.')),
                  )
                else
                  ...filteredItems.map(
                    (analysis) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: HistoryItemTile(
                        analysis: analysis,
                        onTap: () => showAnalysisResultBottomSheet(
                          context: context,
                          analysisId: analysis.id,
                          onScanAnother: () {
                            Navigator.of(context).pop();
                            context.go('/app/scan');
                          },
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Analysis> _applyFilter(List<Analysis> items) {
    return switch (_filter) {
      _HistoryFilter.all => items,
      _HistoryFilter.good =>
        items.where((item) => item.score.value >= 80).toList(),
      _HistoryFilter.moderate =>
        items
            .where((item) => item.score.value >= 55 && item.score.value < 80)
            .toList(),
      _HistoryFilter.risky =>
        items.where((item) => item.score.value < 55).toList(),
    };
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.selected, required this.onSelected});

  final _HistoryFilter selected;
  final ValueChanged<_HistoryFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _HistoryFilter.values.map((filter) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: selected == filter,
              onSelected: (_) => onSelected(filter),
              label: Text(filter.label),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SyncBanner extends StatelessWidget {
  const _SyncBanner({required this.isOffline});

  final bool isOffline;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(isOffline ? Icons.cloud_off : Icons.cloud_done_outlined),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isOffline
                  ? 'Showing cached scans. New results will sync later.'
                  : 'History is up to date for the current account mode.',
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory({required this.onScan});

  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.history, size: 48),
            const SizedBox(height: 12),
            Text('No scans yet', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            const Text(
              'Analyze a product to see score, risks, and details here.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onScan,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Scan product'),
            ),
          ],
        ),
      ),
    );
  }
}

enum _HistoryFilter {
  all('All'),
  good('Good'),
  moderate('Moderate'),
  risky('Risky');

  const _HistoryFilter(this.label);

  final String label;
}
