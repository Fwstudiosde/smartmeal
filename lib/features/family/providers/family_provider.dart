import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/auth/providers/auth_provider.dart';
import '../../paywall/models/subscription_tier.dart';
import '../models/family.dart';

class FamilyState {
  final Household? family;
  final List<FamilyMember> members;
  final bool isLoading;
  final String? error;

  const FamilyState({
    this.family,
    this.members = const [],
    this.isLoading = false,
    this.error,
  });

  bool get hasFamily => family != null;

  FamilyState copyWith({
    Household? family,
    bool clearFamily = false,
    List<FamilyMember>? members,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return FamilyState(
      family: clearFamily ? null : (family ?? this.family),
      members: members ?? this.members,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class FamilyNotifier extends StateNotifier<FamilyState> {
  final SupabaseClient _client;
  final String? boundUid;

  FamilyNotifier(this._client, {this.boundUid}) : super(const FamilyState()) {
    if (boundUid != null) load();
  }

  String? get _uid => boundUid ?? _client.auth.currentUser?.id;

  /// Load the current user's family (if any) + members.
  Future<void> load() async {
    final uid = _uid;
    if (uid == null) {
      state = const FamilyState();
      return;
    }
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final memberRes = await _client
          .from('family_members')
          .select('family_id, role')
          .eq('user_id', uid)
          .maybeSingle();

      if (memberRes == null) {
        state = const FamilyState();
        return;
      }

      final familyId = memberRes['family_id'] as String;

      final familyRes = await _client
          .from('families')
          .select('*')
          .eq('id', familyId)
          .single();

      final membersRes = await _client
          .from('family_members')
          .select('family_id, user_id, role, joined_at')
          .eq('family_id', familyId);

      final userIds = (membersRes as List)
          .map((e) => e['user_id'] as String)
          .toList();

      final Map<String, Map<String, dynamic>> profilesById = {};
      if (userIds.isNotEmpty) {
        final profilesRes = await _client
            .from('user_profiles')
            .select('id, display_name, community_name')
            .inFilter('id', userIds);
        for (final p in profilesRes as List) {
          profilesById[p['id'] as String] = Map<String, dynamic>.from(p);
        }
      }

      final members = membersRes.map((e) {
        final m = Map<String, dynamic>.from(e);
        final prof = profilesById[m['user_id']];
        if (prof != null) m['user_profiles'] = prof;
        return FamilyMember.fromJson(m);
      }).toList();

      // Email fetch via SECURITY DEFINER RPC (falls back silently if missing)
      final Map<String, String> emailsById = {};
      try {
        final emailsRes = await _client.rpc(
          'get_family_member_emails',
          params: {'fam_id': familyId},
        );
        if (emailsRes is List) {
          for (final row in emailsRes) {
            final m = Map<String, dynamic>.from(row as Map);
            emailsById[m['user_id'] as String] = m['email'] as String? ?? '';
          }
        }
      } catch (e) {
        // Log for debug, but don't break the household screen.
        // ignore: avoid_print
        print('get_family_member_emails RPC error: $e');
      }

      final enriched = members
          .map((m) => emailsById.containsKey(m.userId)
              ? m.copyWith(email: emailsById[m.userId])
              : m)
          .toList();

      state = FamilyState(
        family: Household.fromJson(familyRes),
        members: enriched,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final r = Random.secure();
    final code = List.generate(8, (_) => chars[r.nextInt(chars.length)]).join();
    return '${code.substring(0, 4)}-${code.substring(4)}';
  }

  Future<void> createFamily(String name, {SubscriptionTier? tier}) async {
    final uid = _uid;
    if (uid == null) throw StateError('Not authenticated');
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final code = _generateInviteCode();
      // Set max_members based on tier so join-by-code RPC enforces it.
      final maxMembers = (tier ?? SubscriptionTier.free).maxHouseholdMembers;
      await _client.from('families').insert({
        'name': name.trim(),
        'owner_id': uid,
        'invite_code': code,
        'max_members': maxMembers,
      });
      // Trigger auto-adds the owner as member. Reload.
      await load();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  /// Owner-only: bump max_members after upgrading tier.
  Future<void> syncMaxMembersToTier(SubscriptionTier tier) async {
    final fam = state.family;
    final uid = _uid;
    if (fam == null || uid == null || fam.ownerId != uid) return;
    final target = tier.maxHouseholdMembers;
    if (fam.maxMembers == target) return;
    try {
      await _client
          .from('families')
          .update({'max_members': target})
          .eq('id', fam.id);
      await load();
    } catch (_) {}
  }

  Future<void> joinByCode(String rawCode) async {
    final uid = _uid;
    if (uid == null) throw StateError('Not authenticated');
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final code = rawCode.trim().toUpperCase();
      await _client.rpc('join_family_by_code', params: {'code': code});
      await load();
    } on PostgrestException catch (e) {
      final msg = switch (e.message) {
        'invalid_code' => 'Kein Haushalt mit diesem Code',
        'family_full' => 'Haushalt ist voll',
        'already_in_family' =>
          'Du bist bereits in einem anderen Haushalt',
        _ => e.message,
      };
      state = state.copyWith(isLoading: false, error: msg);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> leaveFamily() async {
    final uid = _uid;
    final fam = state.family;
    if (uid == null || fam == null) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      if (fam.ownerId == uid) {
        // Owner deletes the whole family — cascades remove memberships.
        await _client.from('families').delete().eq('id', fam.id);
      } else {
        await _client
            .from('family_members')
            .delete()
            .eq('family_id', fam.id)
            .eq('user_id', uid);
      }
      state = const FamilyState();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> removeMember(String memberUserId) async {
    final fam = state.family;
    final uid = _uid;
    if (fam == null || uid == null || fam.ownerId != uid) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _client
          .from('family_members')
          .delete()
          .eq('family_id', fam.id)
          .eq('user_id', memberUserId);
      await load();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }
}

final familyProvider =
    StateNotifierProvider<FamilyNotifier, FamilyState>((ref) {
  // Rebuild notifier whenever the current user's id changes.
  // This clears state on logout / account switch.
  final uid = ref.watch(authProvider.select((s) => s.user?.id));
  final notifier = FamilyNotifier(Supabase.instance.client, boundUid: uid);
  ref.onDispose(() async {
    // Clear the cross-user family cache when the binding changes.
    try {
      await Hive.box('family_cache').clear();
    } catch (_) {}
  });
  return notifier;
});
