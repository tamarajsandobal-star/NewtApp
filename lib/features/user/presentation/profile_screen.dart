import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/models/app_user.dart';
import 'package:neuro_social/core/widgets/async_value_widget.dart';

import 'package:neuro_social/features/user/presentation/user_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
            IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () => context.push('/settings'),
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await ref.read(authRepositoryProvider).signOut();
                if (context.mounted) context.go('/login');
              },
            )
        ],
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text("User not found"));
          }
          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),
                CircleAvatar(
                    radius: 50,
                    backgroundImage: user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
                    child: user.photoUrl == null ? const Icon(Icons.person, size: 50) : null,
                ),
                const SizedBox(height: 10),
                Text(
                  user.displayName ?? 'No Name', 
                  style: Theme.of(context).textTheme.headlineSmall
                ),
                if (user.age != null || user.gender != null)
                   Text(
                     "${user.age ?? ''} • ${user.gender ?? ''}",
                     style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                   ),


                const SizedBox(height: 20),
                const Divider(),
                if (user.bio != null && user.bio!.isNotEmpty) ...[
                  ListTile(
                      title: const Text("Bio"),
                      subtitle: Text(user.bio!),
                  ),
                  const Divider(),
                ],
                if (user.tags.isNotEmpty)
                  Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Wrap(
                            spacing: 8,
                            children: user.tags.map((e) => Chip(label: Text(e))).toList(),
                        ),
                      ),
                  ),
                 const SizedBox(height: 20),
                 OutlinedButton(
                     onPressed: () {
                         context.go('/profile/edit');
                     },
                     child: const Text("Edit Profile"),
                 )
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text("Error: $e")),
      ),
    );
  }
}
