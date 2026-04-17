class Household {
  final String id;
  final String name;
  final String ownerId;
  final String inviteCode;
  final int maxMembers;
  final DateTime createdAt;

  Household({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.inviteCode,
    required this.maxMembers,
    required this.createdAt,
  });

  factory Household.fromJson(Map<String, dynamic> j) => Household(
        id: j['id'] as String,
        name: j['name'] as String,
        ownerId: j['owner_id'] as String,
        inviteCode: j['invite_code'] as String,
        maxMembers: (j['max_members'] as int?) ?? 6,
        createdAt: DateTime.parse(j['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'owner_id': ownerId,
        'invite_code': inviteCode,
        'max_members': maxMembers,
        'created_at': createdAt.toIso8601String(),
      };
}

class FamilyMember {
  final String familyId;
  final String userId;
  final String role; // 'owner' | 'member'
  final DateTime joinedAt;
  final String? displayName;
  final String? communityName;

  FamilyMember({
    required this.familyId,
    required this.userId,
    required this.role,
    required this.joinedAt,
    this.displayName,
    this.communityName,
  });

  factory FamilyMember.fromJson(Map<String, dynamic> j) {
    final prof = j['user_profiles'] as Map<String, dynamic>?;
    return FamilyMember(
      familyId: j['family_id'] as String,
      userId: j['user_id'] as String,
      role: (j['role'] as String?) ?? 'member',
      joinedAt: DateTime.parse(j['joined_at'] as String),
      displayName: prof?['display_name'] as String?,
      communityName: prof?['community_name'] as String?,
    );
  }

  bool get isOwner => role == 'owner';
}
