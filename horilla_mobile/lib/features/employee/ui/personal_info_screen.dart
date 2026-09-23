import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_failure.dart';
import '../../../core/auth/session.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_primitives.dart';
import '../data/profile_api.dart';
import '../../../shared/widgets/app_top_bar.dart';

/// Editing your own contact and emergency details.
///
/// Only the fields the server's self-service allowlist accepts. Name, email,
/// badge and employment details are HR-owned and are not offered here --
/// showing a field that would be silently discarded is worse than not showing
/// it.
class PersonalInfoScreen extends ConsumerStatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  ConsumerState<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends ConsumerState<PersonalInfoScreen> {
  final _fields = <String, TextEditingController>{};
  PersonalInfo? _original;
  bool _saving = false;
  String? _error;
  Map<String, String> _fieldErrors = const {};

  @override
  void dispose() {
    for (final controller in _fields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController _controller(String key, String initial) {
    return _fields.putIfAbsent(key, () => TextEditingController(text: initial));
  }

  PersonalInfo get _edited => PersonalInfo(
    phone: _fields['phone']?.text ?? '',
    address: _fields['address']?.text ?? '',
    city: _fields['city']?.text ?? '',
    state: _fields['state']?.text ?? '',
    zip: _fields['zip']?.text ?? '',
    emergencyContactName: _fields['emergency_contact_name']?.text ?? '',
    emergencyContact: _fields['emergency_contact']?.text ?? '',
    emergencyContactRelation: _fields['emergency_contact_relation']?.text ?? '',
  );

  Future<void> _save() async {
    final original = _original;
    final session = ref.read(sessionProvider);
    if (original == null || session == null) return;

    final changes = _edited.diffFrom(original);
    if (changes.isEmpty) {
      context.pop();
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
      _fieldErrors = const {};
    });

    try {
      await ref.read(profileApiProvider).update(session.user.id, changes);
      ref.invalidate(personalInfoProvider);
      if (mounted) context.pop(true);
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        if (failure is ApiValidation) {
          _fieldErrors = {
            for (final entry in failure.fieldErrors.entries)
              if (entry.value.isNotEmpty) entry.key: entry.value.first,
          };
          if (_fieldErrors.isEmpty) _error = failure.message;
        } else {
          // Includes the administrator having switched profile editing off
          // between opening the screen and saving.
          _error = failure.message;
        }
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final info = ref.watch(personalInfoProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          AppTopBar(title: 'Personal information', onBack: () => context.pop()),
          Expanded(
            child: switch (info) {
              AsyncValue(:final value?) => _form(value),
              AsyncValue(:final error?) => ListView(
                padding: const EdgeInsets.all(AppSpace.screen),
                children: [
                  AppCard(
                    child: Text(
                      error is ApiFailure
                          ? error.message
                          : 'Could not load your details.',
                      style: AppText.body,
                    ),
                  ),
                ],
              ),
              _ => ListView(
                padding: const EdgeInsets.all(AppSpace.screen),
                children: const [AppCard.skeleton(height: 240)],
              ),
            },
          ),
        ],
      ),
    );
  }

  Widget _form(PersonalInfo info) {
    _original ??= info;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.screen,
              AppSpace.x18,
              AppSpace.screen,
              AppSpace.scrollBottom,
            ),
            children: [
              if (_error != null) ...[
                AppCard(
                  background: AppColors.dangerBg,
                  borderColor: AppColors.dangerBorder,
                  padding: const EdgeInsets.all(AppSpace.x12),
                  child: Text(
                    _error!,
                    style: AppText.body.copyWith(color: AppColors.danger),
                  ),
                ),
                const SizedBox(height: AppSpace.x14),
              ],

              const EyebrowLabel('Contact'),
              const SizedBox(height: AppSpace.x10),
              _Field(
                label: 'Phone',
                controller: _controller('phone', info.phone),
                keyboardType: TextInputType.phone,
                error: _fieldErrors['phone'],
              ),
              _Field(
                label: 'Address',
                controller: _controller('address', info.address),
                maxLines: 2,
                error: _fieldErrors['address'],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _Field(
                      label: 'City',
                      controller: _controller('city', info.city),
                      error: _fieldErrors['city'],
                    ),
                  ),
                  const SizedBox(width: AppSpace.x10),
                  Expanded(
                    child: _Field(
                      label: 'Postcode',
                      controller: _controller('zip', info.zip),
                      error: _fieldErrors['zip'],
                    ),
                  ),
                ],
              ),
              _Field(
                label: 'State',
                controller: _controller('state', info.state),
                error: _fieldErrors['state'],
              ),

              const SizedBox(height: AppSpace.x10),
              const EyebrowLabel('Emergency contact'),
              const SizedBox(height: AppSpace.x10),
              _Field(
                label: 'Name',
                controller: _controller(
                  'emergency_contact_name',
                  info.emergencyContactName,
                ),
                error: _fieldErrors['emergency_contact_name'],
              ),
              _Field(
                label: 'Phone',
                controller: _controller(
                  'emergency_contact',
                  info.emergencyContact,
                ),
                keyboardType: TextInputType.phone,
                error: _fieldErrors['emergency_contact'],
              ),
              _Field(
                label: 'Relationship',
                controller: _controller(
                  'emergency_contact_relation',
                  info.emergencyContactRelation,
                ),
                error: _fieldErrors['emergency_contact_relation'],
              ),

              const SizedBox(height: AppSpace.x12),
              Text(
                'Your name, email and employment details are managed by HR '
                'and cannot be changed here.',
                style: AppText.meta,
              ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.screen),
            child: AppButton(
              label: _saving ? 'Saving…' : 'Save changes',
              onPressed: _saving ? null : _save,
            ),
          ),
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    this.keyboardType,
    this.maxLines = 1,
    this.error,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.x10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCard(
            borderColor: error == null ? AppColors.line : AppColors.danger,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.x14,
              vertical: AppSpace.x10,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EyebrowLabel(label),
                const SizedBox(height: AppSpace.x4),
                TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  maxLines: maxLines,
                  style: AppText.body,
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(
                top: AppSpace.x4,
                left: AppSpace.x4,
              ),
              child: Text(
                error!,
                style: AppText.meta.copyWith(color: AppColors.danger),
              ),
            ),
        ],
      ),
    );
  }
}
