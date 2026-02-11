import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_photo.dart';
import 'user_dealbreakers.dart';
import 'user_preferences.dart';

enum ProfileStatus { incomplete, complete, age_blocked }
enum SubscriptionTier { free, premium }
enum FriendshipCommentPermission { yes, only_high_compatibility, no }
enum NeurodivergenceVisibility { public, algorithm_only, hidden }

class AppUser {
  final String uid;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ProfileStatus profileStatus;
  final SubscriptionTier subscriptionTier;
  final bool isVerified;
  final FriendshipCommentPermission allowFriendshipComments;
  final String? displayName;
  final String? username;
  final DateTime? birthDate;
  final String? bio;
  final String? photoUrl; // Deprecated in favor of photos list, kept for backward comp
  final List<UserPhoto> photos; // New
  final String? gender; 
  final Map<String, dynamic>? location; // {'lat': double, 'lng': double}
  final List<String> tags; // Visible "Tinder-style" tags
  
  // Deep Profile
  final String? profileDescription; // "Cómo soy yo" text
  final List<String> identityTags; // "Soy..." tags
  final List<String> deepInterests; // Deep interests
  final Map<String, int> questionnaire; // { 'q1': 5, 'q2': 1 }
  final UserDealbreakers dealbreakers; // Limits

  final UserNeurodivergence neurodivergence;
  final UserSettings settings;
  final UserLimits limits;
  
  // Cached Preferences (fetched from subcollections)
  final DatingPreferences? datingPreferences;
  final FriendshipPreferences? friendshipPreferences;

  AppUser({
    required this.uid,
    required this.createdAt,
    required this.updatedAt,
    this.profileStatus = ProfileStatus.incomplete,
    this.subscriptionTier = SubscriptionTier.free,
    this.isVerified = false,
    this.allowFriendshipComments = FriendshipCommentPermission.yes,
    this.displayName,
    this.username,
    this.birthDate,
    this.bio,
    this.photoUrl,
    this.photos = const [],
    this.gender, 
    this.location, 
    this.tags = const [],
    this.profileDescription,
    this.identityTags = const [],
    this.deepInterests = const [],
    this.questionnaire = const {},
    this.dealbreakers = const UserDealbreakers(),
    this.neurodivergence = const UserNeurodivergence(),
    this.settings = const UserSettings(),
    this.limits = const UserLimits(),
    this.datingPreferences,
    this.friendshipPreferences,
  });

  int? get age {
    if (birthDate == null) return null;
    final now = DateTime.now();
    int age = now.year - birthDate!.year;
    if (now.month < birthDate!.month || (now.month == birthDate!.month && now.day < birthDate!.day)) {
      age--;
    }
    return age;
  }

  // Helper to get primary photo
  String? get primaryPhotoUrl {
      if (photos.isNotEmpty) {
          final primary = photos.firstWhere((p) => p.isPrimary, orElse: () => photos.first);
          return primary.url;
      }
      return photoUrl; // Fallback
  }

  factory AppUser.fromMap(Map<String, dynamic> map, String uid) {
    return AppUser(
      uid: uid,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      profileStatus: ProfileStatus.values.firstWhere((e) => e.name == map['profileStatus'], orElse: () => ProfileStatus.incomplete),
      isVerified: map['isVerified'] ?? false,
      displayName: map['displayName'],
      username: map['username'],
      birthDate: (map['birthDate'] as Timestamp?)?.toDate(),
      bio: map['bio'],
      photoUrl: map['photoUrl'],
      photos: (map['photos'] as List<dynamic>?)?.map((e) => UserPhoto.fromMap(e)).toList() ?? [],
      gender: map['gender'], 
      location: map['location'], 
      tags: List<String>.from(map['tags'] ?? []),
      
      profileDescription: map['profileDescription'],
      identityTags: List<String>.from(map['identityTags'] ?? []),
      deepInterests: List<String>.from(map['deepInterests'] ?? []),
      questionnaire: Map<String, int>.from(map['questionnaire'] ?? {}),
      dealbreakers: map['dealbreakers'] != null ? UserDealbreakers.fromMap(map['dealbreakers']) : const UserDealbreakers(),

      settings: map['settings'] != null ? UserSettings.fromMap(map['settings']) : const UserSettings(),
    );
  }
  
  AppUser copyWith({
    DatingPreferences? datingPreferences,
    FriendshipPreferences? friendshipPreferences,
  }) {
    return AppUser(
      uid: uid,
      createdAt: createdAt,
      updatedAt: updatedAt,
      profileStatus: profileStatus,
      subscriptionTier: subscriptionTier,
      isVerified: isVerified,
      allowFriendshipComments: allowFriendshipComments,
      displayName: displayName,
      username: username,
      birthDate: birthDate,
      bio: bio,
      photoUrl: photoUrl,
      photos: photos,
      gender: gender,
      location: location,
      tags: tags,
      profileDescription: profileDescription,
      identityTags: identityTags,
      deepInterests: deepInterests,
      questionnaire: questionnaire,
      dealbreakers: dealbreakers,
      neurodivergence: neurodivergence,
      settings: settings,
      limits: limits,
      datingPreferences: datingPreferences ?? this.datingPreferences,
      friendshipPreferences: friendshipPreferences ?? this.friendshipPreferences,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'profileStatus': profileStatus.name,
      'subscriptionTier': subscriptionTier.name,
      'isVerified': isVerified,
      'allowFriendshipComments': allowFriendshipComments.name,
      'displayName': displayName,
      'username': username,
      'birthDate': birthDate != null ? Timestamp.fromDate(birthDate!) : null,
      'bio': bio,
      'photoUrl': photoUrl,
      'photos': photos.map((p) => p.toMap()).toList(),
      'gender': gender,
      'location': location, 
      'tags': tags,
      
      'profileDescription': profileDescription,
      'identityTags': identityTags,
      'deepInterests': deepInterests,
      'questionnaire': questionnaire,
      'dealbreakers': dealbreakers.toMap(),

      'settings': {
          'datingActive': settings.datingActive,
          'friendsActive': settings.friendsActive,
      },
      // 'limits': ...
      // 'neurodivergence': ...
    };
  }
}

class UserNeurodivergence {
  final List<String> selected; 
  final String? otherText;
  final NeurodivergenceVisibility visibility;

  const UserNeurodivergence({
    this.selected = const [],
    this.otherText,
    this.visibility = NeurodivergenceVisibility.public,
  });
}

class UserSettings {
  final bool datingActive;
  final bool friendsActive;

  const UserSettings({
    this.datingActive = false,
    this.friendsActive = false,
  });

  factory UserSettings.fromMap(Map<String, dynamic> map) {
    return UserSettings(
      datingActive: map['datingActive'] ?? false,
      friendsActive: map['friendsActive'] ?? false,
    );
  }
}

class UserLimits {
  final int dailyLikesDatingMax;
  final int dailyLikesFriendshipMax;
  final int dailyLikesDatingUsed;
  final int dailyLikesFriendshipUsed;
  final DateTime? lastResetAt;

  const UserLimits({
    this.dailyLikesDatingMax = 15,
    this.dailyLikesFriendshipMax = 25,
    this.dailyLikesDatingUsed = 0,
    this.dailyLikesFriendshipUsed = 0,
    this.lastResetAt,
  });
}
