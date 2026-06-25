import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
  final TextEditingController _barcodeController = TextEditingController(
    text: '460000000001',
  );

  @override
  void dispose() {
    _barcodeController.dispose();
    super.dispose();
  }

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
          analysisId: analysis.id,
          onScanAnother: () {
            Navigator.of(context).pop();
            ref.read(scanControllerProvider.notifier).reset();
          },
        );
      }
    });

    final scanState = ref.watch(scanControllerProvider);
    final authState = ref.watch(authControllerProvider);
    final user = authState.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: () =>
                ref.read(authControllerProvider.notifier).signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Text(
              'Analyze food composition',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 6),
            Text(
              'Scan a barcode first. If the product is not in the catalog, capture the ingredients label.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            _ModeBanner(isGuest: user?.isGuest ?? true),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: scanState.isLoading
                  ? null
                  : () => context.go('/app/scan/barcode'),
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Scan barcode'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: scanState.isLoading
                  ? null
                  : () async {
                      final session = await ref
                          .read(scanControllerProvider.notifier)
                          .startIngredientSession();
                      if (context.mounted) {
                        context.go('/app/scan/ingredients/${session.id}');
                      }
                    },
              icon: const Icon(Icons.document_scanner_outlined),
              label: const Text('Scan ingredients directly'),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _barcodeController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Enter barcode manually',
                prefixIcon: const Icon(Icons.edit_outlined),
                suffixIcon: IconButton(
                  tooltip: 'Check barcode',
                  onPressed: scanState.isLoading
                      ? null
                      : () => ref
                            .read(scanControllerProvider.notifier)
                            .scanBarcode(_barcodeController.text),
                  icon: const Icon(Icons.arrow_forward),
                ),
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (value) =>
                  ref.read(scanControllerProvider.notifier).scanBarcode(value),
            ),
            const SizedBox(height: 24),
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(isGuest ? Icons.phone_iphone : Icons.cloud_done_outlined),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isGuest
                  ? 'Guest mode: scans are stored on this device.'
                  : 'Signed in: scans are synced through backend.',
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanStatePanel extends StatelessWidget {
  const _ScanStatePanel({required this.scanState});

  final AsyncValue<ScanSession?> scanState;

  @override
  Widget build(BuildContext context) {
    if (scanState.isLoading) {
      return const _StatusCard(
        icon: Icons.sync,
        title: 'Working',
        message: 'Checking product data or preparing OCR.',
      );
    }

    if (scanState.hasError) {
      return _StatusCard(
        icon: Icons.error_outline,
        title: 'Something went wrong',
        message: scanState.error.toString(),
      );
    }

    final session = scanState.value;
    if (session == null) {
      return const _StatusCard(
        icon: Icons.camera_alt_outlined,
        title: 'Ready',
        message: 'Start with barcode scanning for the fastest result.',
      );
    }

    return _StatusCard(
      icon: _iconForStep(session.step),
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

  String _titleForStep(ScanStep step) {
    return switch (step) {
      ScanStep.completed => 'Result ready',
      ScanStep.productMissing => 'Ingredients required',
      ScanStep.ocrReview => 'Review OCR text',
      ScanStep.failed => 'Scan failed',
      _ => 'Current step: ${step.name}',
    };
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(message),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
