import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/models/app_user.dart';
import '../domain/models/user_preferences.dart';

// Provider to get MY profile
final currentUserProfileProvider = FutureProvider.autoDispose<AppUser?>((ref) async {
  final authUser = ref.watch(authRepositoryProvider).currentUser;
  if (authUser == null) return null;

  final doc = await FirebaseFirestore.instance.collection('users').doc(authUser.uid).get();
  if (doc.exists) {
    var user = AppUser.fromMap(doc.data()!, authUser.uid);
    
    // Fetch Preferences
    print("DEBUG: Fetching preferences for ${authUser.uid}");
    final datingDoc = await FirebaseFirestore.instance.doc('users/${authUser.uid}/datingPreferences/main').get();
    DatingPreferences? datingPrefs;
    if (datingDoc.exists) {
        print("DEBUG: Dating prefs found: ${datingDoc.data()}");
        datingPrefs = DatingPreferences.fromMap(datingDoc.data()!);
    } else {
        print("DEBUG: No dating prefs found");
    }

    final friendDoc = await FirebaseFirestore.instance.doc('users/${authUser.uid}/friendshipPreferences/main').get();
    FriendshipPreferences? friendPrefs;
    if (friendDoc.exists) {
        print("DEBUG: Friendship prefs found: ${friendDoc.data()}");
        friendPrefs = FriendshipPreferences.fromMap(friendDoc.data()!);
    } else {
        print("DEBUG: No friendship prefs found");
    }

    // print("DEBUG: User loaded: ${user.displayName}, Photos: ${user.photos.length}");

    return user.copyWith(
        datingPreferences: datingPrefs,
        friendshipPreferences: friendPrefs
    );
  }
  print("DEBUG: User doc does not exist for ${authUser.uid}");
  return null;
});

// Provider to get ANY profile by ID
final userProfileProvider = FutureProvider.family.autoDispose<AppUser?, String>((ref, userId) async {
  if (userId.isEmpty) return null;
  final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
  if (doc.exists) {
    return AppUser.fromMap(doc.data()!, userId);
  }
  return null;
});
