import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart';

// Features
import '../../features/auth/data/auth_repository.dart';
import '../../features/chat/data/chat_repository.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/onboarding_screen.dart';
import '../../features/discovery/presentation/discovery_screen.dart';
import '../../features/chat/presentation/chat_list_screen.dart';
import '../../features/chat/presentation/chat_screen.dart';
import '../../features/events/presentation/events_list_screen.dart';
import '../../features/user/presentation/profile_screen.dart';
import '../../features/user/presentation/edit_profile_screen.dart';
import '../../features/user/presentation/settings_screen.dart';
import '../../features/user/presentation/verification_screen.dart';
import '../../features/user/presentation/mode_selection_screen.dart';
import '../../features/user/presentation/edit_profile/edit_profile_hub_screen.dart';
import '../../features/user/presentation/edit_profile/photos_editor_screen.dart';
import '../../features/user/presentation/edit_profile/basic_info_editor_screen.dart';
import '../../features/user/presentation/edit_profile/about_me_editor_screen.dart';
import '../../features/user/presentation/edit_profile/neuro_editor_screen.dart';
import '../../features/user/presentation/edit_profile/deep_interests_editor_screen.dart';
import '../../features/user/presentation/edit_profile/limits_editor_screen.dart';
import '../../features/user/presentation/edit_profile/dating_settings_editor_screen.dart';
import '../../features/user/presentation/edit_profile/friendship_settings_editor_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      if (state.uri.toString() == '/discovery') {
        return '/dating';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/mode-selection',
        builder: (context, state) => const ModeSelectionScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return ScaffoldWithBottomNavBar(child: child);
        },
        routes: [
          GoRoute(
            path: '/dating',
            builder: (context, state) => const DiscoveryScreen(mode: 'dating'),
          ),
          GoRoute(
            path: '/friendship',
            builder: (context, state) => const DiscoveryScreen(mode: 'friendship'),
          ),
          GoRoute(
            path: '/community',
            builder: (context, state) => const EventsListScreen(), // Placeholder for Community
          ),
          GoRoute(
            path: '/chats',
            builder: (context, state) => const ChatListScreen(),
            routes: [
                 GoRoute(
                    path: ':chatId', // /chats/:chatId
                    builder: (context, state) => ChatScreen(chatId: state.pathParameters['chatId']!),
                 ),
            ],
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
            routes: [
               GoRoute(
                 path: 'edit',
                 builder: (context, state) => const EditProfileHubScreen(),
                 routes: [
                    GoRoute(path: 'photos', builder: (c, s) => const PhotosEditorScreen()),
                    GoRoute(path: 'basic', builder: (c, s) => const BasicInfoEditorScreen()),
                    GoRoute(path: 'about', builder: (c, s) => const AboutMeEditorScreen()),
                    GoRoute(path: 'neuro', builder: (c, s) => const NeuroEditorScreen()),
                    GoRoute(path: 'deep-interests', builder: (c, s) => const DeepInterestsEditorScreen()),
                    GoRoute(path: 'limits', builder: (c, s) => const LimitsEditorScreen()),
                    GoRoute(path: 'dating-settings', builder: (c, s) => const DatingSettingsEditorScreen()),
                    GoRoute(path: 'friendship-settings', builder: (c, s) => const FriendshipSettingsEditorScreen()),
                 ]
               ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
        routes: [
             GoRoute(
                 path: 'verification',
                 builder: (context, state) => const VerificationScreen(),
             ),
        ],
      ),
      GoRoute(
        path: '/chat/:chatId', // Top level for direct access
        builder: (context, state) => ChatScreen(chatId: state.pathParameters['chatId']!),
      ),
    ],
  );
});

class ScaffoldWithBottomNavBar extends ConsumerWidget {
  final Widget child;

  const ScaffoldWithBottomNavBar({required this.child, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(authRepositoryProvider).currentUser?.uid;
    
    // Calculate unread count
    int unreadCount = 0;
    if (uid != null) {
      final chatsAsync = ref.watch(chatListProvider(uid));
      chatsAsync.whenData((chats) {
        for (var chat in chats) {
          unreadCount += (chat.unreadCounts[uid] ?? 0);
        }
      });
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _calculateSelectedIndex(context),
        onTap: (int idx) => _onItemTapped(idx, context),
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Citas'),
          const BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Amistad'),
          const BottomNavigationBarItem(icon: Icon(Icons.groups), label: 'Comunidad'),
          BottomNavigationBarItem(
              icon: Badge(
                  isLabelVisible: unreadCount > 0,
                  label: Text(unreadCount > 99 ? '99+' : unreadCount.toString()),
                  child: const Icon(Icons.chat)
              ),
              label: 'Chats'
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }

  static int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/dating')) return 0;
    if (location.startsWith('/friendship')) return 1;
    if (location.startsWith('/community')) return 2;
    if (location.startsWith('/chats')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        GoRouter.of(context).go('/dating');
        break;
      case 1:
        GoRouter.of(context).go('/friendship');
        break;
      case 2:
        GoRouter.of(context).go('/community');
        break;
      case 3:
        GoRouter.of(context).go('/chats');
        break;
      case 4:
        GoRouter.of(context).go('/profile');
        break;
    }
  }
}
