import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Result of cropping and re-encoding a captured photo.
class CroppedPhoto {
  const CroppedPhoto({required this.bytes});

  /// JPEG-encoded bytes ready to be written to disk / uploaded.
  final Uint8List bytes;
}

/// Reads, crops and re-encodes a captured photo without blocking the UI
/// isolate. The crop rectangle uses fractional coordinates relative to the
/// original image. The output is downscaled to at most [maxDimension] pixels
/// on the longest side to shrink the upload payload.
Future<CroppedPhoto> cropAndEncodePhoto({
  required String imagePath,
  required Rect cropRect,
  int maxDimension = 1600,
  int jpegQuality = 85,
}) async {
  final bytes = await File(imagePath).readAsBytes();
  return compute(
    _cropAndEncode,
    _CropRequest(
      bytes: bytes,
      cropLeft: cropRect.left,
      cropTop: cropRect.top,
      cropWidth: cropRect.width,
      cropHeight: cropRect.height,
      maxDimension: maxDimension,
      jpegQuality: jpegQuality,
    ),
  );
}

class _CropRequest {
  const _CropRequest({
    required this.bytes,
    required this.cropLeft,
    required this.cropTop,
    required this.cropWidth,
    required this.cropHeight,
    required this.maxDimension,
    required this.jpegQuality,
  });

  final Uint8List bytes;
  final double cropLeft;
  final double cropTop;
  final double cropWidth;
  final double cropHeight;
  final int maxDimension;
  final int jpegQuality;
}

CroppedPhoto _cropAndEncode(_CropRequest request) {
  final source = img.decodeImage(request.bytes);
  if (source == null) {
    throw Exception('Failed to decode captured image.');
  }

  final longestSide = source.width > source.height
      ? source.width
      : source.height;
  final scale = longestSide > request.maxDimension
      ? request.maxDimension / longestSide
      : 1.0;

  final image = scale < 1.0
      ? img.copyResize(
          source,
          width: (source.width * scale).round(),
          height: (source.height * scale).round(),
        )
      : source;

  final cropX = (request.cropLeft * image.width).round().clamp(
    0,
    image.width - 1,
  );
  final cropY = (request.cropTop * image.height).round().clamp(
    0,
    image.height - 1,
  );
  final cropW = (request.cropWidth * image.width).round().clamp(
    1,
    image.width - cropX,
  );
  final cropH = (request.cropHeight * image.height).round().clamp(
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

  return CroppedPhoto(
    bytes: img.encodeJpg(cropped, quality: request.jpegQuality),
  );
}
