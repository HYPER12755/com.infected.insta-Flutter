import 'package:flutter/material.dart';

/// Shimmer loading effect for all skeleton screens
class ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  final bool isCircle;

  const ShimmerBox({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius = 8,
    this.isCircle = false,
  });

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _anim = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: widget.isCircle ? widget.height : widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: widget.isCircle
              ? BorderRadius.circular(widget.height / 2)
              : BorderRadius.circular(widget.borderRadius),
          gradient: LinearGradient(
            begin: Alignment(_anim.value - 1, 0),
            end: Alignment(_anim.value + 1, 0),
            colors: const [
              Color(0xFF1E1E2E),
              Color(0xFF2E2E4E),
              Color(0xFF1E1E2E),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shimmer skeleton for a feed post card
class PostCardSkeleton extends StatelessWidget {
  const PostCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            const ShimmerBox(height: 40, isCircle: true),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
              ShimmerBox(width: 120, height: 12),
              SizedBox(height: 6),
              ShimmerBox(width: 80, height: 10),
            ]),
          ]),
        ),
        const ShimmerBox(height: 380, borderRadius: 0),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
            ShimmerBox(width: 200, height: 12),
            SizedBox(height: 8),
            ShimmerBox(width: 280, height: 12),
            SizedBox(height: 8),
            ShimmerBox(width: 160, height: 10),
          ]),
        ),
      ]),
    );
  }
}

/// Shimmer for user list tile
class UserTileSkeleton extends StatelessWidget {
  const UserTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(children: [
        const ShimmerBox(height: 48, isCircle: true),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
          ShimmerBox(width: 140, height: 12),
          SizedBox(height: 6),
          ShimmerBox(width: 100, height: 10),
        ])),
        const ShimmerBox(width: 72, height: 32, borderRadius: 8),
      ]),
    );
  }
}

/// Shimmer grid item
class GridItemSkeleton extends StatelessWidget {
  const GridItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) => const ShimmerBox(borderRadius: 0);
}

/// Full feed skeleton (list of PostCardSkeleton)
class FeedSkeleton extends StatelessWidget {
  const FeedSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 3,
      itemBuilder: (_, __) => const PostCardSkeleton(),
    );
  }
}
