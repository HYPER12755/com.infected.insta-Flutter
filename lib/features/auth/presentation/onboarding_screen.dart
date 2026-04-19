import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

import 'package:infected_insta/data/repositories/user_repository.dart';
import 'package:infected_insta/supabase/supabase_client.dart';

// ─── Full Onboarding PageView ─────────────────────────────────────────────────
class OnboardingPageView extends ConsumerStatefulWidget {
  const OnboardingPageView({super.key});
  @override
  ConsumerState<OnboardingPageView> createState() => _OnboardingPageViewState();
}

class _OnboardingPageViewState extends ConsumerState<OnboardingPageView> {
  final _pageCtrl = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < 2) {
      _pageCtrl.nextPage(
          duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: SafeArea(child: Column(children: [
        // Skip button
        Align(alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 12, 20, 0),
            child: TextButton(
              onPressed: () => context.go('/home'),
              child: const Text('Skip', style: TextStyle(color: Colors.white38)),
            ),
          )),

        // Pages
        Expanded(
          child: PageView(
            controller: _pageCtrl,
            onPageChanged: (p) => setState(() => _page = p),
            children: [
              _OnboardingPage(
                icon: FontAwesomeIcons.images,
                title: 'Share Your World',
                subtitle: 'Post photos and videos to share your favorite moments with friends and followers.',
                gradient: [const Color(0xFFC039FF), const Color(0xFF6C3FFF)],
              ),
              _OnboardingPage(
                icon: FontAwesomeIcons.message,
                title: 'Connect with Friends',
                subtitle: 'Send direct messages, share posts, and stay connected with the people that matter.',
                gradient: [const Color(0xFF6C3FFF), const Color(0xFF3F7FFF)],
              ),
              _SuggestedUsersPage(onSkip: () => context.go('/home'),
                  onContinue: () => context.go('/home')),
            ],
          ),
        ),

        // Dots + button
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (int i = 0; i < 3; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _page == i ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _page == i ? primary : Colors.white24,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
            ]),
            const SizedBox(height: 24),
            if (_page < 2)
              SizedBox(width: double.infinity,
                child: ElevatedButton(
                  onPressed: _next,
                  child: const Text('Continue', style: TextStyle(fontWeight: FontWeight.bold)),
                )),
          ]),
        ),
      ])),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final FaIconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;

  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 120, height: 120,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: gradient,
                begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(36),
          ),
          child: Center(child: FaIcon(icon, size: 52, color: Colors.white)),
        ),
        const SizedBox(height: 40),
        Text(title, textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold,
                color: Colors.white)),
        const SizedBox(height: 16),
        Text(subtitle, textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.white54, height: 1.5)),
      ]),
    );
  }
}

class _SuggestedUsersPage extends StatefulWidget {
  final VoidCallback onSkip;
  final VoidCallback onContinue;
  const _SuggestedUsersPage({required this.onSkip, required this.onContinue});
  @override
  State<_SuggestedUsersPage> createState() => _SuggestedUsersPageState();
}

class _SuggestedUsersPageState extends State<_SuggestedUsersPage> {
  final _userRepo = UserRepository();
  List<Map<String, dynamic>> _users = [];
  final Set<String> _following = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) { setState(() => _isLoading = false); return; }
    final result = await _userRepo.getSuggestedUsers(uid);
    result.fold(
      (_) => setState(() => _isLoading = false),
      (u) => setState(() { _users = u.take(8).toList(); _isLoading = false; }),
    );
  }

  Future<void> _toggle(String userId) async {
    final myId = supabase.auth.currentUser?.id;
    if (myId == null) return;
    setState(() {
      if (_following.contains(userId)) {
        _following.remove(userId);
      } else {
        _following.add(userId);
      }
    });
    if (_following.contains(userId)) {
      await _userRepo.followUser(myId, userId);
    } else {
      await _userRepo.unfollowUser(myId, userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(children: [
        const SizedBox(height: 20),
        const Text('Follow People', textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Follow accounts you are interested in.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54)),
        const SizedBox(height: 20),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _users.isEmpty
                  ? const Center(child: Text('No suggestions yet',
                      style: TextStyle(color: Colors.white38)))
                  : ListView.builder(
                      itemCount: _users.length,
                      itemBuilder: (_, i) {
                        final u = _users[i];
                        final id = u['id'] as String? ?? '';
                        final isFollowing = _following.contains(id);
                        final avatar = u['avatar_url'] as String? ?? '';
                        final username = u['username'] as String? ?? '';
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFF2A2A3E),
                            backgroundImage: avatar.isNotEmpty
                                ? NetworkImage(avatar) as ImageProvider : null,
                            child: avatar.isEmpty
                                ? Text(username.isNotEmpty ? username[0].toUpperCase() : 'U',
                                    style: const TextStyle(color: Colors.white)) : null,
                          ),
                          title: Text(username,
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(u['full_name'] ?? username,
                              style: const TextStyle(color: Colors.white38, fontSize: 12)),
                          trailing: GestureDetector(
                            onTap: () => _toggle(id),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                color: isFollowing ? const Color(0xFF2A2A3E) : primary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(isFollowing ? 'Following' : 'Follow',
                                  style: TextStyle(
                                    color: isFollowing ? Colors.white54 : Colors.white,
                                    fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ),
                        );
                      }),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: SizedBox(width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.onContinue,
              child: const Text('Get Started',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
        ),
      ]),
    );
  }
}

// ─── Legacy stubs (router references) ────────────────────────────────────────
class OnboardingScreen1 extends StatelessWidget {
  final VoidCallback onNext;
  const OnboardingScreen1({super.key, required this.onNext});
  @override
  Widget build(BuildContext context) => const OnboardingPageView();
}

class OnboardingScreen2 extends StatelessWidget {
  final VoidCallback onNext;
  const OnboardingScreen2({super.key, required this.onNext});
  @override
  Widget build(BuildContext context) => const OnboardingPageView();
}

class OnboardingScreen3 extends StatelessWidget {
  final VoidCallback onNext;
  const OnboardingScreen3({super.key, required this.onNext});
  @override
  Widget build(BuildContext context) => const OnboardingPageView();
}
