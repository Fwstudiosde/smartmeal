import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/family_provider.dart';

enum PlanContext { personal, household }

/// Shared segmented control that switches between the personal and the
/// household (family) plan/list. Only renders the household side when the
/// user is actually in a family — otherwise it shows a subtle hint.
class PlanContextBar extends ConsumerWidget {
  final PlanContext current;

  /// Route to navigate to when Household is selected.
  final String householdRoute;

  /// Route to navigate to when Personal is selected.
  final String personalRoute;

  const PlanContextBar({
    super.key,
    required this.current,
    required this.householdRoute,
    required this.personalRoute,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fam = ref.watch(familyProvider);
    final theme = Theme.of(context);

    if (!fam.hasFamily) {
      // User without a household: show a small CTA to create one
      if (current != PlanContext.personal) return const SizedBox.shrink();
      return Container(
        margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: theme.primaryColor.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: theme.primaryColor.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.people_outline,
                size: 16, color: theme.primaryColor),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Haushalt erstellen und mit anderen teilen?',
                style: TextStyle(fontSize: 12),
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              onPressed: () => context.push('/household'),
              child: const Text('Los'),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: SegmentedButton<PlanContext>(
        segments: [
          const ButtonSegment(
            value: PlanContext.household,
            icon: Icon(Icons.people, size: 16),
            label: Text('Haushalt'),
          ),
          const ButtonSegment(
            value: PlanContext.personal,
            icon: Icon(Icons.person_outline, size: 16),
            label: Text('Privat'),
          ),
        ],
        selected: {current},
        onSelectionChanged: (sel) {
          final picked = sel.first;
          if (picked == current) return;
          if (picked == PlanContext.household) {
            context.go(householdRoute);
          } else {
            context.go(personalRoute);
          }
        },
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          padding: WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      ),
    );
  }
}
