import 'package:flutter/material.dart';

import '../../../features/posts/models/post.dart';

class PostCard extends StatelessWidget {
  final Post post;

  const PostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          Image.network(post.imageUrl),
          if (post.caption != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(post.caption!),
            ),
        ],
      ),
    );
  }
}
