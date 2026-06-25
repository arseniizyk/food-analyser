abstract interface class CameraService {
  Future<String> takePhoto();

  Future<String?> pickImageFromGallery();
}

class MockCameraService implements CameraService {
  @override
  Future<String> takePhoto() async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    return '/mock/images/ingredients.jpg';
  }

  @override
  Future<String?> pickImageFromGallery() async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    return '/mock/images/ingredients-from-gallery.jpg';
  }
}
