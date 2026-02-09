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
import '../../features/user/presentation/settings_screen.dart';
import '../../features/user/presentation/verification_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
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
      ShellRoute(
        builder: (context, state, child) {
          return ScaffoldWithBottomNavBar(child: child);
        },
        routes: [
          GoRoute(
            path: '/discovery',
            builder: (context, state) => const DiscoveryScreen(),
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
            path: '/events',
            builder: (context, state) => const EventsListScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
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
          const BottomNavigationBarItem(icon: Icon(Icons.style), label: 'Discover'),
          BottomNavigationBarItem(
              icon: Badge(
                  isLabelVisible: unreadCount > 0,
                  label: Text(unreadCount > 99 ? '99+' : unreadCount.toString()),
                  child: const Icon(Icons.chat)
              ),
              label: 'Chats'
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Events'),
          const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  static int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/discovery')) return 0;
    if (location.startsWith('/chats')) return 1;
    if (location.startsWith('/events')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        GoRouter.of(context).go('/discovery');
        break;
      case 1:
        GoRouter.of(context).go('/chats');
        break;
      case 2:
        GoRouter.of(context).go('/events');
        break;
      case 3:
        GoRouter.of(context).go('/profile');
        break;
    }
  }
}
