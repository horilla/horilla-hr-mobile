import 'package:flutter/material.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_inset_field.dart';
import '../../../shared/widgets/horilla_mark.dart';

/// Screen 1 of the handoff.
///
/// Full-bleed ink surface. Self-hosted users type their own server address,
/// which is why the host field is here rather than buried in settings.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key, this.onSignedIn});

  final VoidCallback? onSignedIn;

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _host = TextEditingController(text: 'https://demo.horilla.com');
  final _username = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _host.dispose();
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.x20,
            AppSpace.x28,
            AppSpace.x20,
            AppSpace.scrollBottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpace.x28),
              const HorillaMark(),
              const SizedBox(height: AppSpace.x28),
              Text(
                'Your workday,\nin your pocket.',
                style: AppText.cardTitle.copyWith(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                  height: 1.15,
                  color: AppColors.surface,
                ),
              ),
              const SizedBox(height: AppSpace.x12),
              Text(
                'Punch in, book leave, check your payslip — '
                'without opening a laptop.',
                style: AppText.body.copyWith(
                  fontSize: 14,
                  color: AppColors.onDark2,
                ),
              ),
              const SizedBox(height: AppSpace.x28),

              AppInsetField(
                label: 'Server',
                controller: _host,
                onDark: true,
                keyboardType: TextInputType.url,
                hintText: 'https://hr.yourcompany.com',
              ),
              const SizedBox(height: AppSpace.x12),
              AppInsetField(
                label: 'Username',
                controller: _username,
                onDark: true,
                autofillHints: const [AutofillHints.username],
              ),
              const SizedBox(height: AppSpace.x12),
              AppInsetField(
                label: 'Password',
                controller: _password,
                onDark: true,
                obscureText: true,
                autofillHints: const [AutofillHints.password],
              ),

              const SizedBox(height: AppSpace.x20),
              AppButton(
                label: 'Sign in',
                tone: AppButtonTone.onDark,
                onPressed: widget.onSignedIn,
              ),

              const SizedBox(height: AppSpace.x18),
              Row(
                children: [
                  const Expanded(child: Divider(color: Color(0x33FFFFFF))),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpace.x12,
                    ),
                    child: Text(
                      'or',
                      style: AppText.meta.copyWith(color: AppColors.onDark2),
                    ),
                  ),
                  const Expanded(child: Divider(color: Color(0x33FFFFFF))),
                ],
              ),
              const SizedBox(height: AppSpace.x18),

              const AppButton(
                label: 'Continue with SSO',
                tone: AppButtonTone.outlinedOnDark,
                onPressed: null,
              ),

              const SizedBox(height: AppSpace.x28),
              Center(
                child: Text(
                  'Self-hosted · you control your data',
                  style: AppText.mono.copyWith(
                    fontSize: 11,
                    color: AppColors.ink4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
