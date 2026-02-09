import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../user/domain/user_model.dart';
import '../data/discovery_repository_impl.dart';

// Interface
abstract class DiscoveryRepository {
  Future<List<AppUser>> getPotentialMatches(String currentUid);
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
  Future<List<AppUser>> getPotentialMatches(String currentUid) async {
    // Simplified logic: Get users who are NOT me and NOT swiped yet.
    // In production: Requires complex queries or backend function (Algolia/Typesense recommended for scale)
    
    // 1. Get IDs I have already swiped
    final swipesSnap = await _firestore.collection('swipes/$currentUid/given').get();
    final swipedIds = swipesSnap.docs.map((d) => d.id).toSet();
    swipedIds.add(currentUid); // Explicitly add myself to ignore list

    // 2. Query users (limit 20)
    final usersSnap = await _firestore.collection('users').limit(20).get(); 

    return usersSnap.docs
        .where((doc) => doc.id != currentUid && !swipedIds.contains(doc.id)) 
        .map((doc) => AppUser.fromMap(doc.data(), doc.id))
        .toList();
  }

  @override
  Future<bool> swipe(String currentUid, String otherUid, bool isLike, String mode) async {
    final batch = _firestore.batch();
    bool isMatch = false;

    // Record swipe
    final swipeRef = _firestore.doc('swipes/$currentUid/given/$otherUid');
    batch.set(swipeRef, {
      'type': isLike ? 'like' : 'dislike',
      'mode': mode,
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (isLike) {
      // Check for Match (Reciprocal like)
      final otherSwipeRef = _firestore.doc('swipes/$otherUid/given/$currentUid');
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
          'participants': [currentUid, otherUid], // For easier querying
        });

        // Initialize chat placeholder (optional, usually done on first message)
        // But handy to have it ready
        final chatRef = _firestore.collection('chats').doc(matchRef.id);
        batch.set(chatRef, {
            'matchId': matchRef.id,
            'participants': [currentUid, otherUid],
            'lastMessage': '',
            'lastMessageAt': FieldValue.serverTimestamp(),
        });
      }
    }

    await batch.commit();
    return isMatch;
  }
}
