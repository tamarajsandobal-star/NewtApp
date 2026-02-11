
class UserInterests {
  final List<String> tagsNormalized;
  final List<String> tagsDisplay;
  final UserDealbreakers dealbreakers; // General or combined
  final UserDealbreakers? datingDealbreakers; // Specific overrides or additions
  final UserDealbreakers? friendshipDealbreakers; // Specific overrides or additions

  const UserInterests({
    this.tagsNormalized = const [],
    this.tagsDisplay = const [],
    this.dealbreakers = const UserDealbreakers(),
    this.datingDealbreakers,
    this.friendshipDealbreakers,
  });

  factory UserInterests.fromMap(Map<String, dynamic> map) {
    return UserInterests(
      tagsNormalized: List<String>.from(map['tagsNormalized'] ?? []),
      tagsDisplay: List<String>.from(map['tagsDisplay'] ?? []),
      dealbreakers: UserDealbreakers.fromMap(map['dealbreakers'] ?? {}),
      datingDealbreakers: map['datingDealbreakers'] != null 
          ? UserDealbreakers.fromMap(map['datingDealbreakers']) 
          : null,
      friendshipDealbreakers: map['friendshipDealbreakers'] != null 
          ? UserDealbreakers.fromMap(map['friendshipDealbreakers']) 
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tagsNormalized': tagsNormalized,
      'tagsDisplay': tagsDisplay,
      'dealbreakers': dealbreakers.toMap(),
      'datingDealbreakers': datingDealbreakers?.toMap(),
      'friendshipDealbreakers': friendshipDealbreakers?.toMap(),
    };
  }
}

class UserDealbreakers {
  final List<String> hard;
  final List<String> soft;

  const UserDealbreakers({
    this.hard = const [],
    this.soft = const [],
  });

  factory UserDealbreakers.fromMap(Map<String, dynamic> map) {
    return UserDealbreakers(
      hard: List<String>.from(map['hard'] ?? []),
      soft: List<String>.from(map['soft'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'hard': hard,
      'soft': soft,
    };
  }
}
