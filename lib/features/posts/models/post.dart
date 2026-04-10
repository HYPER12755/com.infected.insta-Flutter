class Post {
  final String id;
  final String authorId;
  final String imageUrl;
  final String? caption;
  final DateTime timestamp;
  final List<String> likes;

  const Post({
    required this.id,
    required this.authorId,
    required this.imageUrl,
    this.caption,
    required this.timestamp,
    this.likes = const [],
  });

  /// Create Post from Map data (Supabase format)
  factory Post.fromMap(Map<String, dynamic> data, String id) {
    return Post(
      id: id,
      authorId: data['authorId'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      caption: data['caption'],
      timestamp: data['timestamp'] is DateTime
          ? data['timestamp']
          : DateTime.now(),
      likes: List<String>.from(data['likes'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'authorId': authorId,
      'imageUrl': imageUrl,
      'caption': caption,
      'timestamp': timestamp.toIso8601String(),
      'likes': likes,
    };
  }
}
