/// A re-entry gate, not an auth factor.
///
/// Face ID / Touch ID here only decides whether the already-signed-in app is
/// visible yet -- the JWT sits in secure storage unchanged either way, and
/// this toggle is a plain boolean in shared_preferences, not a Keychain
/// access-control flag. That distinction matters: binding a Keychain item to
/// biometryCurrentSet means re-enrolling a fingerprint silently destroys it
/// with no recovery path, which is not what a re-entry gate should risk.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/tokens.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/horilla_mark.dart';
import '../../shared/widgets/pressable.dart';
import 'session.dart';

class BiometricStore {
  BiometricStore({SharedPreferencesAsync? prefs})
    : _prefs = prefs ?? SharedPreferencesAsync();

  static const _key = 'horilla.biometric_unlock';

  final SharedPreferencesAsync _prefs;

  Future<bool> read() async {
    try {
      return await _prefs.getBool(_key) ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> write(bool enabled) async {
    try {
      await _prefs.setBool(_key, enabled);
    } catch (_) {
      // Losing this costs a re-shown toggle next launch, nothing more.
    }
  }
}

final biometricStoreProvider = Provider<BiometricStore>(
  (ref) => BiometricStore(),
);

final localAuthProvider = Provider<LocalAuthentication>(
  (ref) => LocalAuthentication(),
);

/// Whether the device can even offer the toggle -- enrolled biometrics or a
/// device passcode/pattern, either of which `authenticate` can use.
final biometricAvailableProvider = FutureProvider<bool>((ref) async {
  try {
    return await ref.watch(localAuthProvider).isDeviceSupported();
  } catch (_) {
    return false;
  }
});

final biometricEnabledProvider =
    NotifierProvider<BiometricEnabledController, bool>(
      BiometricEnabledController.new,
    );

class BiometricEnabledController extends Notifier<bool> {
  @override
  bool build() => false;

  /// Reads the stored flag. Called once, alongside session restore, so the
  /// gate's first build already has the real value instead of a flash of
  /// "unlocked" while shared_preferences resolves.
  Future<void> restore() async {
    state = await ref.read(biometricStoreProvider).read();
  }

  Future<void> set(bool value) async {
    await ref.read(biometricStoreProvider).write(value);
    state = value;
  }
}

/// Wraps the whole signed-in app. Locks on first build and on every
/// foreground resume when the toggle is on.
///
/// ponytail: no grace period after backgrounding -- a phone call or a quick
/// app switch re-locks it same as a real cold start. Add a short grace
/// window if that turns out to be annoying in practice; nothing here depends
/// on locking being instant.
class BiometricGate extends ConsumerStatefulWidget {
  const BiometricGate({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<BiometricGate> createState() => _BiometricGateState();
}

class _BiometricGateState extends ConsumerState<BiometricGate>
    with WidgetsBindingObserver {
  bool _locked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _maybeLock();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _maybeLock();
  }

  void _maybeLock() {
    final hasSession = ref.read(sessionProvider) != null;
    final enabled = ref.read(biometricEnabledProvider);
    if (hasSession && enabled && !_locked) {
      setState(() => _locked = true);
    }
  }

  Future<void> _unlock() async {
    try {
      final ok = await ref
          .read(localAuthProvider)
          .authenticate(
            localizedReason: 'Unlock Horilla HR',
            options: const AuthenticationOptions(stickyAuth: true),
          );
      if (ok && mounted) setState(() => _locked = false);
    } catch (_) {
      // Hardware failure or cancellation -- stay locked, the escape hatch
      // below is what recovers from a dead-end prompt.
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    if (!_locked || session == null) return widget.child;

    return Material(
      color: AppColors.ink,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.screen),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const HorillaMark(size: 56),
                const SizedBox(height: AppSpace.x20),
                Text(
                  'Signed in as ${session.user.fullName}',
                  textAlign: TextAlign.center,
                  style: AppText.body.copyWith(color: AppColors.surface),
                ),
                const SizedBox(height: AppSpace.x20),
                AppButton(label: 'Unlock', onPressed: _unlock),
                const SizedBox(height: AppSpace.x16),
                // Never a dead end: biometric hardware fails, or someone
                // re-enrolled a fingerprint and the prompt keeps declining.
                Pressable(
                  onTap: () {
                    ref.read(sessionProvider.notifier).signOut();
                    setState(() => _locked = false);
                  },
                  child: Text(
                    'Sign out instead',
                    style: AppText.body.copyWith(color: AppColors.ink4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
