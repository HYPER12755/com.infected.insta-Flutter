import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/auth/providers/firestore_provider.dart';
import '../models/post.dart';

final postRepositoryProvider = Provider((ref) => PostRepository(ref.watch(firestoreProvider)));

class PostRepository {
  final FirebaseFirestore _firestore;

  PostRepository(this._firestore);

  Future<void> createPost(Post post) async {
    await _firestore.collection('posts').add(post.toJson());
  }

  Stream<List<Post>> getPosts() {
    return _firestore
        .collection('posts')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Post.fromDoc(doc)).toList();
    });
  }

  Future<void> likePost(String postId, String userId) async {
    await _firestore.collection('posts').doc(postId).update({
      'likes': FieldValue.arrayUnion([userId])
    });
  }

  Future<void> unlikePost(String postId, String userId) async {
    await _firestore.collection('posts').doc(postId).update({
      'likes': FieldValue.arrayRemove([userId])
    });
  }
}
