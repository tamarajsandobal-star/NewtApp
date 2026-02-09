import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neuro_social/features/discovery/data/discovery_repository_impl.dart';
import 'package:go_router/go_router.dart';
import '../../auth/data/auth_repository.dart';
import '../../user/domain/user_model.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart'; // Assuming dependency or custom implementation

// Note: If flutter_card_swiper is not added to pubspec, we would implement a simple Draggable here.
// For this MVP, I will generate a simple custom draggable stack to avoid extra dependency issues if not installed.

class DiscoveryScreen extends ConsumerStatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  ConsumerState<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends ConsumerState<DiscoveryScreen> {
  // Using a future provider for users would be better, but initializing here for simplicity
  List<AppUser> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final user = ref.read(authRepositoryProvider).currentUser;
    if (user == null) {
        setState(() => _isLoading = false);
        return;
    }
    
    try {
      final users = await ref.read(discoveryRepositoryProvider).getPotentialMatches(user.uid);
      if (mounted) setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      print("Error loading users: $e");
    }
  }

  void _onSwipe(int index, bool isLike) async {
     final user = _users[index];
     final currentUser = ref.read(authRepositoryProvider).currentUser;
     if (currentUser == null) return;

     // Optimistic update
     setState(() {
         _users.removeAt(index);
     });
     
     try {
         // Defaulting to 'both' or the other user's goal for MVP simplicity
         // Ideallly we pass the specific mode (dating/friends) active in the UI
         final isMatch = await ref.read(discoveryRepositoryProvider).swipe(currentUser.uid, user.uid, isLike, 'both');
         
         if (mounted && isMatch) {
             showDialog(
                 context: context, 
                 builder: (context) => AlertDialog(
                     title: const Text("It's a Match! 🎉"),
                     content: Text("You and ${user.displayName} liked each other!"),
                     actions: [
                         TextButton(
                             onPressed: () {
                                 context.pop(); // Close dialog
                                 // Ideally navigate to chat here, but for now just close
                             },
                             child: const Text("Keep Swiping"),
                         ),
                         FilledButton(
                             onPressed: () {
                                 context.pop();
                                 context.go('/chats');
                             }, 
                             child: const Text("Go to Chat"),
                         )
                     ],
                 )
             );
         }
     } catch (e) {
         if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error swiping: $e")));
         }
     }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    
    if (_users.isEmpty) {
        return const Scaffold(
            body: Center(child: Text("No more profiles to show. Check back later!")),
        );
    }

    // Simplified Stack of Cards
    return Scaffold(
        appBar: AppBar(title: const Text("Discover")),
        body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Stack(
                children: _users.map((user) {
                    return Positioned.fill(
                        child: Draggable(
                            feedback: _buildCard(user),
                            childWhenDragging: Container(), // Show nothing or next card
                            onDragEnd: (details) {
                                if (details.velocity.pixelsPerSecond.dx > 100) {
                                    _onSwipe(_users.indexOf(user), true);
                                } else if (details.velocity.pixelsPerSecond.dx < -100) {
                                  _onSwipe(_users.indexOf(user), false);
                                }
                            },
                            child: _buildCard(user),
                        ),
                    );
                }).toList().reversed.toList(), // Reverse to show first item on top
            ),
        ),
        bottomNavigationBar: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                    FloatingActionButton(
                        heroTag: 'dislike',
                        backgroundColor: Colors.red[100],
                        onPressed: () => _onSwipe(0, false),
                        child: const Icon(Icons.close, color: Colors.red),
                    ),
                    FloatingActionButton(
                        heroTag: 'like',    
                        backgroundColor: Colors.green[100],
                        onPressed: () => _onSwipe(0, true),
                        child: const Icon(Icons.favorite, color: Colors.green),
                    ),
                ],
            ),
        ),
    );
  }

  Widget _buildCard(AppUser user) {
      return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                  Expanded(
                    flex: 3,
                    child: Container(
                        decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        child: user.photoUrl != null 
                             ? Image.network(user.photoUrl!, fit: BoxFit.cover)
                             : const Icon(Icons.person, size: 80, color: Colors.white),
                    ),
                  ),
                  Expanded(
                      flex: 2,
                      child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                  Text("${user.displayName ?? 'Unknown'}, ${user.age ?? '?'}", style: Theme.of(context).textTheme.headlineSmall),
                                  const SizedBox(height: 8),
                                  Text(user.bio ?? 'No bio yet.', style: Theme.of(context).textTheme.bodyMedium),
                                  const SizedBox(height: 12),
                                  Wrap(
                                      spacing: 8,
                                      children: user.tags.map((t) => Chip(label: Text(t))).toList(),
                                  )
                              ],
                          ),
                      ),
                  ),
              ],
          ),
      );
  }
}
