import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:neuro_social/core/theme/theme_provider.dart';
import '../../auth/data/auth_repository.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLowStim = ref.watch(lowStimulationModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Low Stimulation Mode'),
            subtitle: const Text('Reduces animations and uses softer colors.'),
            value: isLowStim,
            onChanged: (val) {
              ref.read(lowStimulationModeProvider.notifier).toggle();
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.verified),
            title: const Text('Request Verification'),
            onTap: () {
               context.go('/settings/verification');
            },
          ),
          ListTile(
            leading: const Icon(Icons.block),
            title: const Text('Blocked Users'),
             onTap: () {
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Blocked list empty.")));
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
            onTap: () async {
              await ref.read(authRepositoryProvider).signOut();
              if (context.mounted) context.go('/login');
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("Debug Zone", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.orange),
            title: const Text('Reset Matches (Debug)'),
            subtitle: const Text('Clears matches/swipes but keeps account.'),
            onTap: () async {
               // ... existing reset logic ...
               final confirm = await showDialog<bool>(
                 context: context,
                 builder: (c) => AlertDialog(
                   title: const Text("Reset Matches?"),
                   content: const Text("This will delete all your likes, matches, and chats. You can start swiping again."),
                   actions: [
                     TextButton(onPressed: () => c.pop(false), child: const Text("Cancel")),
                     TextButton(onPressed: () => c.pop(true), child: const Text("Reset")),
                   ],
                 )
               );
               
               if (confirm == true) {
                 final user = ref.read(authRepositoryProvider).currentUser;
                 if (user == null) return;
                 
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Resetting...")));
                 
                 final firestore = FirebaseFirestore.instance;
                 final batch = firestore.batch();
                 
                 // 1. Delete my swipes
                 final mySwipes = await firestore.collection('swipes/${user.uid}/given').get();
                 for (var doc in mySwipes.docs) batch.delete(doc.reference);
                 
                 // 2. Delete matches (where I am a participant)
                 final myMatches = await firestore.collection('matches').where('participants', arrayContains: user.uid).get();
                 for (var doc in myMatches.docs) batch.delete(doc.reference);

                 // 3. Delete chats (where I am a participant)
                 final myChats = await firestore.collection('chats').where('participants', arrayContains: user.uid).get();
                 for (var doc in myChats.docs) batch.delete(doc.reference);
                 
                 await batch.commit();
                 
                 if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Reset complete! Restart app to refresh feed.")));
                 }
               }
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Delete Account', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            subtitle: const Text('Permanently delete your account and data.'),
            onTap: () async {
              final confirm = await showDialog<bool>(
                 context: context,
                 builder: (c) => AlertDialog(
                   title: const Text("Delete Account?"),
                   content: const Text("This action cannot be undone. All your data will be lost forever."),
                   actions: [
                     TextButton(onPressed: () => c.pop(false), child: const Text("Cancel")),
                     TextButton(onPressed: () => c.pop(true), style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text("DELETE")),
                   ],
                 )
               );

               if (confirm == true) {
                 final user = ref.read(authRepositoryProvider).currentUser;
                 if (user == null) return;

                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Deleting account...")));
                 
                 try {
                     final firestore = FirebaseFirestore.instance;
                     final batch = firestore.batch();

                     // 1. Delete User Profile
                     batch.delete(firestore.collection('users').doc(user.uid));

                     // 2. Delete Swipes
                     final mySwipes = await firestore.collection('swipes/${user.uid}/given').get();
                     for (var doc in mySwipes.docs) batch.delete(doc.reference);

                     // 3. Delete Matches
                     final myMatches = await firestore.collection('matches').where('participants', arrayContains: user.uid).get();
                     for (var doc in myMatches.docs) batch.delete(doc.reference);

                     // 4. Delete Chats
                     final myChats = await firestore.collection('chats').where('participants', arrayContains: user.uid).get();
                     for (var doc in myChats.docs) batch.delete(doc.reference);

                     await batch.commit();

                     // 5. Delete Auth Account
                     await user.delete(); 

                     if (context.mounted) context.go('/login');
                 } catch (e) {
                     if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error deleting account: $e. You may need to re-login.")));
                     }
                 }
               }
            },
          ),
        ],
      ),
    );
  }
}
