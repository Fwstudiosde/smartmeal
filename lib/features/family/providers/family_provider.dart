import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

  FamilyNotifier(this._client) : super(const FamilyState()) {
    load();
  }

  String? get _uid => _client.auth.currentUser?.id;

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
          .select('family_id, user_id, role, joined_at, user_profiles(display_name, community_name)')
          .eq('family_id', familyId);

      state = FamilyState(
        family: Household.fromJson(familyRes),
        members: (membersRes as List)
            .map((e) => FamilyMember.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
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

  Future<void> createFamily(String name) async {
    final uid = _uid;
    if (uid == null) throw StateError('Not authenticated');
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final code = _generateInviteCode();
      await _client.from('families').insert({
        'name': name.trim(),
        'owner_id': uid,
        'invite_code': code,
      });
      // Trigger auto-adds the owner as member. Reload.
      await load();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> joinByCode(String rawCode) async {
    final uid = _uid;
    if (uid == null) throw StateError('Not authenticated');
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final code = rawCode.trim().toUpperCase();
      final fam = await _client
          .from('families')
          .select('*')
          .eq('invite_code', code)
          .maybeSingle();
      if (fam == null) {
        state = state.copyWith(
            isLoading: false, error: 'Kein Haushalt mit diesem Code');
        return;
      }

      final existingMembers = await _client
          .from('family_members')
          .select('user_id')
          .eq('family_id', fam['id']);
      final count = (existingMembers as List).length;
      final max = (fam['max_members'] as int?) ?? 6;
      if (count >= max) {
        state = state.copyWith(
            isLoading: false, error: 'Haushalt ist voll ($count/$max)');
        return;
      }

      await _client.from('family_members').insert({
        'family_id': fam['id'],
        'user_id': uid,
        'role': 'member',
      });
      await load();
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
  return FamilyNotifier(Supabase.instance.client);
});
