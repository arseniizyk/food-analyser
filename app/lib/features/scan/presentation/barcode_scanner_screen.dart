import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../analysis/presentation/analysis_result_bottom_sheet.dart';
import '../domain/scan_session.dart';
import 'scan_controller.dart';

class BarcodeScannerScreen extends ConsumerStatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  ConsumerState<BarcodeScannerScreen> createState() =>
      _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends ConsumerState<BarcodeScannerScreen> {
  bool _flashEnabled = false;

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
            context.go('/app/scan/barcode');
          },
        );
      }
    });

    final scanState = ref.watch(scanControllerProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF101815),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: _CameraPreviewMock(isLoading: scanState.isLoading),
            ),
            Positioned(
              left: 8,
              right: 8,
              top: 4,
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Back',
                    color: Colors.white,
                    onPressed: () => context.go('/app/scan'),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const Expanded(
                    child: Text(
                      'Scan barcode',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Flash',
                    color: Colors.white,
                    onPressed: () =>
                        setState(() => _flashEnabled = !_flashEnabled),
                    icon: Icon(
                      _flashEnabled ? Icons.flash_on : Icons.flash_off,
                    ),
                  ),
                ],
              ),
            ),
            Center(
              child: AspectRatio(
                aspectRatio: 1.65,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 36),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text(
                      'Place barcode inside the frame',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 24,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (scanState.isLoading)
                    const _ScannerStatus(message: 'Checking product...')
                  else if (scanState.hasError)
                    _ScannerStatus(message: scanState.error.toString())
                  else
                    const _ScannerStatus(
                      message: 'Camera ready. Use demo buttons below.',
                    ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: scanState.isLoading
                              ? null
                              : () => ref
                                    .read(scanControllerProvider.notifier)
                                    .scanBarcode('460000000001'),
                          icon: const Icon(Icons.qr_code),
                          label: const Text('Demo found'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white70),
                          ),
                          onPressed: scanState.isLoading
                              ? null
                              : () => ref
                                    .read(scanControllerProvider.notifier)
                                    .scanBarcode(
                                      'unknown-${DateTime.now().second}',
                                    ),
                          icon: const Icon(Icons.search_off),
                          label: const Text('Not found'),
                        ),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: scanState.isLoading
                        ? null
                        : () => _showManualBarcodeSheet(context),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Enter barcode manually'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showManualBarcodeSheet(BuildContext context) async {
    final controller = TextEditingController(text: '460000000001');

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            0,
            20,
            MediaQuery.viewInsetsOf(context).bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Manual barcode',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Barcode',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  ref
                      .read(scanControllerProvider.notifier)
                      .scanBarcode(controller.text);
                },
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Check product'),
              ),
            ],
          ),
        );
      },
    );

    controller.dispose();
  }
}

class _CameraPreviewMock extends StatelessWidget {
  const _CameraPreviewMock({required this.isLoading});

  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF18231F), Color(0xFF0E1412), Color(0xFF26352E)],
        ),
      ),
      child: Center(
        child: isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Icon(
                Icons.qr_code_scanner,
                color: Colors.white24,
                size: 160,
              ),
      ),
    );
  }
}

class _ScannerStatus extends StatelessWidget {
  const _ScannerStatus({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.54),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white),
      ),
    );
  }
}
