class AppUser {
  final String uid;
  final String? username; // Unique @username
  final String? displayName;
  final String? photoUrl;
  final int? age;
  final String? gender;
  final String? city;
  final String? bio;
  final List<String> tags;
  final String goal; // 'dating', 'friends', 'both'
  final bool isVerified;
  final Map<String, dynamic> sensoryPrefs; // { 'lowStimulation': true }

  AppUser({
    required this.uid,
    this.username,
    this.displayName,
    this.photoUrl,
    this.age,
    this.gender,
    this.city,
    this.bio,
    this.tags = const [],
    this.goal = 'both',
    this.isVerified = false,
    this.sensoryPrefs = const {},
  });

  factory AppUser.fromMap(Map<String, dynamic> map, String uid) {
    return AppUser(
      uid: uid,
      username: map['username'],
      displayName: map['displayName'],
      photoUrl: map['photoUrl'],
      age: map['age'],
      gender: map['gender'],
      city: map['city'],
      bio: map['bio'],
      tags: List<String>.from(map['tags'] ?? []),
      goal: map['goal'] ?? 'both',
      isVerified: map['isVerified'] ?? false,
      sensoryPrefs: Map<String, dynamic>.from(map['sensoryPrefs'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'age': age,
      'gender': gender,
      'city': city,
      'bio': bio,
      'tags': tags,
      'goal': goal,
      'isVerified': isVerified,
      'sensoryPrefs': sensoryPrefs,
    };
  }
}
