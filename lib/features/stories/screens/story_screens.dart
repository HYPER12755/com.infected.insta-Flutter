import 'package:flutter/material.dart';
import 'package:infected_insta/core/theme/instagram_theme.dart';

/// Story Viewer Screen - Full screen story display with progress bars
class StoryViewerScreen extends StatefulWidget {
  final String userId;
  final String username;
  final String? userAvatar;
  final List<String> storyImages; // URLs of story images

  const StoryViewerScreen({
    super.key,
    required this.userId,
    required this.username,
    this.userAvatar,
    required this.storyImages,
  });

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen> {
  int _currentIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    // Auto advance story after 5 seconds
    _startAutoAdvance();
  }

  void _startAutoAdvance() {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && _currentIndex < widget.storyImages.length - 1) {
        setState(() {
          _currentIndex++;
        });
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        _startAutoAdvance();
      } else if (mounted) {
        Navigator.pop(context); // Close when done
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: (details) {
          // Left side - previous, Right side - next
          final screenWidth = MediaQuery.of(context).size.width;
          if (details.globalPosition.dx < screenWidth / 2) {
            // Previous
            if (_currentIndex > 0) {
              setState(() {
                _currentIndex--;
              });
              _pageController.previousPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
          } else {
            // Next
            if (_currentIndex < widget.storyImages.length - 1) {
              setState(() {
                _currentIndex++;
              });
              _pageController.nextPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            } else {
              Navigator.pop(context);
            }
          }
        },
        child: Stack(
          children: [
            // Story content
            PageView.builder(
              controller: _pageController,
              itemCount: widget.storyImages.length,
              itemBuilder: (context, index) {
                return Container(
                  color: Colors.black,
                  child: Image.network(
                    widget.storyImages[index],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) {
                      return Container(
                        color: InstagramColors.darkSurface,
                        child: const Center(
                          child: Icon(
                            Icons.image_not_supported,
                            color: Colors.white54,
                            size: 64,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            // Progress bars
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 8,
              right: 8,
              child: Row(
                children: List.generate(widget.storyImages.length, (index) {
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      height: 3,
                      decoration: BoxDecoration(
                        color: index <= _currentIndex
                            ? Colors.white
                            : Colors.white.withAlpha(77),
                        borderRadius: BorderRadius.circular(1.5),
                      ),
                    ),
                  );
                }),
              ),
            ),
            // User info header
            Positioned(
              top: MediaQuery.of(context).padding.top + 20,
              left: 12,
              right: 12,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: InstagramColors.primary,
                    backgroundImage: widget.userAvatar != null
                        ? NetworkImage(widget.userAvatar!)
                        : null,
                    child: widget.userAvatar == null
                        ? Text(
                            widget.username.isNotEmpty
                                ? widget.username[0].toUpperCase()
                                : '?',
                            style: const TextStyle(color: Colors.white),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    widget.username,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '2h',
                    style: TextStyle(
                      color: Colors.white.withAlpha(178),
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            // Quick replies (message input)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 20,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white54),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Text(
                        'Send message',
                        style: TextStyle(color: Colors.white54),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Colors.white24,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.favorite_border,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Story Create Screen - Create and share stories
class StoryCreateScreen extends StatelessWidget {
  const StoryCreateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: InstagramColors.darkBackground,
      appBar: AppBar(
        backgroundColor: InstagramColors.darkBackground,
        title: const Text(
          'New Story',
          style: TextStyle(color: InstagramColors.darkText),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Share story
              Navigator.pop(context);
            },
            child: const Text(
              'Share',
              style: TextStyle(
                color: InstagramColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Preview area
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: InstagramColors.darkSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: InstagramColors.darkTextSecondary.withAlpha(77),
                ),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 64,
                      color: InstagramColors.darkTextSecondary,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Add photo or video',
                      style: TextStyle(
                        color: InstagramColors.darkTextSecondary,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Story options
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildOption(Icons.text_fields, 'Text'),
                const SizedBox(width: 16),
                _buildOption(Icons.music_note, 'Music'),
                const SizedBox(width: 16),
                _buildOption(Icons.face, 'Effects'),
                const SizedBox(width: 16),
                _buildOption(Icons.draw, 'Draw'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOption(IconData icon, String label) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: InstagramColors.darkSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: InstagramColors.darkText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: InstagramColors.darkTextSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// Story Camera Screen - Capture story content
class StoryCameraScreen extends StatelessWidget {
  const StoryCameraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview placeholder
          const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.camera_alt_outlined,
                  size: 80,
                  color: Colors.white54,
                ),
                SizedBox(height: 16),
                Text(
                  'Camera access needed',
                  style: TextStyle(color: Colors.white54),
                ),
              ],
            ),
          ),
          // Top controls
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Icon(Icons.close, color: Colors.white, size: 28),
                Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.flash_off, color: Colors.white),
                  ],
                ),
              ],
            ),
          ),
          // Bottom controls
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 32,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Gallery
                const Icon(Icons.photo_library_outlined,
                    color: Colors.white, size: 28),
                // Capture button
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 4),
                    shape: BoxShape.circle,
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                // Flip camera
                const Icon(Icons.flip_camera_ios_outlined,
                    color: Colors.white, size: 28),
              ],
            ),
          ),
        ],
      ),
    );
  }
}