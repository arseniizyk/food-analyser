import 'dart:async';

abstract interface class BarcodeScannerService {
  Stream<String> watchBarcodes();

  Future<void> start();

  Future<void> stop();
}

class MockBarcodeScannerService implements BarcodeScannerService {
  final StreamController<String> _controller = StreamController.broadcast();

  @override
  Stream<String> watchBarcodes() => _controller.stream;

  @override
  Future<void> start() async {}

  @override
  Future<void> stop() async {}

  Future<void> emit(String barcode) async {
    _controller.add(barcode);
  }
}
