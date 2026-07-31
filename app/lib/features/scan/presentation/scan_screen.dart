import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../analysis/presentation/analysis_result_bottom_sheet.dart';
import '../../auth/presentation/auth_controller.dart';
import '../domain/scan_session.dart';
import 'scan_controller.dart';

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  @override
  Widget build(BuildContext context) {
    ref.listen(scanControllerProvider, (previous, next) {
      if (ModalRoute.of(context)?.isCurrent != true) {
        return;
      }

      final session = next.value;
      final analysis = session?.analysis;

      if (session?.step == ScanStep.productMissing) {
        context.go('/app/scan/ingredients/${session!.id}');
      }

      if (session?.step == ScanStep.completed && analysis != null) {
        showAnalysisResultBottomSheet(
          context: context,
          analysisId: analysis.barcode,
          onScanAnother: () {
            ref.read(scanControllerProvider.notifier).reset();
            context.go('/app/scan');
          },
        );
      }
    });

    final scanState = ref.watch(scanControllerProvider);
    final authState = ref.watch(authControllerProvider);
    final user = authState.value;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Scan')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.md,
            AppSpacing.screenPadding,
            AppSpacing.xxl,
          ),
          children: [
            Text(
              'Analyze food composition',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Scan a barcode or capture the ingredients label to get a health score and risk analysis.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            _ModeBanner(isGuest: user?.isGuest ?? true),
            const SizedBox(height: AppSpacing.xl),
            _ScanActionRow(
              isLoading: scanState.isLoading,
              onBarcodeScan: () => context.go('/app/scan/barcode'),
              onIngredientsScan: () async {
                // Сбрасываем предыдущую сессию перед созданием новой
                ref.read(scanControllerProvider.notifier).reset();

                final session = await ref
                    .read(scanControllerProvider.notifier)
                    .startIngredientSession();
                if (!context.mounted) return;
                context.go('/app/scan/ingredients/${session.id}');
              },
            ),
            const SizedBox(height: AppSpacing.xxl),
            _ManualBarcodeSection(
              isLoading: scanState.isLoading,
              onLookup: (barcode) => ref
                  .read(scanControllerProvider.notifier)
                  .scanBarcode(barcode),
            ),
            const SizedBox(height: AppSpacing.xxl),
            _ScanStatePanel(scanState: scanState),
          ],
        ),
      ),
    );
  }
}

class _ModeBanner extends StatelessWidget {
  const _ModeBanner({required this.isGuest});

  final bool isGuest;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isGuest
            ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
            : theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: AppRadius.mdAll,
        border: Border.all(
          color: isGuest
              ? theme.colorScheme.outlineVariant.withValues(alpha: 0.5)
              : theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isGuest ? Icons.phone_iphone : Icons.cloud_done_outlined,
            size: 20,
            color: isGuest
                ? theme.colorScheme.onSurfaceVariant
                : theme.colorScheme.primary,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              isGuest
                  ? 'Guest mode — scans are stored on this device.'
                  : 'Signed in — scans are synced to your account.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isGuest
                    ? theme.colorScheme.onSurfaceVariant
                    : theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanActionRow extends StatelessWidget {
  const _ScanActionRow({
    required this.isLoading,
    required this.onBarcodeScan,
    required this.onIngredientsScan,
  });

  final bool isLoading;
  final VoidCallback onBarcodeScan;
  final VoidCallback onIngredientsScan;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ScanOptionCard(
            icon: Icons.qr_code_scanner,
            title: 'Barcode',
            subtitle: 'Fast lookup',
            onTap: isLoading ? null : onBarcodeScan,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _ScanOptionCard(
            icon: Icons.document_scanner,
            title: 'Ingredients',
            subtitle: 'OCR scan',
            onTap: isLoading
                ? null
                : onIngredientsScan, // Добавлена проверка isLoading
          ),
        ),
      ],
    );
  }
}

class _ScanOptionCard extends StatelessWidget {
  const _ScanOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDisabled = onTap == null;

