import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/camera/barcode_utils.dart';
import '../../../core/camera/camera_permission_helper.dart';
import '../../../core/camera/scan_overlay.dart';
import '../../analysis/presentation/analysis_result_bottom_sheet.dart';
import '../domain/scan_session.dart';
import 'scan_controller.dart';

class BarcodeScannerScreen extends ConsumerStatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  ConsumerState<BarcodeScannerScreen> createState() =>
      _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends ConsumerState<BarcodeScannerScreen>
    with WidgetsBindingObserver {
  MobileScannerController? _controller;
  CameraPermissionStatus _permissionStatus = CameraPermissionStatus.denied;
  bool _isCheckingPermission = true;
  bool _isProcessingScan = false;
  bool _isConfirmingBarcode = false;
  String? _lastScannedBarcode;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  Future<void> _initialize() async {
    final status = await CameraPermissionHelper.check();
    if (!mounted) {
      return;
    }

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
      formats: BarcodeUtils.retailFormats,
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
    );
    setState(() {
      _isProcessingScan = false;
      _lastScannedBarcode = null;
      _isConfirmingBarcode = false;
    });
  }

  Future<void> _requestPermission() async {
    setState(() => _isCheckingPermission = true);
    final status = await CameraPermissionHelper.request();
    if (!mounted) {
      return;
    }

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
    if (controller == null) {
      return;
    }

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      controller.stop();
    } else if (state == AppLifecycleState.resumed &&
        _permissionStatus == CameraPermissionStatus.granted &&
        !_isProcessingScan &&
        !_isConfirmingBarcode) {
      controller.start();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _handleBarcode(String rawValue) async {
    if (_isProcessingScan || _isConfirmingBarcode) return;

    final barcode = BarcodeUtils.normalizeRetailBarcode(rawValue);
    if (barcode == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unsupported barcode format. Try another angle.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    if (barcode == _lastScannedBarcode) return;

    setState(() {
      _isConfirmingBarcode = true;
      _lastScannedBarcode = barcode;
    });

    await _controller?.stop();

    if (!mounted) {
      return;
    }

    // Ask user to confirm detected barcode before proceeding to avoid accidental scans
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm barcode'),
          content: Text(
            'Detected barcode: $barcode\n\nProceed with this barcode?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      if (mounted) {
        setState(() {
          _isConfirmingBarcode = false;
        });
      }
      await _controller?.start();
      return;
    }

    setState(() {
      _isProcessingScan = true;
      _isConfirmingBarcode = false;
    });

    await HapticFeedback.mediumImpact();

    await ref.read(scanControllerProvider.notifier).scanBarcode(barcode);
  }

  void _resumeScanning() {
    if (_permissionStatus != CameraPermissionStatus.granted) {
      return;
    }

    setState(() {
      _isProcessingScan = false;
      _isConfirmingBarcode = false;
      _lastScannedBarcode = null;
    });
    _controller?.start();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(scanControllerProvider, (previous, next) {
      if (ModalRoute.of(context)?.isCurrent != true) {
        return;
      }

      final session = next.value;
      final analysis = session?.analysis;

      if (next.hasError && _isProcessingScan) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Scan failed: ${next.error.toString()}',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        _resumeScanning();
      }

      if (session?.step == ScanStep.productMissing) {
        context.go('/app/scan/ingredients/${session!.id}');
        return;
      }

      if (session?.step == ScanStep.completed && analysis != null) {
        showAnalysisResultBottomSheet(
          context: context,
          analysisId: analysis.barcode,
          onScanAnother: () {
            Navigator.of(context).pop();
            ref.read(scanControllerProvider.notifier).reset();
            _resumeScanning();
          },
        );
      }
    });

    final scanState = ref.watch(scanControllerProvider);
    final isLoading = scanState.isLoading;

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
                message:
                    'Camera access is needed to scan EAN and UPC barcodes on product packaging.',
              )
            : Stack(
                fit: StackFit.expand,
                children: [
                  if (_controller != null)
                    MobileScanner(
                      controller: _controller,
                      onDetect: (capture) {
                        if (_isProcessingScan ||
                            _isConfirmingBarcode ||
                            isLoading) {
                          return;
                        }

                        for (final barcode in capture.barcodes) {
                          final value = barcode.rawValue;
                          if (value != null && value.isNotEmpty) {
                            _handleBarcode(value);
                            break;
                          }
                        }
                      },
                    ),
                  const ScanOverlay(
                    frameAspectRatio: 1.65,
                    hint: 'Align the barcode inside the frame',
                  ),
                  _ScannerTopBar(
                    torchEnabled: _controller?.torchEnabled ?? false,
                    onBack: () => context.go('/app/scan'),
                    onToggleTorch: () async {
                      await _controller?.toggleTorch();
                      if (mounted) {
                        setState(() {});
                      }
                    },
                  ),
                  if (isLoading || _isProcessingScan)
                    const _ProcessingOverlay(),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 20,
                    child: _ScannerBottomPanel(
                      isLoading: isLoading,
                      error: scanState.error?.toString(),
                      lastBarcode: _lastScannedBarcode,
                      onManualEntry: () => _showManualBarcodeSheet(context),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _showManualBarcodeSheet(BuildContext context) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            0,
            20,
            MediaQuery.viewInsetsOf(context).bottom + 20,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Enter barcode manually',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Supports EAN-13, EAN-8, UPC-A and UPC-E codes.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: controller,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Barcode',
                    hintText: '460000000001',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.numbers),
                  ),
                  validator: (value) {
                    final normalized = BarcodeUtils.normalizeRetailBarcode(
                      value ?? '',
                    );
                    if (normalized == null) {
                      return 'Enter a valid retail barcode (8–14 digits).';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: () {
                    if (!formKey.currentState!.validate()) {
                      return;
                    }
                    Navigator.of(context).pop();
                    _handleBarcode(controller.text);
                  },
                  icon: const Icon(Icons.search),
                  label: const Text('Look up product'),
                ),
              ],
            ),
          ),
        );
      },
    );

    controller.dispose();
  }
}

class _ScannerTopBar extends StatelessWidget {
  const _ScannerTopBar({
    required this.torchEnabled,
    required this.onBack,
    required this.onToggleTorch,
  });

  final bool torchEnabled;
  final VoidCallback onBack;
  final VoidCallback onToggleTorch;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 8,
      right: 8,
      top: 4,
      child: Row(
        children: [
          IconButton(
            tooltip: 'Back',
            color: Colors.white,
            onPressed: onBack,
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
      color: Colors.black.withValues(alpha: 0.45),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Looking up product...',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScannerBottomPanel extends StatelessWidget {
  const _ScannerBottomPanel({
    required this.isLoading,
    required this.error,
    required this.lastBarcode,
    required this.onManualEntry,
  });

  final bool isLoading;
  final String? error;
  final String? lastBarcode;
  final VoidCallback onManualEntry;

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
                (lastBarcode != null
                    ? 'Scanned: $lastBarcode'
                    : 'Point the camera at the barcode on the package'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Colors.white70),
            minimumSize: const Size.fromHeight(48),
          ),
          onPressed: isLoading ? null : onManualEntry,
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Enter barcode manually'),
        ),
      ],
    );
  }
}
