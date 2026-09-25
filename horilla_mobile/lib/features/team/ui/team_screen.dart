import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api_failure.dart';
import '../../../core/auth/session.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_primitives.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../../shared/widgets/error_state_card.dart';
import '../../approvals/data/approvals_controller.dart';
import '../../employee/data/employee_models.dart';
import '../../employee/ui/directory_screen.dart';
import '../../employee/ui/profile_sheet.dart';
import '../data/team_api.dart';
import '../data/team_models.dart';

/// A manager's view of their direct reports, today: who is in, who is off,
/// and whether this week's leave leaves the team thin.
class TeamScreen extends ConsumerWidget {
  const TeamScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final team = ref.watch(teamTodayProvider);
    final pending = ref.watch(approvalsProvider).value?.items.length ?? 0;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          AppTopBar(
            title: 'My team',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TopBarAction(
                  label: 'Directory',
                  onTap: () => context.push('/team/directory'),
                ),
                const SizedBox(width: AppSpace.x8),
                TopBarAction(
                  label: pending > 0 ? 'Approvals · $pending' : 'Approvals',
                  onTap: () => context.push('/team/approvals'),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.brandStrong,
              onRefresh: () async {
                ref.invalidate(approvalsProvider);
                return ref.refresh(teamTodayProvider.future);
              },
              child: switch (team) {
                AsyncValue(:final value?) => _TeamBody(team: value),
                AsyncValue(:final error?) => ErrorStateCard(
                  failure: error is ApiFailure ? error : const ApiUnknown(),
                  onRetry: () => ref.invalidate(teamTodayProvider),
                ),
                _ => ListView(
                  padding: const EdgeInsets.all(AppSpace.screen),
                  children: const [
                    AppCard.skeleton(height: 92),
                    SizedBox(height: AppSpace.x16),
                    AppCard.skeleton(height: 220),
                  ],
                ),
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamBody extends StatelessWidget {
  const _TeamBody({required this.team});

  final TeamToday team;

  @override
  Widget build(BuildContext context) {
    if (team.members.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(AppSpace.screen),
        children: [
          AppCard(
            child: Text(
              'No one reports to you yet. Your team appears here once HR '
              'sets you as their reporting manager.',
              style: AppText.body,
            ),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.screen,
        AppSpace.x6,
        AppSpace.screen,
        AppSpace.scrollBottom,
      ),
      children: [
        AppCard(
          child: Row(
            children: [
              Expanded(
                child: StatTile(
                  label: 'Checked in',
                  value: '${team.count(TeamState.checkedIn)}',
                  valueColor: AppColors.success,
                ),
              ),
              Expanded(
                child: StatTile(
                  label: 'On leave',
                  value: '${team.count(TeamState.onLeave)}',
                  valueColor: AppColors.warningInk,
                ),
              ),
              Expanded(
                child: StatTile(
                  label: 'Not in',
                  value: '${team.count(TeamState.notIn)}',
                  valueColor: AppColors.danger,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.x20),
        const SectionHeader(title: 'Today'),
        const SizedBox(height: AppSpace.x10),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < team.members.length; i++) ...[
                if (i > 0) const Divider(height: 1, color: AppColors.line2),
                _MemberRow(member: team.members[i]),
              ],
            ],
          ),
        ),
        if (team.week.isNotEmpty) ...[
          const SizedBox(height: AppSpace.x20),
          _ClashCard(team: team),
        ],
      ],
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({required this.member});

  final TeamMember member;

  @override
  Widget build(BuildContext context) {
    final subtitle = switch (member.state) {
      TeamState.onLeave => member.leaveType ?? 'On leave',
      _ => member.jobPosition ?? member.state.label,
    };

    return InkWell(
      onTap: () => showProfileSheet(
        context,
        DirectoryEntry(
          id: member.id,
          firstName: member.name,
          lastName: '',
          jobPosition: member.jobPosition,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.x16,
          vertical: AppSpace.x12,
        ),
        child: Row(
          children: [
            AppAvatar.toned(name: member.name, size: 36),
            const SizedBox(width: AppSpace.x12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.cardTitle.copyWith(fontSize: 14),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.meta,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpace.x8),
            if (member.clockIn != null)
              Text(member.clockIn!, style: AppText.mono.copyWith(fontSize: 12))
            else
              StatusChip(
                member.state.label,
                tone: member.state == TeamState.onLeave
                    ? StatusTone.warning
                    : StatusTone.danger,
              ),
          ],
        ),
      ),
    );
  }
}

/// Monday to Friday, shaded by how many of the team are off.
class _ClashCard extends StatelessWidget {
  const _ClashCard({required this.team});

  final TeamToday team;

  @override
  Widget build(BuildContext context) {
    final worst = team.worstDay;
    final weekOf = DateFormat('d MMM').format(team.week.first.date);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Leave clash · week of $weekOf',
            style: AppText.cardTitle.copyWith(fontSize: 14),
          ),
          const SizedBox(height: AppSpace.x12),
          Row(
            children: [
              for (var i = 0; i < team.week.length; i++) ...[
                if (i > 0) const SizedBox(width: AppSpace.x6),
                Expanded(child: _DayBlock(day: team.week[i])),
              ],
            ],
          ),
          const SizedBox(height: AppSpace.x10),
          Text(
            worst == null
                ? 'No day this week has more than one person off.'
                : '${DateFormat('EEEE').format(worst.date)}: '
                      '${worst.off.join(', ')} off. Coverage is thin that day.',
            style: AppText.meta.copyWith(
              color: worst == null ? AppColors.ink3 : AppColors.danger,
              fontWeight: worst == null ? null : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DayBlock extends StatelessWidget {
  const _DayBlock({required this.day});

  final ClashDay day;

  @override
  Widget build(BuildContext context) {
    final off = day.off.length;
    final (bg, ink) = off >= TeamToday.clashThreshold
        ? (AppColors.dangerBg, AppColors.danger)
        : off == 1
        ? (AppColors.warningBg, AppColors.warningInk)
        : (AppColors.bg, AppColors.ink4);

    return Semantics(
      label:
          '${DateFormat('EEEE').format(day.date)}: '
          '$off ${off == 1 ? 'person' : 'people'} off',
      excludeSemantics: true,
      child: Column(
        children: [
          Container(
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              off == 0 ? '–' : '$off',
              style: AppText.mono.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: ink,
              ),
            ),
          ),
          const SizedBox(height: AppSpace.x4),
          Text(
            DateFormat('E').format(day.date),
            style: AppText.mono.copyWith(fontSize: 10, color: AppColors.ink4),
          ),
        ],
      ),
    );
  }
}

/// The Team tab's root: a manager's own team, or the directory for
/// everyone else. Decided by the role the server resolved at sign-in.
class TeamTab extends ConsumerWidget {
  const TeamTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isManager =
        ref.watch(sessionProvider)?.capabilities.isManager ?? false;
    return isManager ? const TeamScreen() : const DirectoryScreen();
  }
}
