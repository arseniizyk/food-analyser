import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
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
      height: MediaQuery.sizeOf(context).height * 0.88,
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
    final theme = Theme.of(context);
    final color = AppColors.scoreColor(analysis.score.value, context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            0,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Analysis result',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Barcode ${analysis.barcode}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
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
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenPadding,
              0,
              AppSpacing.screenPadding,
              AppSpacing.screenPadding,
            ),
            children: [
              _ScoreCard(score: analysis.score.value, color: color),
              const SizedBox(height: AppSpacing.xl),
              _SectionHeader(title: 'Summary'),
              const SizedBox(height: AppSpacing.sm),
              ...analysis.summary.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 18,
                        color: AppColors.good,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          item,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _SectionHeader(title: 'Ingredient risks'),
              const SizedBox(height: AppSpacing.sm),
              if (analysis.risks.isEmpty)
                _NoRisksBanner()
              else
                ...analysis.risks.map((risk) => _RiskTile(risk: risk)),
              const SizedBox(height: AppSpacing.xxl),
              FilledButton.icon(
                onPressed: onScanAnother != null
                    ? () {
                        Navigator.of(context).pop();
                        onScanAnother!();
                      }
                    : null,
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Scan another product'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.score, required this.color});

  final int score;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            height: 72,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 72,
                  height: 72,
                  child: CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 6,
                    backgroundColor: color.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Text(
                  score.toString(),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xl),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppColors.scoreLabel(score),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Health score: $score/100',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _NoRisksBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.good.withValues(alpha: 0.08),
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: AppColors.good.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.shield_outlined,
            color: AppColors.good,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'No notable risks found in the ingredients.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.good,
              ),
            ),
          ),
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
    final theme = Theme.of(context);
    final riskColor = _colorForRisk(risk.severity);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: riskColor.withValues(alpha: 0.06),
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: riskColor.withValues(alpha: 0.15)),
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xs,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          leading: Icon(_iconForRisk(risk.severity), color: riskColor, size: 22),
          title: Text(
            risk.title,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            risk.severity.name.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: riskColor,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                risk.description,
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _colorForRisk(RiskLevel level) {
    return switch (level) {
      RiskLevel.low => AppColors.riskLow,
      RiskLevel.medium => AppColors.riskMedium,
      RiskLevel.high => AppColors.riskHigh,
    };
  }

  IconData _iconForRisk(RiskLevel level) {
    return switch (level) {
      RiskLevel.low => Icons.info_outline,
      RiskLevel.medium => Icons.warning_amber_outlined,
      RiskLevel.high => Icons.report_problem_outlined,
    };
  }
}
