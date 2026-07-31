import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image/image.dart' as img;
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/camera/camera_permission_helper.dart';
import '../../../core/camera/movable_selection_overlay.dart';
import '../../analysis/presentation/analysis_result_bottom_sheet.dart';
import '../domain/scan_session.dart';
import 'scan_controller.dart';

class IngredientsScanScreen extends ConsumerStatefulWidget {
  const IngredientsScanScreen({required this.sessionId, super.key});

  final String sessionId;

  @override
  ConsumerState<IngredientsScanScreen> createState() =>
      _IngredientsScanScreenState();
}

class _IngredientsScanScreenState extends ConsumerState<IngredientsScanScreen>
    with WidgetsBindingObserver {
  MobileScannerController? _controller;
  CameraPermissionStatus _permissionStatus = CameraPermissionStatus.denied;
  bool _isCheckingPermission = true;
  bool _isProcessing = false;
  Uint8List? _lastFrameBytes;
  Rect _cropRect = const Rect.fromLTRB(0.1, 0.3, 0.9, 0.65);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  Future<void> _initialize() async {
    final status = await CameraPermissionHelper.check();
    if (!mounted) return;

    setState(() {
      _permissionStatus = status;
      _isCheckingPermission = false;
    });

    if (status == CameraPermissionStatus.granted) {
      _startScanner();
    }
  }

  void _startScanner() {
    _controller?.dispose();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      returnImage: true,
    );
    if (mounted) {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _requestPermission() async {
    setState(() => _isCheckingPermission = true);
    final status = await CameraPermissionHelper.request();
    if (!mounted) return;

    setState(() {
      _permissionStatus = status;
      _isCheckingPermission = false;
    });

    if (status == CameraPermissionStatus.granted) {
      _startScanner();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null) return;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      controller.stop();
    } else if (state == AppLifecycleState.resumed &&
        _permissionStatus == CameraPermissionStatus.granted &&
        !_isProcessing) {
      controller.start();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _captureIngredients() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);
    await HapticFeedback.mediumImpact();

    try {
      final bytes = _lastFrameBytes;
      if (bytes == null) {
        throw Exception('Camera frame not available yet. Please try again.');
      }

      final image = img.decodeImage(bytes);
      if (image == null) {
        throw Exception('Failed to decode camera frame.');
      }

      final cropX = (_cropRect.left * image.width).round().clamp(0, image.width);
      final cropY =
          (_cropRect.top * image.height).round().clamp(0, image.height);
      final cropW = (_cropRect.width * image.width)
          .round()
          .clamp(1, image.width - cropX);
      final cropH = (_cropRect.height * image.height)
          .round()
          .clamp(1, image.height - cropY);
      final cropped = img.copyCrop(
        image,
        x: cropX,
        y: cropY,
        width: cropW,
        height: cropH,
      );

      final tempDir = Directory.systemTemp;
      final tempFile = File(
        '${tempDir.path}/scan_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await tempFile.writeAsBytes(img.encodeJpg(cropped));

      await ref.read(scanControllerProvider.notifier).scanIngredients(
            imagePath: tempFile.path,
            sessionId: widget.sessionId,
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to process image: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() => _isProcessing = false);
      }
    }
  }

  void _handleBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/app/scan');
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(scanControllerProvider, (previous, next) {
      if (ModalRoute.of(context)?.isCurrent != true) return;

      final session = next.value;
      final analysis = session?.analysis;

      if (next.hasError && _isProcessing) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Scan failed: ${next.error}'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          setState(() => _isProcessing = false);
        }
      }

      if (session?.step == ScanStep.completed && analysis != null) {
        showAnalysisResultBottomSheet(
          context: context,
          analysisId: analysis.barcode,
          onScanAnother: () {
            Navigator.of(context).pop();
            ref.read(scanControllerProvider.notifier).reset();
            _handleBack();
          },
        );
      }
    });

    final scanState = ref.watch(scanControllerProvider);
    final isLoading = scanState.isLoading || _isProcessing;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _isCheckingPermission
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : _permissionStatus != CameraPermissionStatus.granted
            ? CameraPermissionView(
                status: _permissionStatus,
                onRequest: _requestPermission,
                message: 'Camera access is needed to scan product ingredients.',
              )
            : Stack(
                fit: StackFit.expand,
                children: [
                  if (_controller != null)
                    MobileScanner(
                      controller: _controller,
                      fit: BoxFit.cover,
                      onDetect: (capture) {
                        if (capture.image != null) {
                          _lastFrameBytes = capture.image;
                        }
                      },
                    ),
                  MovableSelectionOverlay(
                    onChanged: (rect) {
                      _cropRect = rect;
                    },
                  ),
                  _TopBar(
                    title: 'Scan Ingredients',
                    torchEnabled: _controller?.torchEnabled ?? false,
                    onBack: _handleBack,
                    onToggleTorch: () async {
                      await _controller?.toggleTorch();
                      if (mounted) setState(() {});
                    },
                  ),
                  if (isLoading) const _ProcessingOverlay(),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 20,
                    child: _BottomPanel(
                      isLoading: isLoading,
                      error: scanState.error?.toString(),
                      onCapture: _captureIngredients,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.torchEnabled,
    required this.onBack,
    required this.onToggleTorch,
  });

  final String title;
  final bool torchEnabled;
  final VoidCallback onBack;
  final VoidCallback onToggleTorch;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 8,
      right: 8,
      top: 8,
      child: Row(
        children: [
          IconButton(
            tooltip: 'Back',
            color: Colors.white,
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            tooltip: torchEnabled ? 'Turn flash off' : 'Turn flash on',
            color: Colors.white,
            onPressed: onToggleTorch,
            icon: Icon(torchEnabled ? Icons.flash_on : Icons.flash_off),
          ),
        ],
      ),
    );
  }
}

class _ProcessingOverlay extends StatelessWidget {
  const _ProcessingOverlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.5),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Recognizing text...',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomPanel extends StatelessWidget {
  const _BottomPanel({
    required this.isLoading,
    required this.error,
    required this.onCapture,
  });

  final bool isLoading;
  final String? error;
  final VoidCallback onCapture;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (error != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
          const SizedBox(height: 12),
        ],
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onPressed: isLoading ? null : onCapture,
          icon: const Icon(Icons.camera_alt),
          label: const Text(
            'Scan Selected Area',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
