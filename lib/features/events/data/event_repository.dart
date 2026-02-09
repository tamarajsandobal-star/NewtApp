import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/event_model.dart';

final eventsProvider = StreamProvider<List<Event>>((ref) {
  return FirebaseFirestore.instance
      .collection('events')
      .orderBy('startAt') // Show upcoming
      .limit(20)
      .snapshots()
      .map((snap) => snap.docs.map((d) => Event.fromMap(d.data(), d.id)).toList());
});

final eventRepositoryProvider = Provider((ref) => EventRepository(FirebaseFirestore.instance));

class EventRepository {
  final FirebaseFirestore _firestore;

  EventRepository(this._firestore);

  Future<void> rsvp(String eventId, String userId, String status) async {
    await _firestore
        .collection('events')
        .doc(eventId)
        .collection('rsvps')
        .doc(userId)
        .set({
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    // If 'going', cloud function or client could add to groupChat participants
  }
}