    return Material(
      color: isDisabled
          ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
          : theme.colorScheme.primaryContainer.withValues(alpha: 0.25),
      borderRadius: AppRadius.mdAll,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.mdAll,
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.xl,
            horizontal: AppSpacing.lg,
          ),
          decoration: BoxDecoration(
            borderRadius: AppRadius.mdAll,
            border: Border.all(
              color: isDisabled
                  ? theme.colorScheme.outlineVariant.withValues(alpha: 0.3)
                  : theme.colorScheme.primary.withValues(alpha: 0.25),
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 32,
                color: isDisabled
                    ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)
                    : theme.colorScheme.primary,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDisabled
                      ? theme.colorScheme.onSurfaceVariant
                      : theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ManualBarcodeSection extends StatefulWidget {
  const _ManualBarcodeSection({
    required this.isLoading,
    required this.onLookup,
  });

  final bool isLoading;
  final ValueChanged<String> onLookup;

  @override
  State<_ManualBarcodeSection> createState() => _ManualBarcodeSectionState();
}

class _ManualBarcodeSectionState extends State<_ManualBarcodeSection> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: AppRadius.mdAll,
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter barcode manually',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _controller,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 16,
                      letterSpacing: 1.2,
                    ),
                    decoration: const InputDecoration(
                      hintText: '460000000001',
                      prefixIcon: Icon(Icons.numbers, size: 20),
                      isDense: true,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Enter a barcode';
                      }
                      if (value.trim().length < 8) {
                        return 'Too short';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                IntrinsicWidth(
                  child: FilledButton.tonalIcon(
                    onPressed: widget.isLoading
                        ? null
                        : () {
                            if (_formKey.currentState!.validate()) {
                              widget.onLookup(_controller.text);
                            }
                          },
                    icon: const Icon(Icons.search, size: 20),
                    label: const Text('Check'),
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

class _ScanStatePanel extends StatelessWidget {
  const _ScanStatePanel({required this.scanState});

  final AsyncValue<ScanSession?> scanState;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (scanState.isLoading) {
      return _StatusCard(
        icon: Icons.sync,
        iconColor: theme.colorScheme.primary,
        title: 'Working',
        message: 'Checking product data or preparing OCR.',
      );
    }

    if (scanState.hasError) {
      return _StatusCard(
        icon: Icons.error_outline,
        iconColor: theme.colorScheme.error,
        title: 'Something went wrong',
        message: scanState.error.toString(),
      );
    }

    final session = scanState.value;
    if (session == null) {
      return _StatusCard(
        icon: Icons.camera_alt_outlined,
        iconColor: theme.colorScheme.onSurfaceVariant,
        title: 'Ready',
        message: 'Start with barcode scanning for the fastest result.',
      );
    }

    return _StatusCard(
      icon: _iconForStep(session.step),
      iconColor: _colorForStep(session.step, theme),
      title: _titleForStep(session.step),
      message: session.product?.name ?? 'Continue the scan flow.',
    );
  }

  IconData _iconForStep(ScanStep step) {
    return switch (step) {
      ScanStep.completed => Icons.check_circle_outline,
      ScanStep.productMissing => Icons.document_scanner_outlined,
      ScanStep.failed => Icons.error_outline,
      _ => Icons.info_outline,
    };
  }

  Color _colorForStep(ScanStep step, ThemeData theme) {
    return switch (step) {
      ScanStep.completed => AppColors.good,
      ScanStep.failed => theme.colorScheme.error,
      _ => theme.colorScheme.onSurfaceVariant,
    };
  }

  String _titleForStep(ScanStep step) {
    return switch (step) {
      ScanStep.completed => 'Result ready',
      ScanStep.productMissing => 'Ingredients required',
      ScanStep.failed => 'Scan failed',
      _ => 'Current step: ${step.name}',
    };
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: AppRadius.smAll,
              ),
              child: Icon(icon, size: 22, color: iconColor),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    message,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
