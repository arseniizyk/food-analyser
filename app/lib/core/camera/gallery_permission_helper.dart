import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

enum GalleryPermissionStatus {
  granted,
  denied,
  permanentlyDenied,
  restricted,
}

class GalleryPermissionHelper {
  const GalleryPermissionHelper._();

  static Future<GalleryPermissionStatus> request() async {
    final status = await Permission.photos.request();

    if (status.isGranted || status.isLimited) {
      return GalleryPermissionStatus.granted;
    }
    if (status.isPermanentlyDenied) {
      return GalleryPermissionStatus.permanentlyDenied;
    }
    if (status.isRestricted) {
      return GalleryPermissionStatus.restricted;
    }
    return GalleryPermissionStatus.denied;
  }

  static Future<GalleryPermissionStatus> check() async {
    final status = await Permission.photos.status;

    if (status.isGranted || status.isLimited) {
      return GalleryPermissionStatus.granted;
    }
    if (status.isPermanentlyDenied) {
      return GalleryPermissionStatus.permanentlyDenied;
    }
    if (status.isRestricted) {
      return GalleryPermissionStatus.restricted;
    }
    return GalleryPermissionStatus.denied;
  }
}

void showGalleryPermissionSnackBar(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: const Text(
        'Photo library access is needed to pick an image.',
      ),
      behavior: SnackBarBehavior.floating,
      action: SnackBarAction(
        label: 'Settings',
        onPressed: openAppSettings,
      ),
    ),
  );
}
