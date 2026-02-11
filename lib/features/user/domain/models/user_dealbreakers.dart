class UserDealbreakers {
  // Dating Limits
  final List<String> datingSoft; // "Prefiero evitar"
  final List<String> datingHard; // "No acepto"

  // Friendship Limits
  final List<String> friendshipSoft;
  final List<String> friendshipHard;

  const UserDealbreakers({
    this.datingSoft = const [],
    this.datingHard = const [],
    this.friendshipSoft = const [],
    this.friendshipHard = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'datingSoft': datingSoft,
      'datingHard': datingHard,
      'friendshipSoft': friendshipSoft,
      'friendshipHard': friendshipHard,
    };
  }

  factory UserDealbreakers.fromMap(Map<String, dynamic> map) {
    return UserDealbreakers(
      datingSoft: List<String>.from(map['datingSoft'] ?? []),
      datingHard: List<String>.from(map['datingHard'] ?? []),
      friendshipSoft: List<String>.from(map['friendshipSoft'] ?? []),
      friendshipHard: List<String>.from(map['friendshipHard'] ?? []),
    );
  }
}
