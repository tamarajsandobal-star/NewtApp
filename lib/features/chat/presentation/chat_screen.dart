import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/chat_repository.dart';
import '../../auth/data/auth_repository.dart';
import '../../user/domain/user_model.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String chatId;
  final AppUser? extraUser; // Passed from list
  const ChatScreen({required this.chatId, this.extraUser, super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _markAsRead();
  }

  void _markAsRead() {
    final uid = ref.read(authRepositoryProvider).currentUser?.uid;
    if (uid != null) {
      FirebaseFirestore.instance.collection('chats').doc(widget.chatId).update({
        'unreadCounts.$uid': 0,
      });
    }
  }

  void _sendMessage() {
    if (_controller.text.trim().isEmpty) return;
    
    // Using mock ID if auth undefined for MVP testing
    final uid = ref.read(authRepositoryProvider).currentUser?.uid ?? 'testUid';
    ref.read(chatRepositoryProvider).sendMessage(widget.chatId, uid, _controller.text.trim());
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(chatMessagesProvider(widget.chatId));
    final uid = ref.read(authRepositoryProvider).currentUser?.uid ?? 'testUid';

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            if (widget.extraUser?.photoUrl != null)
              CircleAvatar(backgroundImage: NetworkImage(widget.extraUser!.photoUrl!), radius: 16),
            if (widget.extraUser?.photoUrl != null) const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.extraUser != null 
                    ? "${widget.extraUser!.displayName}, ${widget.extraUser!.age ?? '?'}"
                    : "Chat",
                  style: const TextStyle(fontSize: 16),
                ),
                if (widget.extraUser?.username != null)
                   Text(
                     "@${widget.extraUser!.username}", 
                     style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal)
                   ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                 if (messages.isEmpty) return const Center(child: Text("Say hi!"));
                 return ListView.builder(
                   reverse: true,
                   itemCount: messages.length,
                   itemBuilder: (context, index) {
                     final msg = messages[index];
                     final isMe = msg.senderId == uid;
                     return Align(
                       alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                       child: Container(
                         margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                         padding: const EdgeInsets.all(12),
                         decoration: BoxDecoration(
                           color: isMe ? Colors.blue[100] : Colors.grey[200],
                           borderRadius: BorderRadius.circular(16),
                         ),
                         child: Text(msg.text),
                       ),
                     );
                   },
                 );
              },
              error: (e, st) => Center(child: Text('Error: $e')),
              loading: () => const Center(child: CircularProgressIndicator()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
