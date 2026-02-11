import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../user/domain/models/app_user.dart';
import '../../user/domain/models/user_full_profile.dart';
import '../../user/domain/models/user_preferences.dart';
import '../../user/domain/models/neuro_profile.dart';
import '../../user/domain/models/user_interests.dart';

// Interface
abstract class DiscoveryRepository {
  Future<List<UserFullProfile>> getPotentialMatches(String currentUid, String mode);
  Future<bool> swipe(String currentUid, String otherUid, bool isLike, String mode);
}

// Provider
final discoveryRepositoryProvider = Provider<DiscoveryRepository>((ref) {
  return DiscoveryRepositoryImpl(FirebaseFirestore.instance);
});

// Implementation
class DiscoveryRepositoryImpl implements DiscoveryRepository {
  final FirebaseFirestore _firestore;

  DiscoveryRepositoryImpl(this._firestore);

  @override
  Future<List<UserFullProfile>> getPotentialMatches(String currentUid, String mode) async {
    // 1. Get IDs I have already swiped in THIS mode
    final swipesSnap = await _firestore.collection('swipes/$currentUid/given').get();
    
    // Legacy support: if ID has no prefix, it's global/old. If it has prefix, check mode.
    // New format: "{mode}_{otherUid}"
    
    final swipedUserIds = <String>{};
    swipedUserIds.add(currentUid); // Always exclude self

    for (var doc in swipesSnap.docs) {
        final docId = doc.id;
        if (docId.startsWith('${mode}_')) {
           // swiped in this mode
           swipedUserIds.add(docId.replaceFirst('${mode}_', ''));
        } else if (!docId.contains('_')) {
           // Legacy handling: if no prefix, assume it affects Dating (or strict block?)
           // For now, let's assume legacy swipes affect Dating.
           if (mode == 'dating') swipedUserIds.add(docId);
        }
    }

    // 2. Query users (limit 100)
    final usersSnap = await _firestore.collection('users')
        .limit(100)
        .get(); 

    // 3. Filter and fetch full profile
    List<UserFullProfile> fullProfiles = [];
    
    for (var doc in usersSnap.docs) {
      if (swipedUserIds.contains(doc.id)) continue;
      
      try {
          final user = AppUser.fromMap(doc.data(), doc.id);
          
          // Fetch Subcollections (Parallel for speed)
          final results = await Future.wait([
              _firestore.doc('users/${user.uid}/datingPreferences/main').get(),
              _firestore.doc('users/${user.uid}/friendshipPreferences/main').get(),
              _firestore.doc('users/${user.uid}/neuroProfile/main').get(),
              _firestore.doc('users/${user.uid}/interests/main').get(),
          ]);

          final datingSnap = results[0];
          final friendSnap = results[1];
          final neuroSnap = results[2];
          final interestsSnap = results[3];

          DatingPreferences? datingPrefs;
          if (datingSnap.exists) {
             datingPrefs = DatingPreferences.fromMap(datingSnap.data()!);
          }

          FriendshipPreferences? friendPrefs;
          if (friendSnap.exists) {
             friendPrefs = FriendshipPreferences.fromMap(friendSnap.data()!);
          }

          final neuroProfile = neuroSnap.exists 
              ? NeuroProfile.fromMap(neuroSnap.data()!) 
              : const NeuroProfile();

          final interests = interestsSnap.exists 
              ? UserInterests.fromMap(interestsSnap.data()!) 
              : const UserInterests();

          fullProfiles.add(UserFullProfile(
            user: user,
            datingPreferences: datingPrefs,
            friendshipPreferences: friendPrefs,
            neuroProfile: neuroProfile,
            interests: interests,
          ));
          
      } catch (e) {
          print("Error fetching profile for ${doc.id}: $e");
      }
    }
    return fullProfiles;
  }

  @override
  Future<bool> swipe(String currentUid, String otherUid, bool isLike, String mode) async {
    final batch = _firestore.batch();
    bool isMatch = false;

    // Record swipe with Mode Prefix
    final swipeRef = _firestore.doc('swipes/$currentUid/given/${mode}_$otherUid');
    batch.set(swipeRef, {
      'type': isLike ? 'like' : 'dislike',
      'mode': mode,
      'createdAt': FieldValue.serverTimestamp(),
      'targetUid': otherUid, 
    });

    if (isLike) {
      // Check verification status of current user
      final currentUserDoc = await _firestore.collection('users').doc(currentUid).get();
      final isVerified = currentUserDoc.data()?['isVerified'] ?? false;

      if (isVerified) {
          // Check for Match (Reciprocal like)
          // Look for their swipe on ME in the SAME mode
          final otherSwipeRef = _firestore.doc('swipes/$otherUid/given/${mode}_$currentUid');
          final otherSwipeSnap = await otherSwipeRef.get();

          if (otherSwipeSnap.exists && otherSwipeSnap.data()?['type'] == 'like') {
            // IT'S A MATCH!
            isMatch = true;
            final matchRef = _firestore.collection('matches').doc();
            batch.set(matchRef, {
              'userA': currentUid,
              'userB': otherUid,
              'mode': mode,
              'createdAt': FieldValue.serverTimestamp(),
              'lastMessageAt': FieldValue.serverTimestamp(),
              'participants': [currentUid, otherUid], 
            });

            // Initialize chat placeholder
            final chatRef = _firestore.collection('chats').doc(matchRef.id);
            batch.set(chatRef, {
                'matchId': matchRef.id,
                'participants': [currentUid, otherUid],
                'mode': mode, // SAVE MODE HERE
                'lastMessage': '',
                'lastMessageAt': FieldValue.serverTimestamp(),
            });
          }
      } 
    }

    await batch.commit();
    return isMatch;
  }
}
