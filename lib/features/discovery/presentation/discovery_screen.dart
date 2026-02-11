import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neuro_social/features/discovery/data/discovery_repository_impl.dart';
import 'package:neuro_social/features/discovery/domain/services/discovery_service.dart';
import 'package:neuro_social/features/discovery/domain/services/scoring_service.dart';
import 'package:neuro_social/features/user/domain/models/neuro_profile.dart';
import 'package:neuro_social/features/user/domain/models/user_interests.dart';
import 'package:neuro_social/features/user/domain/models/user_preferences.dart';
import 'package:go_router/go_router.dart';
import '../../auth/data/auth_repository.dart';
import '../../user/domain/models/user_full_profile.dart';
import '../../user/domain/models/app_user.dart';
import '../../user/presentation/user_providers.dart';

// Simple provider for DiscoveryService
final discoveryServiceProvider = Provider<DiscoveryService>((ref) {
  return DiscoveryService(ScoringService());
});

class DiscoveryScreen extends ConsumerStatefulWidget {
  final String mode; // 'dating' or 'friendship'

  const DiscoveryScreen({super.key, required this.mode});

  @override
  ConsumerState<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends ConsumerState<DiscoveryScreen> {
  List<DiscoveryCandidate> _candidates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCandidates();
  }
  
