import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_failure.dart';
import '../../../core/api/host.dart';
import '../../../core/auth/session.dart';
import '../../../core/theme/tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_inset_field.dart';
import '../../../shared/widgets/horilla_mark.dart';
import '../../../shared/widgets/pressable.dart';

/// Screen 1 of the handoff.
///
/// The host field is on the first screen rather than buried in settings
/// because self-hosted installs are the common case for this product.
/// Server the host field starts on. See the controller below for why.
const String kDefaultHost = 'https://hr.demo.horilla.com';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key, this.onSignedIn});

  final VoidCallback? onSignedIn;

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  // Prefilled with the public demo. An app whose first screen demands a
  // server address nobody has is the most likely way a store review fails as
  // "unable to review", and it saves everyone else typing a URL on a phone.
  // Editable, and the https:// default still applies once it is cleared.
  final _host = TextEditingController(text: kDefaultHost);
  final _username = TextEditingController();
  final _password = TextEditingController();

  bool _busy = false;
  String? _formError;
  String? _hostError;
  String? _usernameError;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    // The cleartext warning is derived from the host text, so the field has
    // to drive a rebuild -- a TextEditingController changing does not by
    // itself repaint anything outside the TextField.
    _host.addListener(_onHostChanged);
  }

  void _onHostChanged() => setState(() {});

  @override
  void dispose() {
    _host.removeListener(_onHostChanged);
    _host.dispose();
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  /// Warn about an unencrypted connection as it is typed, not after sign-in.
  bool get _isCleartext {
    final result = normaliseHost(_host.text);
    return result.isValid && result.isCleartext;
  }

  Future<void> _submit() async {
    final l10n = AppL10n.of(context);
    setState(() {
      _busy = true;
      _formError = null;
      _hostError = null;
      _usernameError = null;
      _passwordError = null;
    });

    try {
      await ref
          .read(sessionProvider.notifier)
          .signIn(
            rawHost: _host.text,
            username: _username.text,
            password: _password.text,
          );
      if (mounted) widget.onSignedIn?.call();
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        // Each of these needs different words. A locked account and a rate
        // limit are both 429; an unreachable host and a wrong password are
        // both "it didn't work" to a user who is not told otherwise.
        switch (failure) {
          case ApiIncompatibleServer():
          case ApiNetwork():
          case ApiTimeout():
          case ApiTls():
            _hostError = failure.message;
          case ApiUnauthenticated():
            _formError = l10n.signInBadCredentials;
          case ApiLockedOut():
            _formError = failure.message;
          case ApiNoCompany():
            _formError = failure.message;
          case ApiValidation(:final fieldErrors):
            _usernameError = fieldErrors['username']?.first;
            _passwordError = fieldErrors['password']?.first;
            if (_usernameError == null && _passwordError == null) {
              _formError = failure.message;
            }
          default:
            _formError = failure.message;
        }
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// The server field is tucked behind the footer, as v2 draws it -- it is
  /// prefilled, and most people never change it. It opens by itself whenever
  /// there is something about the server to say.
  bool _editingServer = false;

  bool get _showServer => _editingServer || _hostError != null || _isCleartext;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final hostLabel = Uri.tryParse(normaliseHost(_host.text).host)?.host;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          // The soft brand disc in the top corner.
          Positioned(
            top: -150,
            right: -120,
            child: IgnorePointer(
              child: Container(
                width: 300,
                height: 300,
                decoration: const BoxDecoration(
                  color: AppColors.brandTint,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.x28 - 2,
                AppSpace.x28,
                AppSpace.x28 - 2,
                AppSpace.scrollBottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpace.x20),
                  const HorillaLockup(),
                  const SizedBox(height: 44),
                  Text(
                    l10n.signInHeadline,
                    style: AppText.appBarTitle.copyWith(
                      fontSize: 34,
                      letterSpacing: -1.2,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: AppSpace.x12),
                  Text(
                    l10n.signInSubcopy,
                    style: AppText.body.copyWith(
                      fontSize: 14.5,
                      color: AppColors.ink3,
                    ),
                  ),
                  const SizedBox(height: AppSpace.x28),

                  if (_formError != null) ...[
                    _ErrorBanner(message: _formError!),
                    const SizedBox(height: AppSpace.x14),
                  ],

                  if (_showServer) ...[
                    AppInsetField(
                      label: l10n.signInServerLabel,
                      controller: _host,
                      keyboardType: TextInputType.url,
                      hintText: l10n.signInServerHint,
                      errorText: _hostError,
                    ),
                    if (_isCleartext) ...[
                      const SizedBox(height: AppSpace.x8),
                      _CleartextWarning(message: l10n.signInCleartextWarning),
                    ],
                    const SizedBox(height: AppSpace.x12),
                  ],
                  AppInsetField(
                    label: l10n.signInUsernameLabel,
                    controller: _username,
                    errorText: _usernameError,
                    autofillHints: const [AutofillHints.username],
                  ),
                  const SizedBox(height: AppSpace.x12),
                  AppInsetField(
                    label: l10n.signInPasswordLabel,
                    controller: _password,
                    obscureText: true,
                    errorText: _passwordError,
                    autofillHints: const [AutofillHints.password],
                  ),

                  const SizedBox(height: AppSpace.x20),
                  AppButton(
                    label: _busy ? l10n.signInBusy : l10n.signInAction,
                    onPressed: _busy ? null : _submit,
                  ),

                  const SizedBox(height: AppSpace.x18),
                  Row(
                    children: [
                      const Expanded(child: Divider(color: AppColors.line2)),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpace.x12,
                        ),
                        child: Text(
                          l10n.signInOr,
                          style: AppText.meta.copyWith(color: AppColors.ink4),
                        ),
                      ),
                      const Expanded(child: Divider(color: AppColors.line2)),
                    ],
                  ),
                  const SizedBox(height: AppSpace.x18),

                  // Disabled deliberately: there is no SAML or SSO anywhere in
                  // the Horilla backend, so a live-looking button would
                  // promise something that does not exist.
                  AppButton(
                    label: l10n.signInSso,
                    tone: AppButtonTone.quiet,
                    icon: Icons.shield_outlined,
                    onPressed: null,
                  ),

                  const SizedBox(height: 40),
                  Center(
                    child: Semantics(
                      button: true,
                      label: 'Server ${hostLabel ?? 'not set'}, change server',
                      excludeSemantics: true,
                      child: Pressable(
                        onTap: () =>
                            setState(() => _editingServer = !_editingServer),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            minHeight: kMinHitTarget,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: _isCleartext
                                      ? AppColors.warning
                                      : AppColors.success,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: AppSpace.x8),
                              Flexible(
                                child: Text(
                                  '${hostLabel ?? l10n.signInFooter} · '
                                  '${l10n.signInServerChange}',
                                  overflow: TextOverflow.ellipsis,
                                  style: AppText.mono.copyWith(
                                    fontSize: 11.5,
                                    color: AppColors.ink3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.x12),
      decoration: BoxDecoration(
        color: AppColors.dangerBg,
        borderRadius: BorderRadius.circular(AppRadii.button),
        border: Border.all(color: AppColors.dangerBorder),
      ),
      child: Text(
        message,
        style: AppText.body.copyWith(color: AppColors.danger),
      ),
    );
  }
}

/// Unencrypted connections are permitted on a local network, but never
/// silently: the person signing in is told, every time.
class _CleartextWarning extends StatelessWidget {
  const _CleartextWarning({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.x10),
      decoration: BoxDecoration(
        color: AppColors.warningBg,
        borderRadius: BorderRadius.circular(AppRadii.button),
        border: Border.all(color: AppColors.warningBorder),
      ),
      child: Text(
        message,
        style: AppText.meta.copyWith(color: AppColors.warningInk),
      ),
    );
  }
}
