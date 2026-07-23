class PostModel {
  final String id;
  final String userId;
  final String userName;
  final String userAvatar;
  final bool isVerified;
  final String content;
  final String? imageUrl;
  final String? videoUrl;
  final String timeAgo;
  final String? location; // GPS location label
  int likes;
  int commentsCount;
  int sharesCount;
  int viewsCount;
  bool isLiked;
  bool isBookmarked;

  PostModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    this.isVerified = false,
    required this.content,
    this.imageUrl,
    this.videoUrl,
    required this.timeAgo,
    this.location,
    this.likes = 0,
    this.commentsCount = 0,
    this.sharesCount = 0,
    this.viewsCount = 0,
    this.isLiked = false,
    this.isBookmarked = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'userName': userName,
        'userAvatar': userAvatar,
        'isVerified': isVerified,
        'content': content,
        'imageUrl': imageUrl,
        'videoUrl': videoUrl,
        'timeAgo': timeAgo,
        'likes': likes,
        'commentsCount': commentsCount,
        'sharesCount': sharesCount,
        'viewsCount': viewsCount,
        'isLiked': isLiked,
        'isBookmarked': isBookmarked,
      };

  factory PostModel.fromJson(Map<String, dynamic> json) => PostModel(
        id: json['id'] as String,
        userId: json['userId'] as String,
        userName: json['userName'] as String,
        userAvatar: json['userAvatar'] as String,
        isVerified: (json['isVerified'] as bool?) ?? false,
        content: json['content'] as String,
        imageUrl: json['imageUrl'] as String?,
        videoUrl: json['videoUrl'] as String?,
        timeAgo: json['timeAgo'] as String,
        likes: (json['likes'] as int?) ?? 0,
        commentsCount: (json['commentsCount'] as int?) ?? 0,
        sharesCount: (json['sharesCount'] as int?) ?? 0,
        viewsCount: (json['viewsCount'] as int?) ?? 0,
        isLiked: (json['isLiked'] as bool?) ?? false,
        isBookmarked: (json['isBookmarked'] as bool?) ?? false,
      );
}
