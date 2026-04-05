import 'package:flutter/material.dart';
import 'package:infected_insta/core/theme/instagram_theme.dart';
import 'package:infected_insta/features/auth/presentation/login_page.dart';

/// Onboarding Screen 1 - Welcome
class OnboardingScreen1 extends StatelessWidget {
  final VoidCallback onNext;

  const OnboardingScreen1({super.key, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: InstagramColors.darkBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Spacer(),
              // Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: InstagramColors.instagramGradient,
                  ),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Icon(
                  Icons.camera_alt_outlined,
                  size: 60,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 40),
              // Title
              const Text(
                'Share Photos & Videos',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: InstagramColors.darkText,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              // Subtitle
              Text(
                'Share your favorite moments with friends and followers.',
                style: TextStyle(
                  fontSize: 16,
                  color: InstagramColors.darkTextSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              // Next Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onNext,
                  child: const Text('Next'),
                ),
              ),
              const SizedBox(height: 16),
              // Skip Button
              TextButton(
                onPressed: () {
                  // Skip to login
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LoginPage(showSignupPage: () {}),
                    ),
                  );
                },
                child: Text(
                  'Skip',
                  style: TextStyle(color: InstagramColors.darkTextSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Onboarding Screen 2 - Connect
class OnboardingScreen2 extends StatelessWidget {
  final VoidCallback onNext;

  const OnboardingScreen2({super.key, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: InstagramColors.darkBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Spacer(),
              // Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: InstagramColors.instagramGradient,
                  ),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Icon(
                  Icons.people_outline,
                  size: 60,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 40),
              // Title
              const Text(
                'Connect with Friends',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: InstagramColors.darkText,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              // Subtitle
              Text(
                'Follow accounts you love and see what they\'re up to.',
                style: TextStyle(
                  fontSize: 16,
                  color: InstagramColors.darkTextSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              // Next Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onNext,
                  child: const Text('Next'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Onboarding Screen 3 - Explore
class OnboardingScreen3 extends StatelessWidget {
  final VoidCallback onNext;

  const OnboardingScreen3({super.key, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: InstagramColors.darkBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Spacer(),
              // Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: InstagramColors.instagramGradient,
                  ),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Icon(
                  Icons.explore_outlined,
                  size: 60,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 40),
              // Title
              const Text(
                'Explore Your Interests',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: InstagramColors.darkText,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              // Subtitle
              Text(
                'Discover new content and connect with communities that share your passions.',
                style: TextStyle(
                  fontSize: 16,
                  color: InstagramColors.darkTextSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              // Get Started Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onNext,
                  child: const Text('Get Started'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Onboarding Page View Controller
class OnboardingPageView extends StatefulWidget {
  const OnboardingPageView({super.key});

  @override
  State<OnboardingPageView> createState() => _OnboardingPageViewState();
}

class _OnboardingPageViewState extends State<OnboardingPageView> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    _pages.addAll([
      OnboardingScreen1(
        onNext: () => _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        ),
      ),
      OnboardingScreen2(
        onNext: () => _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        ),
      ),
      OnboardingScreen3(
        onNext: () {
          // Navigate to login
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => LoginPage(showSignupPage: () {}),
            ),
          );
        },
      ),
    ]);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: InstagramColors.darkBackground,
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _currentPage = index);
              },
              children: _pages,
            ),
          ),
          // Page Indicator
          Padding(
            padding: const EdgeInsets.only(bottom: 40),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? InstagramColors.primary
                        : InstagramColors.darkTextSecondary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
