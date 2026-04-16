import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartmeal/core/config/supabase_config.dart';
import 'package:smartmeal/core/auth/providers/auth_provider.dart';

class FollowState {
  final Set<String> followingIds;
  final bool isLoading;

  const FollowState({this.followingIds = const {}, this.isLoading = false});

  FollowState copyWith({Set<String>? followingIds, bool? isLoading}) {
    return FollowState(
      followingIds: followingIds ?? this.followingIds,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class FollowNotifier extends StateNotifier<FollowState> {
  final String? userId;

  FollowNotifier({this.userId}) : super(const FollowState()) {
    if (userId != null) loadFollowing();
  }

  final _client = SupabaseConfig.client;

  Future<void> loadFollowing() async {
    if (userId == null) return;
    state = state.copyWith(isLoading: true);
    try {
      final response = await _client
          .from('follows')
          .select('following_id')
          .eq('follower_id', userId!);

      final ids = (response as List)
          .map((e) => e['following_id'] as String)
          .toSet();

      state = state.copyWith(followingIds: ids, isLoading: false);
    } catch (e) {
      debugPrint('Error loading follows: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  bool isFollowing(String targetUserId) {
    return state.followingIds.contains(targetUserId);
  }

  Future<void> follow(String targetUserId) async {
    if (userId == null || targetUserId == userId) return;

    // Optimistic
    state = state.copyWith(
      followingIds: {...state.followingIds, targetUserId},
    );

    try {
      await _client.from('follows').insert({
        'follower_id': userId,
        'following_id': targetUserId,
      });
    } catch (e) {
      debugPrint('Error following user: $e');
      state = state.copyWith(
        followingIds: state.followingIds.difference({targetUserId}),
      );
    }
  }

  Future<void> unfollow(String targetUserId) async {
    if (userId == null) return;

    // Optimistic
    state = state.copyWith(
      followingIds: state.followingIds.difference({targetUserId}),
    );

    try {
      await _client
          .from('follows')
          .delete()
          .eq('follower_id', userId!)
          .eq('following_id', targetUserId);
    } catch (e) {
      debugPrint('Error unfollowing user: $e');
      state = state.copyWith(
        followingIds: {...state.followingIds, targetUserId},
      );
    }
  }

  Future<void> toggleFollow(String targetUserId) async {
    if (isFollowing(targetUserId)) {
      await unfollow(targetUserId);
    } else {
      await follow(targetUserId);
    }
  }
}

final followProvider = StateNotifierProvider<FollowNotifier, FollowState>((ref) {
  final userId = ref.watch(authProvider).user?.id;
  return FollowNotifier(userId: userId);
});

/// Profiles of followed users (for story circles)
class FollowedUserProfile {
  final String id;
  final String? communityName;
  final String? avatarUrl;

  const FollowedUserProfile({
    required this.id,
    this.communityName,
    this.avatarUrl,
  });
}

final followedUsersProfilesProvider = FutureProvider<List<FollowedUserProfile>>((ref) async {
  final followState = ref.watch(followProvider);
  final ids = followState.followingIds.toList();
  if (ids.isEmpty) return [];

  try {
    final response = await SupabaseConfig.client
        .from('user_profiles')
        .select('id, community_name, avatar_url')
        .inFilter('id', ids);

    return (response as List).map((e) => FollowedUserProfile(
      id: e['id'] as String,
      communityName: e['community_name'] as String?,
      avatarUrl: e['avatar_url'] as String?,
    )).toList();
  } catch (e) {
    debugPrint('Error loading followed profiles: $e');
    return [];
  }
});

/// Follower count for a user
final followerCountProvider = FutureProvider.family<int, String>((ref, userId) async {
  try {
    final response = await SupabaseConfig.client
        .from('follows')
        .select('follower_id')
        .eq('following_id', userId);
    return (response as List).length;
  } catch (_) {
    return 0;
  }
});

/// Following count for a user
final followingCountProvider = FutureProvider.family<int, String>((ref, userId) async {
  try {
    final response = await SupabaseConfig.client
        .from('follows')
        .select('following_id')
        .eq('follower_id', userId);
    return (response as List).length;
  } catch (_) {
    return 0;
  }
});
