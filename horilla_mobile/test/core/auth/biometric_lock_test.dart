/// The biometric-unlock toggle is a plain persisted boolean, not an auth
/// factor -- this pins that it defaults off, that a stored value comes back
/// on restore, and that toggling it both updates state and persists.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horilla_mobile/core/auth/biometric_lock.dart';
import 'package:horilla_mobile/core/auth/session.dart';
import 'package:horilla_mobile/features/auth/data/auth_models.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

const _session = Session(
  host: 'https://hr.example.test',
  user: SignedInUser(id: 1, fullName: 'Test User'),
  capabilities: Capabilities.empty,
  isCleartext: false,
  geoFencingEnabled: false,
  faceDetectionEnabled: false,
);

class _TestSession extends SessionController {
  @override
  Session? build() => _session;

  void set(Session? value) => state = value;
}

class _EnabledBiometrics extends BiometricEnabledController {
  @override
  bool build() => true;
}

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test('defaults to off before restore runs', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(biometricEnabledProvider), isFalse);
  });

  test('restore loads a previously-enabled flag', () async {
    await BiometricStore().write(true);
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(biometricEnabledProvider.notifier).restore();

    expect(container.read(biometricEnabledProvider), isTrue);
  });

  test('set() persists and updates state together', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(biometricEnabledProvider.notifier).set(true);

    expect(container.read(biometricEnabledProvider), isTrue);
    expect(await BiometricStore().read(), isTrue);
  });

  testWidgets('a session lost while locked does not re-lock the next sign-in', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionProvider.overrideWith(_TestSession.new),
          biometricEnabledProvider.overrideWith(_EnabledBiometrics.new),
        ],
        child: const MaterialApp(home: BiometricGate(child: Text('the app'))),
      ),
    );
    await tester.pump();
    expect(find.text('Unlock'), findsOneWidget);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(BiometricGate)),
    );
    final session = container.read(sessionProvider.notifier) as _TestSession;

    // A failed refresh signs out from underneath the lock screen...
    session.set(null);
    await tester.pump();
    // ...and signing back in must land on the app, not the lock again.
    session.set(_session);
    await tester.pump();

    expect(find.text('the app'), findsOneWidget);
    expect(find.text('Unlock'), findsNothing);
  });

  group('ResumeGate', () {
    // The actual bug: passing Face ID dismisses the native prompt, which
    // drives the app through `resumed` without ever reaching `paused` --
    // re-locking on that `resumed` re-locks the instant a correct pass
    // unlocks it, an infinite loop reported live on a real device.
    test('a resumed with no preceding paused does not count', () {
      final gate = ResumeGate();
      expect(gate.record(AppLifecycleState.inactive), isFalse);
      expect(gate.record(AppLifecycleState.resumed), isFalse);
    });

    test('a resumed that follows real backgrounding does count', () {
      final gate = ResumeGate();
      expect(gate.record(AppLifecycleState.paused), isFalse);
      expect(gate.record(AppLifecycleState.resumed), isTrue);
    });

    test('detached counts as backgrounding too', () {
      final gate = ResumeGate();
      expect(gate.record(AppLifecycleState.detached), isFalse);
      expect(gate.record(AppLifecycleState.resumed), isTrue);
    });

    test('an inactive dip in the middle does not lose the paused flag', () {
      final gate = ResumeGate();
      expect(gate.record(AppLifecycleState.paused), isFalse);
      expect(gate.record(AppLifecycleState.inactive), isFalse);
      expect(gate.record(AppLifecycleState.resumed), isTrue);
    });

    test('a second resumed without a new paused does not double-count', () {
      final gate = ResumeGate();
      gate.record(AppLifecycleState.paused);
      expect(gate.record(AppLifecycleState.resumed), isTrue);
      expect(gate.record(AppLifecycleState.resumed), isFalse);
    });
  });
}