  @override
  void didUpdateWidget(DiscoveryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mode != widget.mode) {
      _loadCandidates();
    }
  }

  Future<UserFullProfile?> _fetchMyProfile(String uid) async {
      try {
          final firestore = FirebaseFirestore.instance;
          final userDoc = await firestore.collection('users').doc(uid).get();
          if (!userDoc.exists) return null;
          final appUser = AppUser.fromMap(userDoc.data()!, uid);

          final results = await Future.wait([
              firestore.doc('users/$uid/datingPreferences/main').get(),
              firestore.doc('users/$uid/friendshipPreferences/main').get(),
              firestore.doc('users/$uid/neuroProfile/main').get(),
              firestore.doc('users/$uid/interests/main').get(),
          ]);

          DatingPreferences? datingPrefs = results[0].exists ? DatingPreferences.fromMap(results[0].data()!) : null;
          FriendshipPreferences? friendPrefs = results[1].exists ? FriendshipPreferences.fromMap(results[1].data()!) : null;
          NeuroProfile neuro = results[2].exists ? NeuroProfile.fromMap(results[2].data()!) : const NeuroProfile();
          UserInterests interests = results[3].exists ? UserInterests.fromMap(results[3].data()!) : const UserInterests();

          return UserFullProfile(
            user: appUser,
            datingPreferences: datingPrefs,
            friendshipPreferences: friendPrefs,
            neuroProfile: neuro,
            interests: interests,
          );
      } catch (e, stack) {
          print("Error fetching my profile (Critical): $e");
          print(stack);
          return null;
      }
  }

  Future<void> _loadCandidates() async {
    setState(() => _isLoading = true);
    final user = ref.read(authRepositoryProvider).currentUser;
    if (user == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
    }
    
    try {
      final repo = ref.read(discoveryRepositoryProvider);
      final service = ref.read(discoveryServiceProvider);
      
      // 1. My Profile
      final myProfile = await _fetchMyProfile(user.uid);
      if (myProfile == null) {
         if (mounted) setState(() => _isLoading = false); // Should redirect to login ideally
         return;
      }

      // 2. All Potential Candidates (Raw)
      final allProfiles = await repo.getPotentialMatches(user.uid, widget.mode);
      
      // 3. Filter & Score
      List<DiscoveryCandidate> result = [];
      if (widget.mode == 'dating') {
          result = await service.getDatingCandidates(
              currentUser: myProfile, 
              allCandidates: allProfiles, 
              blockedUserIds: {}, // TODO: fetch blocked
              alreadyInteractedUserIds: {} // Repo handles swiped, but good to have
          );
      } else {
          result = await service.getFriendshipCandidates(
              currentUser: myProfile, 
              allCandidates: allProfiles, 
              blockedUserIds: {}, 
              alreadyInteractedUserIds: {}
          );
      }

      if (mounted) setState(() {
        _candidates = result;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      print("Error loading candidates: $e");
    }
  }

  void _onSwipe(int index, bool isLike) async {
     final candidate = _candidates[index];
     final currentUser = ref.read(authRepositoryProvider).currentUser;
     if (currentUser == null) return;

     // Optimistic update
     setState(() {
         _candidates.removeAt(index);
     });
     
     try {
         final isMatch = await ref.read(discoveryRepositoryProvider).swipe(currentUser.uid, candidate.profile.user.uid, isLike, widget.mode);
         
         if (mounted && isMatch) {
             showDialog(
                 context: context, 
                 builder: (context) => AlertDialog(
                     title: const Text("¡Es un Match! 🎉", textAlign: TextAlign.center),
                     content: Text("¡A ${candidate.profile.user.displayName} también le gustas!", textAlign: TextAlign.center),
                     actions: [
                         TextButton(
                             onPressed: () => context.pop(),
                             child: const Text("Seguir buscando"),
                         ),
                         FilledButton(
                             onPressed: () {
                                 context.pop();
                                 context.go('/chats');
                             }, 
                             child: const Text("Ir al Chat"),
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
    
    // Check if mode is active for user (simple check, assume initialized if here, warning if not)
    // In real app we'd redirect to settings if mode is disabled.
    
    if (_candidates.isEmpty) {
        return Scaffold(
            appBar: AppBar(
                title: Text(widget.mode == 'dating' ? "Citas" : "Amistad"),
                actions: [
                    IconButton(
                        icon: const Icon(Icons.bug_report), 
                        onPressed: () async {
                             // Robust Debug Logic (Empty State)
                             final authUser = ref.read(authRepositoryProvider).currentUser;
                             if (authUser == null) return;

                             final user = ref.read(currentUserProfileProvider).value;
                             final uid = authUser.uid;
                             
                             try {
                                 final datingDoc = await FirebaseFirestore.instance.doc('users/$uid/datingPreferences/main').get();
                                 final datingData = datingDoc.data();
                                 
                                 final structure = widget.mode == 'dating' ? (datingData?['relationalStructure'] ?? 'N/A') : 'N/A';
                                 final intention = widget.mode == 'dating' ? (datingData?['intention'] ?? 'N/A') : 'N/A';

                                 if (context.mounted) {
                                     showDialog(context: context, builder: (c) => AlertDialog(
                                         title: const Text("Debug Info (Empty State)"),
                                         content: SingleChildScrollView(
                                             child: ListBody(
                                                 children: [
                                                     Text("UID: ${uid.substring(0,4)}..."),
                                                     Text("UserProv Loaded: ${user != null}"),
                                                     Text("Verified: ${user?.isVerified ?? 'Unknown'}"),
                                                     Text("DatingActive: ${user?.settings.datingActive ?? 'Unknown'}"),
                                                     const Divider(),
                                                     Text("Structure: $structure"),
                                                     Text("Intention: $intention"),
                                                     const Divider(),
                                                     Text("Candidates Loaded: ${_candidates.length}"),
                                                     const Text("(If 0, check filters or raw data)"),
                                                     const Divider(),
                                                     const Text("Filter Logs:", style: TextStyle(fontWeight: FontWeight.bold)),
                                                     Builder(
                                                        builder: (context) {
                                                            final logs = ref.read(discoveryServiceProvider).lastDebugLogs;
                                                            if (logs.isEmpty) return const Text("No logs. (Run failed?)");
                                                            return Container(
                                                                height: 150,
                                                                width: double.maxFinite,
                                                                decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
                                                                child: ListView.builder(
                                                                    shrinkWrap: true,
                                                                    itemCount: logs.length,
                                                                    itemBuilder: (c, i) => Text(logs[i], style: const TextStyle(fontSize: 10)),
                                                                ),
                                                            );
                                                        }
                                                      )
                                                 ],
                                             ),
                                         ),
                                         actions: [
                                              TextButton(
                                                onPressed: () async {
                                                    final batch = FirebaseFirestore.instance.batch();
                                                    final swipes = await FirebaseFirestore.instance.collection('swipes/${uid}/given').get();
                                                    for (var doc in swipes.docs) {
                                                        batch.delete(doc.reference);
                                                    }
                                                    await batch.commit();
                                                    if (c.mounted) Navigator.pop(c);
                                                    if (mounted) _loadCandidates();
                                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Swipes reset!")));
                                                },
                                                child: const Text("Reset Swipes", style: TextStyle(color: Colors.red)),
                                            ),
                                            TextButton(onPressed: () => context.pop(), child: const Text("OK"))
                                         ],
                                     ));
                                 }
                             } catch (e) {
                                 if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Debug Error: $e")));
                             }
                        }
                    ),
                    IconButton(icon: const Icon(Icons.refresh), onPressed: _loadCandidates)
                ],
            ),
            body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("No more profiles right now."),
                    const SizedBox(height: 10),
                    ElevatedButton(onPressed: _loadCandidates, child: const Text("Refresh"))
                  ],
                )
            ),
        );
    }

    // Stack of Cards
    return Scaffold(
        appBar: AppBar(
            title: Text(widget.mode == 'dating' ? "Citas" : "Amistad"),
            actions: [
                IconButton(
                  icon: const Icon(Icons.bug_report), 
                  onPressed: () async {
                      final user = ref.read(currentUserProfileProvider).value;
                      if (user == null) return;
                      
                      final repo = ref.read(discoveryRepositoryProvider);
                      final datingDoc = await FirebaseFirestore.instance.doc('users/${user.uid}/datingPreferences/main').get();
                      final datingData = datingDoc.data();
                      
                      final structure = widget.mode == 'dating' ? (datingData?['relationalStructure'] ?? 'N/A') : 'N/A';
                      final intention = widget.mode == 'dating' ? (datingData?['intention'] ?? 'N/A') : 'N/A';

                      showDialog(context: context, builder: (c) => AlertDialog(
                          title: const Text("Debug Info"),
                          content: SingleChildScrollView(
                              child: ListBody(
                                  children: [
                                      Text("UID: ${user.uid.substring(0,4)}..."),
                                      Text("Verified: ${user.isVerified}"),
                                      Text("DatingActive: ${user.settings.datingActive}"),
                                      Text("FriendsActive: ${user.settings.friendsActive}"),
                                      const Divider(),
                                      Text("Structure: $structure"),
                                      Text("Intention: $intention"),
                                      const Divider(),
                                      Text("Candidates Loaded: ${_candidates.length}"),
                                      const Divider(),
                                      const Text("Filter Logs (Last Run):", style: TextStyle(fontWeight: FontWeight.bold)),
                                      Builder(
                                        builder: (context) {
                                            final logs = ref.read(discoveryServiceProvider).lastDebugLogs;
                                            if (logs.isEmpty) return const Text("No logs available.");
                                            return Container(
                                                height: 150,
                                                width: double.maxFinite,
                                                decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
                                                child: ListView.builder(
                                                    shrinkWrap: true,
                                                    itemCount: logs.length,
                                                    itemBuilder: (c, i) => Text(logs[i], style: const TextStyle(fontSize: 10)),
                                                ),
                                            );
                                        }
                                      )
                                  ],
                              ),
                          ),
                          actions: [
                              TextButton(
                                  onPressed: () async {
                                      // Reset Swipes Logic (Quick & Dirty for Debug)
                                      final batch = FirebaseFirestore.instance.batch();
                                      final swipes = await FirebaseFirestore.instance.collection('swipes/${user.uid}/given').get();
                                      for (var doc in swipes.docs) {
                                          batch.delete(doc.reference);
                                      }
                                      await batch.commit();
                                      if (c.mounted) Navigator.pop(c);
                                      if (mounted) _loadCandidates();
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Swipes reset!")));
                                  },
                                  child: const Text("Reset Swipes", style: TextStyle(color: Colors.red)),
                              ),
                              TextButton(onPressed: () => context.pop(), child: const Text("OK"))
                          ],
                      ));
                  }
                ),
                IconButton(icon: const Icon(Icons.refresh), onPressed: _loadCandidates)
            ],
        ),
        body: Column(
          children: [
            Consumer(
              builder: (context, ref, _) {
                 final userAsync = ref.watch(currentUserProfileProvider);
                 return userAsync.maybeWhen(
                    data: (user) {
                        if (user != null && !user.isVerified) {
                            return Container(
                                width: double.infinity,
                                color: Colors.orangeAccent,
                                padding: const EdgeInsets.all(8),
                                child: const Text(
                                    "Tu perfil está oculto hasta que te verifiques. Puedes ver a otros, pero ellos no te verán.",
                                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.center,
                                ),
                            );
                        }
                        return const SizedBox.shrink();
                    },
                    orElse: () => const SizedBox.shrink(),
                 );
              },
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Stack(
                    children: _candidates.map((candidate) {
                    return Positioned.fill(
                        child: Draggable(
                            feedback: _buildCard(candidate),
                            childWhenDragging: Container(), 
                            onDragEnd: (details) {
                                if (details.velocity.pixelsPerSecond.dx > 100) {
                                    _onSwipe(_candidates.indexOf(candidate), true);
                                } else if (details.velocity.pixelsPerSecond.dx < -100) {
                                  _onSwipe(_candidates.indexOf(candidate), false);
                                }
                            },
                            child: _buildCard(candidate),
                        ),
                    );
                }).toList().reversed.toList(), 
            ),
          ),
        ),
      ],
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

  Widget _buildCard(DiscoveryCandidate candidate) {
      final user = candidate.profile.user;
      final scoreVal = candidate.score.round();
      
      Color scoreColor = Colors.green;
      if (scoreVal < 80) scoreColor = Colors.orange;
      if (scoreVal < 50) scoreColor = Colors.grey;

      return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                  Expanded(
                    flex: 3,
                    child: Stack(
                      children: [
                        Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                            ),
                            child: user.photoUrl != null 
                                 ? Image.network(user.photoUrl!, fit: BoxFit.cover)
                                 : const Icon(Icons.person, size: 80, color: Colors.white),
                        ),
                        Positioned(
                            top: 10,
                            right: 10,
                            child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                    "$scoreVal% Match",
                                    style: TextStyle(color: scoreColor, fontWeight: FontWeight.bold),
                                ),
                            ),
                        )
                      ],
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
