/// The biometric-unlock toggle is a plain persisted boolean, not an auth
/// factor -- this pins that it defaults off, that a stored value comes back
/// on restore, and that toggling it both updates state and persists.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horilla_mobile/core/auth/biometric_lock.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

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
}
