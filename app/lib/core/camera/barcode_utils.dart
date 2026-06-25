import 'package:mobile_scanner/mobile_scanner.dart';

/// Utilities for retail product barcodes (EAN-13, EAN-8, UPC-A, UPC-E).
class BarcodeUtils {
  const BarcodeUtils._();

  static const retailFormats = <BarcodeFormat>[
    BarcodeFormat.ean13,
    BarcodeFormat.ean8,
    BarcodeFormat.upcA,
    BarcodeFormat.upcE,
    BarcodeFormat.code128,
  ];

  /// Normalizes a scanned value into a catalog-friendly barcode string.
  static String? normalizeRetailBarcode(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final digits = trimmed.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      return null;
    }

    return switch (digits.length) {
      8 => digits,
      12 => digits,
      13 => digits,
      14 when digits.startsWith('0') => digits.substring(1),
      _ => null,
    };
  }

  /// Barcode variants to try when looking up a product in the catalog.
  static List<String> lookupCandidates(String normalized) {
    final candidates = <String>{normalized};

    if (normalized.length == 13 && normalized.startsWith('0')) {
      candidates.add(normalized.substring(1));
    }
    if (normalized.length == 12) {
      candidates.add('0$normalized');
    }

    return candidates.toList();
  }
}
