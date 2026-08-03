import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image/image.dart' as img;

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
  CameraController? _controller;
  CameraPermissionStatus _permissionStatus = CameraPermissionStatus.denied;
  bool _isCheckingPermission = true;
  bool _isInitializingCamera = false;
  bool _isProcessing = false;
  bool _isTakingPicture = false;
  String? _capturedImagePath;
  String? _cameraError;
  Rect _cropRect = const Rect.fromLTRB(0.275, 0.31, 0.725, 0.49);

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

  Future<void> _startScanner() async {
    setState(() {
      _isInitializingCamera = true;
      _cameraError = null;
      _isProcessing = false;
      _isTakingPicture = false;
    });

    CameraController? nextController;

    try {
      final cameras = await availableCameras();
      if (!mounted) {
        return;
      }

      if (cameras.isEmpty) {
        throw StateError('No cameras found on this device.');
      }

      final backCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      nextController = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await nextController.initialize();
      await nextController.setFlashMode(FlashMode.off);

      if (!mounted) {
        await nextController.dispose();
        return;
      }

      await _controller?.dispose();
      setState(() {
        _controller = nextController;
        _isInitializingCamera = false;
      });
    } catch (e) {
      await nextController?.dispose();
      if (!mounted) {
        return;
      }

      setState(() {
        _cameraError = e.toString();
        _isInitializingCamera = false;
      });
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
      await _startScanner();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null) return;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      controller.pausePreview();
    } else if (state == AppLifecycleState.resumed &&
        _permissionStatus == CameraPermissionStatus.granted &&
        !_isProcessing &&
        !_isTakingPicture &&
        _capturedImagePath == null) {
      controller.resumePreview();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    final capturedImagePath = _capturedImagePath;
    if (capturedImagePath != null) {
      unawaited(File(capturedImagePath).delete());
    }
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _captureIngredients() async {
    if (_isProcessing || _isTakingPicture) return;

    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Camera is not ready yet. Please wait a moment.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    setState(() {
      _isTakingPicture = true;
    });
    await HapticFeedback.mediumImpact();

    try {
      final picture = await controller.takePicture();
      if (!mounted) {
        return;
      }

      await controller.pausePreview();
      ref.read(scanControllerProvider.notifier).reset();

      final previousCapturedImagePath = _capturedImagePath;
      if (previousCapturedImagePath != null &&
          previousCapturedImagePath != picture.path) {
        try {
          await File(previousCapturedImagePath).delete();
        } catch (_) {
          // Best-effort cleanup for temporary review images.
        }
      }

      setState(() {
        _capturedImagePath = picture.path;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to capture image: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTakingPicture = false;
        });
      }
    }
  }

  Future<void> _scanCapturedImage() async {
    final capturedImagePath = _capturedImagePath;
    if (capturedImagePath == null || _isProcessing || _isTakingPicture) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });
    await HapticFeedback.mediumImpact();

    try {
      final bytes = await File(capturedImagePath).readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) {
        throw Exception('Failed to decode captured image.');
      }

      final cropX = (_cropRect.left * image.width).round().clamp(
        0,
        image.width - 1,
      );
      final cropY = (_cropRect.top * image.height).round().clamp(
        0,
        image.height - 1,
      );
      final cropW = (_cropRect.width * image.width).round().clamp(
        1,
        image.width - cropX,
      );
      final cropH = (_cropRect.height * image.height).round().clamp(
        1,
        image.height - cropY,
      );
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

      await ref
          .read(scanControllerProvider.notifier)
          .scanIngredients(
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
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _retakePhoto() async {
    final capturedImagePath = _capturedImagePath;
    if (capturedImagePath == null || _isProcessing || _isTakingPicture) {
      return;
    }

    final controller = _controller;
    if (controller != null && controller.value.isInitialized) {
      await controller.resumePreview();
    }

    if (mounted) {
      setState(() {
        _capturedImagePath = null;
      });
    }

    ref.read(scanControllerProvider.notifier).reset();

    try {
      await File(capturedImagePath).delete();
    } catch (_) {
      // Best-effort cleanup for the discarded photo.
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
    final controller = _controller;
    final isCameraReady =
        controller != null &&
        controller.value.isInitialized &&
        _cameraError == null;
    final hasCapturedImage = _capturedImagePath != null;
    final isLoading = scanState.isLoading || _isProcessing || _isTakingPicture;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _isCheckingPermission || _isInitializingCamera
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : _cameraError != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.videocam_off_outlined,
                        color: Colors.white,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to start camera',
                        style: Theme.of(
                          context,
                        ).textTheme.titleLarge?.copyWith(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _cameraError!,
                        style: const TextStyle(color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: _startScanner,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
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
                  if (!hasCapturedImage && isCameraReady)
                    CameraPreview(controller),
                  if (hasCapturedImage)
                    Positioned.fill(
                      child: Image.file(
                        File(_capturedImagePath!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  if (hasCapturedImage)
                    MovableSelectionOverlay(
                      onChanged: (rect) {
                        _cropRect = rect;
                      },
                    ),
                  _TopBar(
                    title: hasCapturedImage
                        ? 'Review Ingredients'
                        : 'Scan Ingredients',
                    torchEnabled:
                        !hasCapturedImage &&
                        controller?.value.flashMode == FlashMode.torch,
                    onBack: _handleBack,
                    onToggleTorch: hasCapturedImage
                        ? null
                        : () async {
                            final cameraController = _controller;
                            if (cameraController == null ||
                                !cameraController.value.isInitialized) {
                              return;
                            }

                            await cameraController.setFlashMode(
                              cameraController.value.flashMode ==
                                      FlashMode.torch
                                  ? FlashMode.off
                                  : FlashMode.torch,
                            );
                            if (mounted) setState(() {});
                          },
                  ),
                  if (isLoading) const _ProcessingOverlay(),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 20,
                    child: _BottomPanel(
                      hasCapturedImage: hasCapturedImage,
                      isLoading: isLoading,
                      isReady: isCameraReady,
                      error: scanState.error?.toString(),
                      onCapture: _captureIngredients,
                      onScan: _scanCapturedImage,
                      onRetake: _retakePhoto,
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
  final VoidCallback? onToggleTorch;

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
    required this.hasCapturedImage,
    required this.isLoading,
    required this.isReady,
    required this.error,
    required this.onCapture,
    required this.onScan,
    required this.onRetake,
  });

  final bool hasCapturedImage;
  final bool isLoading;
  final bool isReady;
  final String? error;
  final VoidCallback onCapture;
  final VoidCallback onScan;
  final VoidCallback onRetake;

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
        if (!hasCapturedImage)
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: isLoading || !isReady ? null : onCapture,
            icon: const Icon(Icons.camera_alt),
            label: Text(
              isReady ? 'Take Photo' : 'Waiting for camera...',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          )
        else ...[
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: isLoading ? null : onRetake,
                  icon: const Icon(Icons.refresh),
                  label: const Text(
                    'Retake',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: isLoading ? null : onScan,
                  icon: const Icon(Icons.document_scanner),
                  label: const Text(
                    'Scan',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
