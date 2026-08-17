import 'dart:io';
import 'dart:ui';

import 'package:app/core/utils/image_processor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  test('cropAndEncodePhoto crops and downscales a photo off the UI isolate',
      () async {
    final source = img.Image(width: 2000, height: 1000);
    img.fill(source, color: img.ColorRgb8(200, 100, 50));
    final file = File(
      '${Directory.systemTemp.path}/photo_test_${DateTime.now().microsecondsSinceEpoch}.jpg',
    );
    await file.writeAsBytes(img.encodeJpg(source));

    try {
      final photo = await cropAndEncodePhoto(
        imagePath: file.path,
        cropRect: const Rect.fromLTRB(0.25, 0.25, 0.75, 0.75),
      );

      final decoded = img.decodeImage(photo.bytes);
      expect(decoded, isNotNull);
      expect(decoded!.width, 800);
      expect(decoded.height, 400);
    } finally {
      if (await file.exists()) {
        await file.delete();
      }
    }
  });

  test('cropAndEncodePhoto keeps small images at their original size', () async {
    final source = img.Image(width: 640, height: 480);
    img.fill(source, color: img.ColorRgb8(50, 150, 200));
    final file = File(
      '${Directory.systemTemp.path}/photo_test_small_${DateTime.now().microsecondsSinceEpoch}.jpg',
    );
    await file.writeAsBytes(img.encodeJpg(source));

    try {
      final photo = await cropAndEncodePhoto(
        imagePath: file.path,
        cropRect: const Rect.fromLTRB(0, 0, 1, 1),
      );

      final decoded = img.decodeImage(photo.bytes);
      expect(decoded, isNotNull);
      expect(decoded!.width, 640);
      expect(decoded.height, 480);
    } finally {
      if (await file.exists()) {
        await file.delete();
      }
    }
  });
}