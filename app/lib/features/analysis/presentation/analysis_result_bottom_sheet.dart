import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_loading_view.dart';
import '../domain/analysis.dart';
import 'analysis_controller.dart';

Future<void> showAnalysisResultBottomSheet({
  required BuildContext context,
  required String analysisId,
  VoidCallback? onScanAnother,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) {
      return AnalysisResultBottomSheet(
        analysisId: analysisId,
        onScanAnother: onScanAnother,
      );
    },
  );
}

class AnalysisResultBottomSheet extends ConsumerWidget {
  const AnalysisResultBottomSheet({
    required this.analysisId,
    this.onScanAnother,
    super.key,
  });

  final String analysisId;
  final VoidCallback? onScanAnother;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analysisState = ref.watch(analysisControllerProvider(analysisId));

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.86,
      child: analysisState.when(
        loading: () => const AppLoadingView(message: 'Analyzing product...'),
        error: (error, stackTrace) => AppErrorView(message: error.toString()),
        data: (analysis) {
          if (analysis == null) {
            return const AppErrorView(message: 'Analysis was not found.');
          }

          return _ResultBody(analysis: analysis, onScanAnother: onScanAnother);
        },
      ),
    );
  }
}

class _ResultBody extends StatelessWidget {
  const _ResultBody({required this.analysis, required this.onScanAnother});

  final Analysis analysis;
  final VoidCallback? onScanAnother;

  @override
  Widget build(BuildContext context) {
    final color = _scoreColor(context, analysis.score.value);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 12, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Analysis result',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 2),
                    Text('Product ${analysis.productId}'),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Close',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withValues(alpha: 0.24)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 38,
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      child: Text(
                        analysis.score.value.toString(),
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _scoreTitle(analysis.score.value),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          Text('Health score: ${analysis.score.label}'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text('Summary', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...analysis.summary.map(
                (item) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.check_circle_outline),
                  title: Text(item),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Ingredient risks',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (analysis.risks.isEmpty)
                const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.verified_outlined),
                  title: Text('No notable risks found.'),
                )
              else
                ...analysis.risks.map((risk) => _RiskTile(risk: risk)),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onScanAnother,
                      icon: const Icon(Icons.qr_code_scanner),
                      label: const Text('Scan another'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _scoreColor(BuildContext context, int value) {
    if (value >= 80) {
      return const Color(0xFF1F7A4D);
    }
    if (value >= 55) {
      return const Color(0xFFB7791F);
    }
    return Theme.of(context).colorScheme.error;
  }

  String _scoreTitle(int value) {
    if (value >= 80) {
      return 'Good composition';
    }
    if (value >= 55) {
      return 'Needs attention';
    }
    return 'Risky composition';
  }
}

class _RiskTile extends StatelessWidget {
  const _RiskTile({required this.risk});

  final IngredientRisk risk;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      leading: Icon(_iconForRisk(risk.level)),
      title: Text(risk.ingredient),
      subtitle: Text(risk.level.name),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      children: [
        Align(alignment: Alignment.centerLeft, child: Text(risk.reason)),
      ],
    );
  }

  IconData _iconForRisk(RiskLevel level) {
    return switch (level) {
      RiskLevel.low => Icons.info_outline,
      RiskLevel.medium => Icons.warning_amber_outlined,
      RiskLevel.high => Icons.report_problem_outlined,
    };
  }
}
