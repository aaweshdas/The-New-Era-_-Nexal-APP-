class UserModel {
  final String uid;
  final String name;
  final String username;
  final String email;
  final String avatarUrl;
  final String bio;
  final String website;
  final int energy;
  final int connections;
  final int influence;
  final bool isVerified;

  UserModel({
    required this.uid,
    required this.name,
    required this.username,
    required this.email,
    required this.avatarUrl,
    this.bio = 'Exploring the quantum realm of digital consciousness ✨',
    this.website = 'nexal.space',
    this.energy = 2400,
    this.connections = 12500,
    this.influence = 8900,
    this.isVerified = true,
  });

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'name': name,
        'username': username,
        'email': email,
        'avatarUrl': avatarUrl,
        'bio': bio,
        'website': website,
        'energy': energy,
        'connections': connections,
        'influence': influence,
        'isVerified': isVerified,
      };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        uid: json['uid'] as String,
        name: json['name'] as String,
        username: json['username'] as String,
        email: json['email'] as String,
        avatarUrl: json['avatarUrl'] as String,
        bio: (json['bio'] as String?) ?? '',
        website: (json['website'] as String?) ?? '',
        energy: (json['energy'] as int?) ?? 0,
        connections: (json['connections'] as int?) ?? 0,
        influence: (json['influence'] as int?) ?? 0,
        isVerified: (json['isVerified'] as bool?) ?? false,
      );
}
