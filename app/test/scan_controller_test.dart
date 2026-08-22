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

  /// When non-null, [currentUser] never completes (simulates slow auth load).
  final Completer<AppUser?>? pendingCurrentUser;

  FakeAuthRepository({this.pendingCurrentUser});

  @override
  Future<AppUser?> currentUser() {
    final pending = pendingCurrentUser;
    if (pending != null) return pending.future;
    return Future.value(const GuestUser('guest-local'));
  }

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
  Completer<void>? startGate;
  Completer<void>? analyzeGate;

  @override
  Future<ScanSession> startByBarcode({
    required String barcode,
    required String userId,
  }) async {
    startedBarcodes.add(barcode);
    final gate = startGate;
    if (gate != null) await gate.future;
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
    final gate = analyzeGate;
    if (gate != null) await gate.future;
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

  test(
    'scanBarcode does not retain the previous session while loading',
    () async {
      await container.read(authControllerProvider.future);
      final notifier = container.read(scanControllerProvider.notifier);

      await notifier.scanBarcode('460000000001');
      expect(
        container.read(scanControllerProvider).value!.barcode,
        '460000000001',
      );

      final gate = Completer<void>();
      scanRepository.startGate = gate;

      final scanFuture = notifier.scanBarcode('460000000002');
      final loading = container.read(scanControllerProvider);

      expect(loading.isLoading, isTrue);
      expect(loading.value, isNull);

      gate.complete();
      await scanFuture;

      expect(
        container.read(scanControllerProvider).value!.barcode,
        '460000000002',
      );
    },
  );

  test(
    'scanIngredients does not retain the previous session while loading',
    () async {
      await container.read(authControllerProvider.future);
      final notifier = container.read(scanControllerProvider.notifier);

      await notifier.scanBarcode('460000000001');
      final session = container.read(scanControllerProvider).value!;

      final gate = Completer<void>();
      scanRepository.analyzeGate = gate;

      final scanFuture = notifier.scanIngredients(
        imagePath: 'photo.jpg',
        sessionId: session.id,
      );
      final loading = container.read(scanControllerProvider);

      expect(loading.isLoading, isTrue);
      expect(loading.value, isNull);

      gate.complete();
      await scanFuture;

      expect(
        container.read(scanControllerProvider).value!.step,
        ScanStep.completed,
      );
    },
  );

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

  test('oldest sessions are evicted once the cap is reached', () async {
    await container.read(authControllerProvider.future);
    final notifier = container.read(scanControllerProvider.notifier);

    for (var i = 0; i < 9; i++) {
      final barcode = '4600000000${(100 + i)}';
      await notifier.scanBarcode(barcode);
    }

    final evictedId = 'scan-4600000000100';
    await notifier.scanIngredients(
      imagePath: 'photo.jpg',
      sessionId: evictedId,
    );

    final state = container.read(scanControllerProvider);
    expect(state.hasError, isTrue);
    expect(state.error.toString(), contains('Scan session was not found'));
  });

  test('scanBarcode reports auth loading instead of guest flash', () async {
    final pending = Completer<AppUser?>();
    authRepository = FakeAuthRepository(pendingCurrentUser: pending);
    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepository),
        scanRepositoryProvider.overrideWithValue(scanRepository),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(scanControllerProvider.notifier);
    await notifier.scanBarcode('460000000001');

    final state = container.read(scanControllerProvider);
    expect(state.hasError, isTrue);
    expect(state.error.toString(), contains('Account is still loading'));
    expect(scanRepository.startedBarcodes, isEmpty);

    pending.complete(const GuestUser('guest-local'));
  });
}
