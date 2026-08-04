import 'dart:async';

import 'package:app/app/app_providers.dart';
import 'package:app/features/analysis/domain/analysis.dart';
import 'package:app/features/auth/domain/app_user.dart';
import 'package:app/features/auth/domain/auth_repository.dart';
import 'package:app/features/auth/presentation/auth_controller.dart';
import 'package:app/features/scan/domain/scan_repository.dart';
import 'package:app/features/scan/domain/scan_session.dart';
import 'package:app/features/scan/presentation/scan_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeAuthRepository implements AuthRepository {
  final _userController = StreamController<AppUser?>.broadcast();

  @override
  Future<AppUser?> currentUser() async => const GuestUser('guest-local');

  @override
  Stream<AppUser?> watchUser() => _userController.stream;

  @override
  Future<AppUser> signInWithGoogle() async => throw UnimplementedError();

  @override
  Future<AppUser> continueAsGuest() async => const GuestUser('guest-local');

  @override
  Future<void> signOut() async {}

  @override
  void dispose() {
    unawaited(_userController.close());
  }
}

class FakeScanRepository implements ScanRepository {
  final List<String> startedBarcodes = [];
  final List<ScanSession> analyzedSessions = [];

  @override
  Future<ScanSession> startByBarcode({
    required String barcode,
    required String userId,
  }) async {
    startedBarcodes.add(barcode);
    return ScanSession(
      id: 'scan-$barcode',
      barcode: barcode,
      ingredientsImagePath: null,
      extractedText: null,
      analysis: null,
      step: ScanStep.analysisMissing,
    );
  }

  @override
  Future<ScanSession> analyzeIngredients({
    required ScanSession session,
    String? userId,
    required String imagePath,
  }) async {
    analyzedSessions.add(session);
    return session.copyWith(
      ingredientsImagePath: imagePath,
      analysis: Analysis(
        barcode: session.barcode!,
        score: 85,
        grade: GradeLevel.good,
        summary: const [],
        risks: const [],
        ingredients: const [],
      ),
      step: ScanStep.completed,
    );
  }
}

void main() {
  late FakeAuthRepository authRepository;
  late FakeScanRepository scanRepository;
  late ProviderContainer container;

  setUp(() {
    authRepository = FakeAuthRepository();
    scanRepository = FakeScanRepository();
    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepository),
        scanRepositoryProvider.overrideWithValue(scanRepository),
      ],
    );
    addTearDown(container.dispose);
  });

  test(
    'scanIngredients restores the session by id and keeps the barcode',
    () async {
      await container.read(authControllerProvider.future);
      final notifier = container.read(scanControllerProvider.notifier);

      await notifier.scanBarcode('460000000001');

      final session = container.read(scanControllerProvider).value!;
      expect(scanRepository.startedBarcodes, ['460000000001']);

      await notifier.scanIngredients(
        imagePath: 'photo.jpg',
        sessionId: session.id,
      );

      final result = container.read(scanControllerProvider).value!;
      expect(result.step, ScanStep.completed);
      expect(scanRepository.analyzedSessions, hasLength(1));
      expect(scanRepository.analyzedSessions.single.id, session.id);
      expect(scanRepository.analyzedSessions.single.barcode, '460000000001');
    },
  );

  test('scanBarcode normalizes a GTIN-14 barcode', () async {
    await container.read(authControllerProvider.future);
    final notifier = container.read(scanControllerProvider.notifier);

    await notifier.scanBarcode('04600000000014');

    expect(scanRepository.startedBarcodes, ['4600000000014']);
  });

  test('scanBarcode rejects invalid barcode input', () async {
    await container.read(authControllerProvider.future);
    final notifier = container.read(scanControllerProvider.notifier);

    await notifier.scanBarcode('not-a-barcode');

    final state = container.read(scanControllerProvider);
    expect(state.hasError, isTrue);
    expect(state.error.toString(), contains('Invalid barcode format'));
  });

  test('scanIngredients fails when the session is unknown', () async {
    await container.read(authControllerProvider.future);
    final notifier = container.read(scanControllerProvider.notifier);

    await notifier.scanIngredients(
      imagePath: 'photo.jpg',
      sessionId: 'scan-unknown',
    );

    final state = container.read(scanControllerProvider);
    expect(state.hasError, isTrue);
    expect(state.error.toString(), contains('Scan session was not found'));
    expect(scanRepository.analyzedSessions, isEmpty);
  });
}
