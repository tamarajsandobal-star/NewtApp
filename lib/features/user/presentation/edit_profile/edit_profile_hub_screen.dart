import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:neuro_social/features/user/presentation/user_providers.dart';

class EditProfileHubScreen extends ConsumerWidget {
  const EditProfileHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Editar Perfil")),
      body: userAsync.when(
        data: (user) {
          if (user == null) return const Center(child: Text("Usuario no encontrado"));
          
          return ListView(
            children: [
              // Header with progress or primary photo?
              // For now simpler list
              _buildSectionTile(context, "Fotos", Icons.photo_library, '/profile/edit/photos'),
              _buildSectionTile(context, "Información Básica", Icons.person, '/profile/edit/basic'),
              _buildSectionTile(context, "Detalles sobre mí", Icons.psychology, '/profile/edit/about'),
              _buildSectionTile(context, "Neurodivergencia", Icons.extension, '/profile/edit/neuro'),
              _buildSectionTile(context, "Intereses Profundos", Icons.favorite, '/profile/edit/deep-interests'),
              _buildSectionTile(context, "Límites y Preferencias", Icons.block, '/profile/edit/limits'),
              const Divider(),
              _buildSectionTile(context, "Ajustes Citas", Icons.favorite_border, '/profile/edit/dating-settings'),
              _buildSectionTile(context, "Ajustes Amistad", Icons.people_outline, '/profile/edit/friendship-settings'),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text("Error: $err")),
      ),
    );
  }

  Widget _buildSectionTile(BuildContext context, String title, IconData icon, String route) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).primaryColor),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.push(route),
    );
  }
}
