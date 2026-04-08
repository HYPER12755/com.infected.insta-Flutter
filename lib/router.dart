import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

// Router with Firebase auth check
final router = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    final user = FirebaseAuth.instance.currentUser;
    final isLoggedIn = user != null;
    final isAuthRoute =
        state.matchedLocation == '/auth' ||
        state.matchedLocation == '/login' ||
        state.matchedLocation == '/signup' ||
        state.matchedLocation == '/forgot-password' ||
        state.matchedLocation.startsWith('/onboarding');

    // If not logged in and trying to access auth routes, allow it
    if (!isLoggedIn && isAuthRoute) {
      return null;
    }

    // If not logged in and trying to access protected routes, redirect to login
    if (!isLoggedIn && !isAuthRoute) {
      return '/login';
    }

    // If logged in and trying to access auth routes, redirect to home
    if (isLoggedIn && isAuthRoute) {
      return '/home';
    }

    return null;
  },
  routes: [
    // Splash & Auth
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/auth', builder: (context, state) => const AuthScreen()),
    GoRoute(path: '/login', builder: (context, state) => const AuthScreen()),
    GoRoute(path: '/signup', builder: (context, state) => const AuthScreen()),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: '/onboarding1',
      builder: (context, state) => OnboardingScreen1(onNext: () {}),
    ),
    GoRoute(
      path: '/onboarding2',
      builder: (context, state) => OnboardingScreen2(onNext: () {}),
    ),
    GoRoute(
      path: '/onboarding3',
      builder: (context, state) => OnboardingScreen3(onNext: () {}),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingPageView(),
    ),

    // Main App - Home
    GoRoute(path: '/home', builder: (context, state) => const HomePage()),

    // Post Details
    GoRoute(
      path: '/post/:id',
      builder: (context, state) {
        final postId = state.pathParameters['id'] ?? '';
        return PostDetailScreen(postId: postId);
      },
    ),

    // Search/Explore
    GoRoute(
      path: '/explore',
      builder: (context, state) => const ExploreScreen(),
    ),
    GoRoute(
      path: '/trending',
      builder: (context, state) => const TrendingTagsScreen(),
    ),
    GoRoute(
      path: '/search/:query',
      builder: (context, state) {
        final query = state.pathParameters['query'] ?? '';
        return UserSearchResultsScreen(query: query);
      },
    ),

    // Create Post
    GoRoute(
      path: '/create',
      builder: (context, state) => const CreatePostScreen(),
    ),
    GoRoute(
      path: '/camera',
      builder: (context, state) => const CameraCaptureScreen(),
    ),
    GoRoute(path: '/edit', builder: (context, state) => const EditCropScreen()),

    // Reels
    GoRoute(path: '/reels', builder: (context, state) => const ReelsScreen()),

    // Profile
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/profile/edit',
      builder: (context, state) => const EditProfileScreen(),
    ),
    GoRoute(
      path: '/archive',
      builder: (context, state) => const ArchiveViewScreen(),
    ),
    GoRoute(
      path: '/saved',
      builder: (context, state) => const SavedPostsScreen(),
    ),
    GoRoute(
      path: '/tagged',
      builder: (context, state) => const TaggedPostsScreen(),
    ),
    GoRoute(
      path: '/highlights',
      builder: (context, state) => const StoryHighlightsScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),

    // Messages
    GoRoute(
      path: '/messages',
      builder: (context, state) => const MessagesInboxScreen(),
    ),
    GoRoute(
      path: '/chat/:id',
      builder: (context, state) {
        final conversationId = state.pathParameters['id'] ?? '';
        // For demo, use a default username
        return ConversationChatScreen(
          conversationId: conversationId,
          username: 'User',
        );
      },
    ),
    GoRoute(
      path: '/new-message',
      builder: (context, state) => const NewMessageScreen(),
    ),
    GoRoute(
      path: '/message-requests',
      builder: (context, state) => const MessageRequestsScreen(),
    ),

    // Notifications
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const ActivityFeedScreen(),
    ),
    GoRoute(
      path: '/follow-requests',
      builder: (context, state) => const FollowRequestsScreen(),
    ),
    GoRoute(
      path: '/likes/:postId',
      builder: (context, state) {
        final postId = state.pathParameters['postId'] ?? '';
        return LikesCommentsScreen(type: 'likes', postId: postId);
      },
    ),
    GoRoute(
      path: '/comments/:postId',
      builder: (context, state) {
        final postId = state.pathParameters['postId'] ?? '';
        return LikesCommentsScreen(type: 'comments', postId: postId);
      },
    ),

    // Call routes
    GoRoute(
      path: '/call',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return CallScreen(
          calleeId: extra?['calleeId'] as String?,
          calleeName: extra?['calleeName'] as String?,
          calleeAvatar: extra?['calleeAvatar'] as String?,
          callType: extra?['callType'] as CallType?,
        );
      },
    ),
    GoRoute(
      path: '/video-call',
      builder: (context, state) => const VideoCallScreen(),
    ),

    // Stories
    GoRoute(
      path: '/story/:userId',
      builder: (context, state) {
        final userId = state.pathParameters['userId'] ?? '';
        final extra = state.extra as Map<String, dynamic>?;
        return StoryViewerScreen(
          userId: userId,
          username: extra?['username'] as String? ?? 'User',
          userAvatar: extra?['avatar'] as String?,
          storyImages:
              (extra?['images'] as List<dynamic>?)?.cast<String>() ?? [],
        );
      },
    ),
    GoRoute(
      path: '/story-create',
      builder: (context, state) => const StoryCreateScreen(),
    ),
    GoRoute(
      path: '/story-camera',
      builder: (context, state) => const StoryCameraScreen(),
    ),
  ],
);
