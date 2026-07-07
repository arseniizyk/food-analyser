import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_loading_view.dart';
import '../domain/analysis.dart';
import 'analysis_controller.dart';

class AnalysisResultScreen extends ConsumerWidget {
  const AnalysisResultScreen({required this.analysisId, super.key});

  final String analysisId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analysisState = ref.watch(analysisControllerProvider(analysisId));

    return Scaffold(
      appBar: AppBar(title: const Text('Result')),
      body: analysisState.when(
        loading: () => const AppLoadingView(message: 'Loading result...'),
        error: (error, stackTrace) => AppErrorView(message: error.toString()),
        data: (analysis) {
          if (analysis == null) {
            return const AppErrorView(message: 'Analysis was not found.');
          }

          return _AnalysisResultBody(analysis: analysis);
        },
      ),
    );
  }
}

class _AnalysisResultBody extends StatelessWidget {
  const _AnalysisResultBody({required this.analysis});

  final Analysis analysis;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 34,
                    child: Text(
                      analysis.score.value.toString(),
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Health score',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text('Label: ${analysis.score.label}'),
                        Text('Barcode: ${analysis.barcode}'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Summary', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...analysis.summary.map(
            (item) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.check_circle_outline),
              title: Text(item),
            ),
          ),
          const SizedBox(height: 16),
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
        ],
      ),
    );
  }
}

class _RiskTile extends StatelessWidget {
  const _RiskTile({required this.risk});

  final IngredientRisk risk;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(_iconForRisk(risk.level)),
        title: Text(risk.ingredient),
        subtitle: Text(risk.reason),
        trailing: Text(risk.level.name),
      ),
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
