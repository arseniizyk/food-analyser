import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../domain/scan_session.dart';
import 'scan_controller.dart';

class IngredientCameraScreen extends ConsumerStatefulWidget {
  const IngredientCameraScreen({required this.sessionId, super.key});

  final String sessionId;

  @override
  ConsumerState<IngredientCameraScreen> createState() =>
      _IngredientCameraScreenState();
}

class _IngredientCameraScreenState
    extends ConsumerState<IngredientCameraScreen> {
  bool _flashEnabled = false;
  bool _hasPreview = false;

  @override
  Widget build(BuildContext context) {
    ref.listen(scanControllerProvider, (previous, next) {
      if (ModalRoute.of(context)?.isCurrent != true) {
        return;
      }

      final session = next.value;
      if (session?.step == ScanStep.ocrReview) {
        context.go('/app/scan/ocr/${session!.id}');
      }
    });

    final scanState = ref.watch(scanControllerProvider);
    final session = scanState.value;

    return Scaffold(
      backgroundColor: const Color(0xFF111512),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(child: _IngredientPreview(hasPreview: _hasPreview)),
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
                      'Scan ingredients',
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
            if (!_hasPreview)
              Center(
                child: Container(
                  width: MediaQuery.sizeOf(context).width - 56,
                  height: 360,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'Fit ingredients text inside the frame',
                        textAlign: TextAlign.center,
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
              child: _CameraControls(
                hasPreview: _hasPreview,
                isLoading: scanState.isLoading,
                error: scanState.error?.toString(),
                barcode: session?.barcode,
                onCapture: () => setState(() => _hasPreview = true),
                onRetake: () => setState(() => _hasPreview = false),
                onUsePhoto: () => ref
                    .read(scanControllerProvider.notifier)
                    .captureIngredients(),
                onGallery: () => setState(() => _hasPreview = true),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IngredientPreview extends StatelessWidget {
  const _IngredientPreview({required this.hasPreview});

  final bool hasPreview;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: hasPreview
              ? const [Color(0xFF26352E), Color(0xFFF7F5EE), Color(0xFF18231F)]
              : const [Color(0xFF17201C), Color(0xFF0E1412), Color(0xFF26352E)],
        ),
      ),
      child: Center(
        child: hasPreview
            ? Container(
                width: MediaQuery.sizeOf(context).width - 48,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'INGREDIENTS: oats, almonds, sugar, cocoa, natural flavor',
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                  ),
                ),
              )
            : const Icon(
                Icons.document_scanner_outlined,
                color: Colors.white24,
                size: 150,
              ),
      ),
    );
  }
}

class _CameraControls extends StatelessWidget {
  const _CameraControls({
    required this.hasPreview,
    required this.isLoading,
    required this.error,
    required this.barcode,
    required this.onCapture,
    required this.onRetake,
    required this.onUsePhoto,
    required this.onGallery,
  });

  final bool hasPreview;
  final bool isLoading;
  final String? error;
  final String? barcode;
  final VoidCallback onCapture;
  final VoidCallback onRetake;
  final VoidCallback onUsePhoto;
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.56),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            error ??
                (barcode == null
                    ? 'Use good lighting and avoid glare.'
                    : 'Barcode $barcode was not found. Ingredients are required.'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white),
          ),
        ),
        const SizedBox(height: 14),
        if (isLoading) ...[
          const CircularProgressIndicator(color: Colors.white),
          const SizedBox(height: 12),
          const Text('Running OCR...', style: TextStyle(color: Colors.white)),
        ] else if (hasPreview) ...[
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white70),
                  ),
                  onPressed: onRetake,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retake'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onUsePhoto,
                  icon: const Icon(Icons.check),
                  label: const Text('Use photo'),
                ),
              ),
            ],
          ),
        ] else ...[
          FilledButton(
            onPressed: onCapture,
            style: FilledButton.styleFrom(
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(22),
            ),
            child: const Icon(Icons.camera_alt, size: 32),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: onGallery,
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('Upload from gallery'),
          ),
        ],
      ],
    );
  }
}
