class User {
  final String username;
  final String name;
  final String bio;
  final String avatarUrl;
  final int followers;
  final int following;
  final int posts;

  User({
    required this.username,
    required this.name,
    required this.bio,
    required this.avatarUrl,
    required this.followers,
    required this.following,
    required this.posts,
  });
}
