import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

enum CameraPermissionStatus { granted, denied, permanentlyDenied, restricted }

class CameraPermissionHelper {
  const CameraPermissionHelper._();

  static Future<CameraPermissionStatus> request() async {
    final status = await Permission.camera.request();

    if (status.isGranted || status.isLimited) {
      return CameraPermissionStatus.granted;
    }
    if (status.isPermanentlyDenied) {
      return CameraPermissionStatus.permanentlyDenied;
    }
    if (status.isRestricted) {
      return CameraPermissionStatus.restricted;
    }
    return CameraPermissionStatus.denied;
  }

  static Future<CameraPermissionStatus> check() async {
    final status = await Permission.camera.status;

    if (status.isGranted || status.isLimited) {
      return CameraPermissionStatus.granted;
    }
    if (status.isPermanentlyDenied) {
      return CameraPermissionStatus.permanentlyDenied;
    }
    if (status.isRestricted) {
      return CameraPermissionStatus.restricted;
    }
    return CameraPermissionStatus.denied;
  }
}

class CameraPermissionView extends StatelessWidget {
  const CameraPermissionView({
    required this.status,
    required this.onRequest,
    this.title = 'Camera access required',
    this.message =
        'Allow camera access to scan product barcodes and ingredient labels.',
    super.key,
  });

  final CameraPermissionStatus status;
  final VoidCallback onRequest;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final isPermanent = status == CameraPermissionStatus.permanentlyDenied;
    final isRestricted = status == CameraPermissionStatus.restricted;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.no_photography_outlined,
              size: 56,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 20),
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              isRestricted
                  ? 'Camera access is restricted on this device.'
                  : message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (isPermanent || isRestricted)
              FilledButton.icon(
                onPressed: openAppSettings,
                icon: const Icon(Icons.settings_outlined),
                label: const Text('Open settings'),
              )
            else
              FilledButton.icon(
                onPressed: onRequest,
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Allow camera'),
              ),
          ],
        ),
      ),
    );
  }
}
