import 'package:go_router/go_router.dart';
import 'package:infected_insta/features/auth/presentation/auth_screen.dart';
import 'package:infected_insta/features/splash/screens/splash_screen.dart';
import 'package:infected_insta/features/auth/presentation/onboarding_screen.dart';
import 'package:infected_insta/features/auth/presentation/forgot_password_screen.dart';
import 'package:infected_insta/features/home/home_page.dart';
import 'package:infected_insta/features/feed/screens/post_screens.dart';
import 'package:infected_insta/features/search/screens/explore_screen.dart';
import 'package:infected_insta/features/create_post/screens/create_screens.dart';
import 'package:infected_insta/features/reels/screens/reels_screen.dart';
import 'package:infected_insta/features/profile/screens/profile_screen.dart';
import 'package:infected_insta/features/profile/presentation/edit_profile_screen.dart';
import 'package:infected_insta/features/settings/presentation/settings_screen.dart';
import 'package:infected_insta/features/chat/screens/messages_screens.dart';
import 'package:infected_insta/features/activity/screens/notification_screens.dart';
import 'package:infected_insta/features/call/screens/call_screen.dart';
import 'package:infected_insta/features/call/screens/video_call_screen.dart';
import 'package:infected_insta/features/call/models/call_model.dart';
import 'package:infected_insta/features/stories/screens/story_screens.dart';
import 'package:infected_insta/features/extra/screens/extra_screens.dart';
import 'package:infected_insta/supabase/supabase_client.dart';

final router = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    final isLoggedIn = supabase.auth.currentSession != null;
    final loc = state.matchedLocation;

    final isAuthRoute = loc == '/auth' || loc == '/login' || loc == '/signup' ||
        loc == '/forgot-password' || loc.startsWith('/onboarding');

    // Splash screen always allowed
    if (loc == '/') return null;

    if (!isLoggedIn && !isAuthRoute) return '/auth';
    if (isLoggedIn && isAuthRoute) return '/home';
    return null;
  },
  routes: [
    // ── Splash & Auth ──────────────────────────────────────────────────────
    GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/auth', builder: (_, __) => const AuthScreen()),
    GoRoute(path: '/login', builder: (_, __) => const AuthScreen()),
    GoRoute(path: '/signup', builder: (_, __) => const AuthScreen()),
    GoRoute(path: '/forgot-password', builder: (_, __) => const ForgotPasswordScreen()),
    GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingPageView()),
    GoRoute(path: '/onboarding1', builder: (_, s) => OnboardingScreen1(onNext: () {})),
    GoRoute(path: '/onboarding2', builder: (_, s) => OnboardingScreen2(onNext: () {})),
    GoRoute(path: '/onboarding3', builder: (_, s) => OnboardingScreen3(onNext: () {})),

    // ── Main App ───────────────────────────────────────────────────────────
    GoRoute(path: '/home', builder: (_, __) => const HomePage()),

    // ── Post ──────────────────────────────────────────────────────────────
    GoRoute(
      path: '/post/:id',
      builder: (_, state) => PostDetailScreen(postId: state.pathParameters['id'] ?? ''),
    ),

    // ── Explore / Search ──────────────────────────────────────────────────
    GoRoute(path: '/explore', builder: (_, __) => const ExploreScreen()),
    GoRoute(path: '/trending', builder: (_, __) => const TrendingTagsScreen()),
    GoRoute(
      path: '/search/:query',
      builder: (_, state) =>
          UserSearchResultsScreen(query: state.pathParameters['query'] ?? ''),
    ),

    // ── Create ────────────────────────────────────────────────────────────
    GoRoute(path: '/create', builder: (_, __) => const CreatePostScreen()),
    GoRoute(path: '/camera', builder: (_, __) => const CameraCaptureScreen()),
    GoRoute(path: '/edit', builder: (_, __) => const EditCropScreen()),

    // ── Reels ─────────────────────────────────────────────────────────────
    GoRoute(path: '/reels', builder: (_, __) => const ReelsScreen()),

    // ── Profile ───────────────────────────────────────────────────────────
    GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
    GoRoute(path: '/profile/edit', builder: (_, __) => const EditProfileScreen()),
    GoRoute(
      path: '/profile/:username',
      builder: (_, state) {
        final username = state.pathParameters['username'] ?? '';
        return ProfileScreen(userId: username);
      },
    ),
    GoRoute(path: '/archive', builder: (_, __) => const ArchiveViewScreen()),
    GoRoute(path: '/saved', builder: (_, __) => const SavedPostsScreen()),
    GoRoute(path: '/tagged', builder: (_, __) => const TaggedPostsScreen()),
    GoRoute(path: '/highlights', builder: (_, __) => const StoryHighlightsScreen()),
    GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),

    // ── Followers / Following ──────────────────────────────────────────────
    GoRoute(
      path: '/followers/:userId',
      builder: (_, state) => FollowListScreen(
        userId: state.pathParameters['userId'] ?? '',
        type: 'followers',
        username: state.uri.queryParameters['username'] ?? '',
      ),
    ),
    GoRoute(
      path: '/following/:userId',
      builder: (_, state) => FollowListScreen(
        userId: state.pathParameters['userId'] ?? '',
        type: 'following',
        username: state.uri.queryParameters['username'] ?? '',
      ),
    ),

    // ── Messages ──────────────────────────────────────────────────────────
    GoRoute(path: '/messages', builder: (_, __) => const MessagesInboxScreen()),
    GoRoute(
      path: '/chat/:id',
      builder: (_, state) => ConversationChatScreen(
        conversationId: state.pathParameters['id'] ?? '',
        username: state.uri.queryParameters['username'] ?? 'User',
      ),
    ),
    GoRoute(path: '/new-message', builder: (_, __) => const NewMessageScreen()),
    GoRoute(path: '/message-requests', builder: (_, __) => const MessageRequestsScreen()),

    // ── Notifications ─────────────────────────────────────────────────────
    GoRoute(path: '/notifications', builder: (_, __) => const ActivityFeedScreen()),
    GoRoute(path: '/follow-requests', builder: (_, __) => const FollowRequestsScreen()),
    GoRoute(
      path: '/likes/:postId',
      builder: (_, state) =>
          LikesCommentsScreen(type: 'likes', postId: state.pathParameters['postId'] ?? ''),
    ),
    GoRoute(
      path: '/comments/:postId',
      builder: (_, state) =>
          LikesCommentsScreen(type: 'comments', postId: state.pathParameters['postId'] ?? ''),
    ),

    // ── Calls ─────────────────────────────────────────────────────────────
    GoRoute(
      path: '/call',
      builder: (_, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return CallScreen(
          calleeId: extra?['calleeId'] as String?,
          calleeName: extra?['calleeName'] as String?,
          calleeAvatar: extra?['calleeAvatar'] as String?,
          callType: extra?['callType'] as CallType?,
        );
      },
    ),
    GoRoute(path: '/video-call', builder: (_, __) => const VideoCallScreen()),

    // ── Stories ───────────────────────────────────────────────────────────
    GoRoute(
      path: '/story/:userId',
      builder: (_, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return StoryViewerScreen(
          userId: state.pathParameters['userId'] ?? '',
          username: extra['username'] as String? ?? 'User',
          userAvatar: extra['avatar'] as String?,
          storyImages: (extra['images'] as List<dynamic>?)?.cast<String>() ?? [],
        );
      },
    ),
    GoRoute(path: '/story-create', builder: (_, __) => const StoryCreateScreen()),
    GoRoute(path: '/story-camera', builder: (_, __) => const StoryCameraScreen()),
  ],
);
