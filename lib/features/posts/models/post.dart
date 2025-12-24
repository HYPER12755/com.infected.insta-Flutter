import 'package:cloud_firestore/cloud_firestore.dart';

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

  factory Post.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Post(
      id: doc.id,
      authorId: data['authorId'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      caption: data['caption'],
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      likes: List<String>.from(data['likes'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'authorId': authorId,
      'imageUrl': imageUrl,
      'caption': caption,
      'timestamp': Timestamp.fromDate(timestamp),
      'likes': likes,
    };
  }
}
