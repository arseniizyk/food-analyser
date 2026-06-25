import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/camera/camera_permission_helper.dart';
import '../../../core/camera/scan_overlay.dart';
import '../domain/scan_session.dart';
import 'scan_controller.dart';

class IngredientCameraScreen extends ConsumerStatefulWidget {
  const IngredientCameraScreen({required this.sessionId, super.key});

  final String sessionId;

  @override
  ConsumerState<IngredientCameraScreen> createState() =>
      _IngredientCameraScreenState();
}

class _IngredientCameraScreenState extends ConsumerState<IngredientCameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  CameraPermissionStatus _permissionStatus = CameraPermissionStatus.denied;
  bool _isInitializing = true;
  bool _torchEnabled = false;
  String? _capturedImagePath;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  Future<void> _initialize() async {
    if (kIsWeb) {
      setState(() => _isInitializing = false);
      return;
    }

    final status = await CameraPermissionHelper.check();
    if (!mounted) {
      return;
    }

    setState(() {
      _permissionStatus = status;
      _isInitializing = false;
    });

    if (status == CameraPermissionStatus.granted) {
      await _initCamera();
    }
  }

  Future<void> _requestPermission() async {
    setState(() => _isInitializing = true);
    final status = await CameraPermissionHelper.request();
    if (!mounted) {
      return;
    }

    setState(() {
      _permissionStatus = status;
      _isInitializing = false;
    });

    if (status == CameraPermissionStatus.granted) {
      await _initCamera();
    }
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    if (!mounted || cameras.isEmpty) {
      return;
    }

    final backCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    await _controller?.dispose();

    final controller = CameraController(
      backCamera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
        _torchEnabled = false;
      });
    } catch (_) {
      await controller.dispose();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not start the camera. Please try again.'),
          ),
        );
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      controller.dispose();
      _controller = null;
    } else if (state == AppLifecycleState.resumed &&
        _capturedImagePath == null) {
      _initCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _capturePhoto() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    try {
      final file = await controller.takePicture();
      setState(() => _capturedImagePath = file.path);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to capture photo.')),
        );
      }
    }
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );

    if (image != null && mounted) {
      setState(() => _capturedImagePath = image.path);
    }
  }

  Future<void> _toggleTorch() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    final nextValue = !_torchEnabled;
    await controller.setFlashMode(
      nextValue ? FlashMode.torch : FlashMode.off,
    );
    if (mounted) {
      setState(() => _torchEnabled = nextValue);
    }
  }

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
    final hasPreview = _capturedImagePath != null;

    if (_isInitializing) {
      return const Scaffold(
        backgroundColor: Color(0xFF111512),
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (kIsWeb && _capturedImagePath == null) {
      return _WebFallback(
        onPickImage: _pickFromGallery,
        onBack: () => context.go('/app/scan'),
      );
    }

    if (_permissionStatus != CameraPermissionStatus.granted && !kIsWeb) {
      return Scaffold(
        backgroundColor: const Color(0xFF111512),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          title: const Text('Scan ingredients'),
        ),
        body: CameraPermissionView(
          status: _permissionStatus,
          onRequest: _requestPermission,
          message:
              'Camera access is needed to photograph the ingredients list on the package.',
        ),
      );
    }

    final controller = _controller;
    final cameraReady = controller != null && controller.value.isInitialized;

    return Scaffold(
      backgroundColor: const Color(0xFF111512),
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasPreview)
              _CapturedPreview(imagePath: _capturedImagePath!)
            else if (cameraReady)
              FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: controller.value.previewSize!.height,
                  height: controller.value.previewSize!.width,
                  child: CameraPreview(controller),
                ),
              )
            else
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            if (!hasPreview && cameraReady)
              const ScanOverlay(
                frameAspectRatio: 0.72,
                hint: 'Fit the ingredients text inside the frame',
                showScanLine: false,
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
                      'Scan ingredients',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (!hasPreview && cameraReady)
                    IconButton(
                      tooltip: _torchEnabled ? 'Turn flash off' : 'Turn flash on',
                      color: Colors.white,
                      onPressed: _toggleTorch,
                      icon: Icon(
                        _torchEnabled ? Icons.flash_on : Icons.flash_off,
                      ),
                    )
                  else
                    const SizedBox(width: 48),
                ],
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 24,
              child: _IngredientControls(
                hasPreview: hasPreview,
                isLoading: scanState.isLoading,
                error: scanState.error?.toString(),
                barcode: session?.barcode,
                onCapture: _capturePhoto,
                onRetake: () => setState(() => _capturedImagePath = null),
                onUsePhoto: () {
                  final path = _capturedImagePath;
                  if (path != null) {
                    ref
                        .read(scanControllerProvider.notifier)
                        .processIngredientsImage(path);
                  }
                },
                onGallery: _pickFromGallery,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CapturedPreview extends StatelessWidget {
  const _CapturedPreview({required this.imagePath});

  final String imagePath;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 72, 16, 160),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              File(imagePath),
              fit: BoxFit.contain,
              width: double.infinity,
            ),
          ),
        ),
      ),
    );
  }
}

class _IngredientControls extends StatelessWidget {
  const _IngredientControls({
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
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            error ??
                (hasPreview
                    ? 'Review the photo, then run OCR.'
                    : barcode == null
                    ? 'Use good lighting and hold the phone steady.'
                    : 'Barcode $barcode was not found. Photograph the ingredients list.'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white),
          ),
        ),
        const SizedBox(height: 14),
        if (isLoading) ...[
          const CircularProgressIndicator(color: Colors.white),
          const SizedBox(height: 12),
          const Text(
            'Recognizing text...',
            style: TextStyle(color: Colors.white),
          ),
        ] else if (hasPreview) ...[
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white70),
                    minimumSize: const Size.fromHeight(48),
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
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  icon: const Icon(Icons.text_fields),
                  label: const Text('Recognize text'),
                ),
              ),
            ],
          ),
        ] else ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.filledTonal(
                style: IconButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.white24,
                  padding: const EdgeInsets.all(16),
                ),
                onPressed: onGallery,
                icon: const Icon(Icons.photo_library_outlined),
                tooltip: 'Choose from gallery',
              ),
              const SizedBox(width: 28),
              FilledButton(
                onPressed: onCapture,
                style: FilledButton.styleFrom(
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(24),
                ),
                child: const Icon(Icons.camera_alt, size: 32),
              ),
              const SizedBox(width: 28),
              const SizedBox(width: 56),
            ],
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onGallery,
            style: TextButton.styleFrom(foregroundColor: Colors.white70),
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('Upload from gallery'),
          ),
        ],
      ],
    );
  }
}

class _WebFallback extends StatelessWidget {
  const _WebFallback({required this.onPickImage, required this.onBack});

  final VoidCallback onPickImage;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan ingredients'),
        leading: IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.photo_library_outlined, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Camera capture is not available in the browser. Upload a photo of the ingredients label instead.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onPickImage,
                icon: const Icon(Icons.upload_file),
                label: const Text('Upload photo'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
