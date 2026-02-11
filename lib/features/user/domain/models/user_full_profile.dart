import 'app_user.dart';
import 'user_preferences.dart';
import 'neuro_profile.dart';
import 'user_interests.dart';

class UserFullProfile {
  final AppUser user;
  final DatingPreferences? datingPreferences;
  final FriendshipPreferences? friendshipPreferences;
  // NeuroProfile is already in AppUser in my previous definition? Let's check.
  // Yes: final UserNeurodivergence neurodivergence; in AppUser.
  // Wait, NeuroProfile (communication, sensory, social) is separate.
  // Prompt said: "En users/{uid} o subdoc neuroProfile".
  // I created `neuro_profile.dart`.
  // I should add NeuroProfile here.
  final NeuroProfile neuroProfile;
  final UserInterests interests;

  UserFullProfile({
    required this.user,
    this.datingPreferences,
    this.friendshipPreferences,
    required this.neuroProfile,
    required this.interests,
  });
}
