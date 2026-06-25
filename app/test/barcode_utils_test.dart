import 'package:app/core/camera/barcode_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BarcodeUtils.normalizeRetailBarcode', () {
    test('accepts UPC-A (12 digits)', () {
      expect(
        BarcodeUtils.normalizeRetailBarcode('012345678905'),
        '012345678905',
      );
    });

    test('accepts EAN-13', () {
      expect(
        BarcodeUtils.normalizeRetailBarcode('0460000000001'),
        '0460000000001',
      );
    });

    test('accepts EAN-8', () {
      expect(BarcodeUtils.normalizeRetailBarcode('96385074'), '96385074');
    });

    test('converts GTIN-14 to EAN-13', () {
      expect(
        BarcodeUtils.normalizeRetailBarcode('00460000000001'),
        '0460000000001',
      );
    });

    test('strips non-digit characters', () {
      expect(
        BarcodeUtils.normalizeRetailBarcode('4 600 0000 0001'),
        '460000000001',
      );
    });

    test('rejects invalid lengths', () {
      expect(BarcodeUtils.normalizeRetailBarcode('123'), isNull);
      expect(BarcodeUtils.normalizeRetailBarcode(''), isNull);
    });
  });
}
