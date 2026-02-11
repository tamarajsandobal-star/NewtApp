import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:neuro_social/core/widgets/async_value_widget.dart';
import 'package:neuro_social/features/auth/data/auth_repository.dart';
import 'package:neuro_social/features/user/presentation/user_providers.dart';
import '../data/chat_repository.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authRepositoryProvider).currentUser;
    if (currentUser == null) {
      return const Center(child: Text("Please log in to see chats"));
    }
    final chatListAsync = ref.watch(chatListProvider(currentUser.uid));

    return Scaffold(
      appBar: AppBar(title: const Text('Chats')),
      body: AsyncValueWidget<List<ChatRoom>>(
        value: chatListAsync,
        error: (e, st) {
           return Center(
             child: Padding(
               padding: const EdgeInsets.all(16.0),
               child: Column(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   const Icon(Icons.error_outline, color: Colors.red, size: 48),
                   const SizedBox(height: 16),
                   Text("Error loading chats:\n$e", textAlign: TextAlign.center),
                   const SizedBox(height: 16),
                   if (e.toString().contains('failed-precondition') || e.toString().contains('index'))
                      const Text(
                        "⚠️ MISSING INDEX\nCheck your console logs or Firebase Console to create the index.",
                        style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                 ],
               ),
             ),
           );
        },
        data: (chats) {
          if (chats.isEmpty) {
            return const Center(child: Text('No chats yet. Go match with someone!'));
          }
          return ListView.separated(
            itemCount: chats.length,
            separatorBuilder: (c, i) => const Divider(),
            itemBuilder: (context, index) {
              final chat = chats[index];
              final otherUserId = chat.participants.firstWhere((id) => id != currentUser.uid, orElse: () => '');
              
              if (otherUserId.isEmpty) return const SizedBox.shrink();

              // Fetch other user data
              return Consumer(
                builder: (context, ref, child) {
                  final otherUserAsync = ref.watch(userProfileProvider(otherUserId));
                  
                  return otherUserAsync.when(
                    data: (user) {
                      if (user == null) return const ListTile(title: Text("Unknown User"));
                      
                      final uid = ref.watch(authRepositoryProvider).currentUser?.uid;
                      final unreadCount = chat.unreadCounts[uid] ?? 0;

                      return ListTile(
                        leading: CircleAvatar(
                             backgroundImage: user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
                             child: user.photoUrl == null ? const Icon(Icons.person) : null,
                        ),
                        title: Row(
                            children: [
                                Expanded(
                                  child: Text(
                                      "${user.displayName ?? 'Unknown'}, ${user.age ?? '?'}",
                                      style: TextStyle(fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal),
                                      overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (chat.mode != null)
                                    Container(
                                        margin: const EdgeInsets.only(left: 8),
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                            color: chat.mode == 'dating' ? Colors.pink[50] : Colors.blue[50],
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                                color: chat.mode == 'dating' ? Colors.pink : Colors.blue,
                                                width: 0.5
                                            )
                                        ),
                                        child: Text(
                                            chat.mode == 'dating' ? "Cita" : "Amistad",
                                            style: TextStyle(
                                                fontSize: 10, 
                                                color: chat.mode == 'dating' ? Colors.pink : Colors.blue,
                                                fontWeight: FontWeight.bold
                                            ),
                                        ),
                                    )
                            ],
                        ),
                        subtitle: Text(
                            chat.lastMessage.isNotEmpty ? chat.lastMessage : 'Start chatting!', 
                            maxLines: 1, 
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: unreadCount > 0 ? Colors.black87 : (chat.lastMessage.isNotEmpty ? null : Colors.grey),
                                fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                                fontStyle: chat.lastMessage.isEmpty ? FontStyle.italic : null,
                            ),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(_formatDate(chat.lastMessageAt), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            // Unread indicator (Placeholder logic: if last message wasn't from me and seen=false)
                            // For MVP, we'll just show a dot if it's "new" (less than 5 mins ago) acting as unread
                            if (DateTime.now().difference(chat.lastMessageAt).inMinutes < 5 && chat.lastMessage.isNotEmpty)
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                width: 10, height: 10,
                                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                              )
                          ],
                        ),
                        onTap: () {
                          context.push('/chat/${chat.id}', extra: user); // Pass user object to avoid refetching
                        },
                      );
                    },
                    loading: () => const ListTile(leading: CircularProgressIndicator(), title: Text("Loading...")),
                    error: (e, s) => const ListTile(title: Text("Error loading user")),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(DateTime d) {
    return "${d.hour}:${d.minute}";
  }
}
