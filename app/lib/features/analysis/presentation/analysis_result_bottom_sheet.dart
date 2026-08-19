import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_loading_view.dart';
import '../domain/analysis.dart';
import 'analysis_controller.dart';

Future<void> showAnalysisResultBottomSheet({
  required BuildContext context,
  required String barcode,
  Analysis? analysis,
  VoidCallback? onScanAnother,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) {
      return AnalysisResultBottomSheet(
        barcode: barcode,
        initialAnalysis: analysis,
        onScanAnother: onScanAnother,
      );
    },
  );
}

class AnalysisResultBottomSheet extends ConsumerWidget {
  const AnalysisResultBottomSheet({
    required this.barcode,
    this.initialAnalysis,
    this.onScanAnother,
    super.key,
  });

  final String barcode;
  final Analysis? initialAnalysis;
  final VoidCallback? onScanAnother;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initialAnalysis = this.initialAnalysis;
    if (initialAnalysis != null) {
      return SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.88,
        child: _ResultBody(
          analysis: initialAnalysis,
          onScanAnother: onScanAnother,
        ),
      );
    }

    final analysisState = ref.watch(analysisControllerProvider(barcode));

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

class _ResultBody extends StatefulWidget {
  const _ResultBody({required this.analysis, required this.onScanAnother});

  final Analysis analysis;
  final VoidCallback? onScanAnother;

  @override
  State<_ResultBody> createState() => _ResultBodyState();
}

class _ResultBodyState extends State<_ResultBody>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scoreController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..forward();

  late final CurvedAnimation _scoreAnimation = CurvedAnimation(
    parent: _scoreController,
    curve: Curves.easeOutCubic,
  );

  @override
  void dispose() {
    _scoreAnimation.dispose();
    _scoreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final analysis = widget.analysis;
    final onScanAnother = widget.onScanAnother;
    final color = AppColors.scoreColor(analysis.score, context);

    final items = <_ResultItem>[
      _ScoreItem(
        score: analysis.score,
        color: color,
        animation: _scoreAnimation,
      ),
      const _SpaceItem(height: AppSpacing.xl),
      const _HeaderItem(title: 'Summary'),
      const _SpaceItem(height: AppSpacing.sm),
      ...analysis.summary.map((item) => _SummaryText(item: item)),
      const _SpaceItem(height: AppSpacing.lg),
      const _HeaderItem(title: 'Ingredient risks'),
      const _SpaceItem(height: AppSpacing.sm),
      if (analysis.risks.isEmpty)
        const _NoRisksItem()
      else
        ...analysis.risks.map((risk) => _RiskItem(risk: risk)),
      const _SpaceItem(height: AppSpacing.lg),
      const _HeaderItem(title: 'Ingredients'),
      const _SpaceItem(height: AppSpacing.sm),
      ...analysis.ingredients.map(
        (ingredient) => _IngredientItem(ingredient: ingredient),
      ),
      const _SpaceItem(height: AppSpacing.xxl),
      _ScanAnotherItem(onScanAnother: onScanAnother),
    ];

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      child: Column(
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
            child: Theme(
              data: theme.copyWith(dividerColor: Colors.transparent),
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPadding,
                  0,
                  AppSpacing.screenPadding,
                  AppSpacing.screenPadding,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) => items[index].build(context),
              ),
            ),
          ),
        ],
      ),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, AppSpacing.sm * (1 - value)),
            child: child,
          ),
        );
      },
    );
  }
}

sealed class _ResultItem {
  const _ResultItem();

  Widget build(BuildContext context);
}

class _SpaceItem extends _ResultItem {
  const _SpaceItem({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(height: height);
}

class _HeaderItem extends _ResultItem {
  const _HeaderItem({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => _SectionHeader(title: title);
}

class _ScoreItem extends _ResultItem {
  const _ScoreItem({
    required this.score,
    required this.color,
    required this.animation,
  });

  final int score;
  final Color color;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) =>
      _ScoreCard(score: score, color: color, animation: animation);
}

class _SummaryText extends _ResultItem {
  const _SummaryText({required this.item});

  final String item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, size: 18, color: AppColors.good),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(item, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

class _RiskItem extends _ResultItem {
  const _RiskItem({required this.risk});

  final Risk risk;

  @override
  Widget build(BuildContext context) => _RiskTile(risk: risk);
}

class _IngredientItem extends _ResultItem {
  const _IngredientItem({required this.ingredient});

  final Ingredient ingredient;

  @override
  Widget build(BuildContext context) => _IngredientTile(ingredient: ingredient);
}

class _NoRisksItem extends _ResultItem {
  const _NoRisksItem();

  @override
  Widget build(BuildContext context) => const _NoRisksBanner();
}

class _ScanAnotherItem extends _ResultItem {
  const _ScanAnotherItem({required this.onScanAnother});

  final VoidCallback? onScanAnother;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onScanAnother != null
          ? () {
              Navigator.of(context).pop();
              onScanAnother!();
            }
          : null,
      icon: const Icon(Icons.qr_code_scanner),
      label: const Text('Scan another product'),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({
    required this.score,
    required this.color,
    required this.animation,
  });

  final int score;
  final Color color;
  final Animation<double> animation;

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
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) {
          final value = (score * animation.value).round();
          return Row(
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
                        value: value / 100,
                        strokeWidth: 6,
                        backgroundColor: color.withValues(alpha: 0.15),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Text(
                      value.toString(),
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
                      'Health score: $value/100',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
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
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
    );
  }
}

class _NoRisksBanner extends StatelessWidget {
  const _NoRisksBanner();

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
          Icon(Icons.shield_outlined, color: AppColors.good, size: 20),
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

  final Risk risk;

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
      child: Material(
        type: MaterialType.transparency,
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
          leading: Icon(
            _iconForRisk(risk.severity),
            color: riskColor,
            size: 22,
          ),
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
              child: Text(risk.description, style: theme.textTheme.bodyMedium),
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

class _IngredientTile extends StatelessWidget {
  const _IngredientTile({required this.ingredient});

  final Ingredient ingredient;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final riskColor = _colorForRisk(ingredient.risk);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: riskColor.withValues(alpha: 0.05),
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: riskColor.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Icon(_iconForRisk(ingredient.risk), color: riskColor, size: 20),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ingredient.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (ingredient.description != null &&
                    ingredient.description!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    ingredient.description!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: riskColor.withValues(alpha: 0.12),
              borderRadius: AppRadius.smAll,
            ),
            child: Text(
              ingredient.risk.name.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: riskColor,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _colorForRisk(IngredientRiskLevel level) {
    return switch (level) {
      IngredientRiskLevel.safe => AppColors.good,
      IngredientRiskLevel.caution => AppColors.riskMedium,
      IngredientRiskLevel.dangerous => AppColors.riskHigh,
    };
  }

  IconData _iconForRisk(IngredientRiskLevel level) {
    return switch (level) {
      IngredientRiskLevel.safe => Icons.check_circle_outline,
      IngredientRiskLevel.caution => Icons.warning_amber_outlined,
      IngredientRiskLevel.dangerous => Icons.report_problem_outlined,
    };
  }
}
