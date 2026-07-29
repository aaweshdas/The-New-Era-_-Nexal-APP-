class UserModel {
  final String uid;
  final String name;
  final String username;
  final String email;
  final String avatarUrl;
  final String coverUrl;
  final String bio;
  final String location;
  final String website;
  final String badge;
  final int energy;
  final int connections;
  final int influence;
  final int postsCount;
  final int followersCount;
  final int followingCount;
  final bool isVerified;

  UserModel({
    required this.uid,
    required this.name,
    required this.username,
    required this.email,
    required this.avatarUrl,
    this.coverUrl = '',
    this.bio = '',
    this.location = '',
    this.website = '',
    this.badge = '',
    this.energy = 0,
    this.connections = 0,
    this.influence = 0,
    this.postsCount = 0,
    this.followersCount = 0,
    this.followingCount = 0,
    this.isVerified = false,
  });

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'name': name,
        'username': username,
        'email': email,
        'avatarUrl': avatarUrl,
        'coverUrl': coverUrl,
        'bio': bio,
        'location': location,
        'website': website,
        'badge': badge,
        'energy': energy,
        'connections': connections,
        'influence': influence,
        'postsCount': postsCount,
        'followersCount': followersCount,
        'followingCount': followingCount,
        'isVerified': isVerified,
      };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        uid: json['uid'] as String? ?? '',
        name: json['name'] as String? ?? '',
        username: json['username'] as String? ?? '',
        email: json['email'] as String? ?? '',
        avatarUrl: json['avatarUrl'] as String? ?? json['avatar_url'] as String? ?? '',
        coverUrl: json['coverUrl'] as String? ?? json['cover_url'] as String? ?? '',
        bio: json['bio'] as String? ?? '',
        location: json['location'] as String? ?? '',
        website: json['website'] as String? ?? '',
        badge: json['badge'] as String? ?? '',
        energy: (json['energy'] as int?) ?? 0,
        connections: (json['connections'] as int?) ?? (json['followers_count'] as int?) ?? 0,
        influence: (json['influence'] as int?) ?? (json['following_count'] as int?) ?? 0,
        postsCount: (json['postsCount'] as int?) ?? (json['posts_count'] as int?) ?? 0,
        followersCount: (json['followersCount'] as int?) ?? (json['followers_count'] as int?) ?? 0,
        followingCount: (json['followingCount'] as int?) ?? (json['following_count'] as int?) ?? 0,
        isVerified: (json['isVerified'] as bool?) ?? (json['is_verified'] as bool?) ?? false,
      );
}
