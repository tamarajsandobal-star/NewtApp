import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/message_model.dart';
import '../../user/domain/models/app_user.dart';

// Provides stream of chats
final chatListProvider = StreamProvider.family<List<ChatRoom>, String>((ref, userId) {
    // In production, fetch ChatRoom objects combined with User data
    return FirebaseFirestore.instance
        .collection('chats')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => ChatRoom.fromMap(d.data(), d.id)).toList());
});

// Provides stream of messages for a chat
final chatMessagesProvider = StreamProvider.family<List<Message>, String>((ref, chatId) {
  return FirebaseFirestore.instance
      .collection('chats')
      .doc(chatId)
      .collection('messages')
      .orderBy('createdAt', descending: true)
      .limit(50) // Pagination handled by controller in UI usually
      .snapshots()
      .map((snap) => snap.docs.map((d) => Message.fromMap(d.data(), d.id)).toList());
});

class ChatRepository {
  final FirebaseFirestore _firestore;
  
  ChatRepository(this._firestore);
  
  Future<void> sendMessage(String chatId, String senderId, String text) async {
      final batch = _firestore.batch();
      
      // 1. Add message
      final messageRef = _firestore.collection('chats').doc(chatId).collection('messages').doc();
      batch.set(messageRef, {
          'senderId': senderId,
          'text': text,
          'createdAt': FieldValue.serverTimestamp(),
      });

      // 2. Update Chat Metadata (for list sorting & preview)
      final chatRef = _firestore.collection('chats').doc(chatId);
      
      // We need to know who the OTHER participants are to increment their unread count.
      // Since we don't have the full participants list here easily without a read, 
      // we can try to fetch it first OR pass it in.
      // For efficiency, let's just do a quick read of the chat doc to get participants if we don't pass them.
      // gracefully handle standard case (2 users):
      final chatSnap = await chatRef.get();
      if (chatSnap.exists) {
          final participants = List<String>.from(chatSnap.data()?['participants'] ?? []);
          final otherUsers = participants.where((p) => p != senderId);
          
          final Map<String, dynamic> updates = {
              'lastMessage': text,
              'lastMessageAt': FieldValue.serverTimestamp(),
          };
          
          for (var other in otherUsers) {
              updates['unreadCounts.$other'] = FieldValue.increment(1);
          }
          
          batch.update(chatRef, updates);
      } else {
         // Fallback if chat doc suspiciously missing (shouldn't happen)
         batch.set(chatRef, {
             'lastMessage': text,
             'lastMessageAt': FieldValue.serverTimestamp(),
             'participants': [senderId], // At least
             'unreadCounts': {},
         }, SetOptions(merge: true));
      }

      await batch.commit();
  }
}

final chatRepositoryProvider = Provider((ref) => ChatRepository(FirebaseFirestore.instance));

class ChatRoom {
    final String id;
    final String lastMessage;
    final DateTime lastMessageAt;
    final List<String> participants;
    final Map<String, int> unreadCounts; // { 'uid1': 2, 'uid2': 0 }
    final String? mode; 

    ChatRoom({
      required this.id, 
      required this.lastMessage, 
      required this.lastMessageAt, 
      required this.participants,
      this.unreadCounts = const {},
      this.mode,
    });

    factory ChatRoom.fromMap(Map<String, dynamic> data, String id) {
        return ChatRoom(
            id: id,
            lastMessage: data['lastMessage'] ?? '',
            lastMessageAt: (data['lastMessageAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            participants: List<String>.from(data['participants'] ?? []),
            unreadCounts: Map<String, int>.from(data['unreadCounts'] ?? {}),
            mode: data['mode'],
        );
    }
}
