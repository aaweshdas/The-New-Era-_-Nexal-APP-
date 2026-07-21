import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/post_model.dart';

class FeedProvider extends ChangeNotifier {
  final List<PostModel> _posts = [];
  final Set<String> _bookmarkedIds = {};
  bool _isLoading = false;

  List<PostModel> get posts => List.unmodifiable(_posts);
  Set<String> get bookmarkedIds => Set.unmodifiable(_bookmarkedIds);
  bool get isLoading => _isLoading;

  FeedProvider() {
    _loadInitialPosts();
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('bookmarked_posts') ?? [];
    _bookmarkedIds.addAll(list);
    notifyListeners();
  }

  Future<void> _saveBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('bookmarked_posts', _bookmarkedIds.toList());
  }

  void _loadInitialPosts() {
    _posts.addAll([
      PostModel(
        id: 'p1',
        userId: 'u1',
        userName: 'Nova Chen',
        userAvatar:
            'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200',
        isVerified: true,
        content:
            'Witnessing the future unfold in real-time ✨ The quantum realm is closer than ever.',
        imageUrl:
            'https://images.unsplash.com/photo-1589017232573-9d001e5cb52c?w=800',
        timeAgo: '2h ago',
        likes: 2847,
        commentsCount: 156,
        sharesCount: 89,
        viewsCount: 15420,
      ),
      PostModel(
        id: 'p2',
        userId: 'u2',
        userName: 'Kai Nakamura',
        userAvatar:
            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200',
        isVerified: false,
        content:
            'The intersection of art and technology creates pure magic 🎨⚡',
        imageUrl:
            'https://images.unsplash.com/photo-1611086615542-635f48ae4656?w=800',
        timeAgo: '4h ago',
        likes: 1923,
        commentsCount: 92,
        sharesCount: 64,
        viewsCount: 9876,
      ),
      PostModel(
        id: 'p3',
        userId: 'u3',
        userName: 'Zara Williams',
        userAvatar:
            'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=200',
        isVerified: true,
        content:
            'Exploring uncharted territories 🚀 No map, just instinct and pure curiosity.',
        imageUrl:
            'https://images.unsplash.com/photo-1681118143075-5f5a10c9c092?w=800',
        timeAgo: '6h ago',
        likes: 3456,
        commentsCount: 234,
        sharesCount: 128,
        viewsCount: 21340,
      ),
    ]);
    notifyListeners();
  }

  void toggleLike(String postId) {
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index != -1) {
      final post = _posts[index];
      post.isLiked = !post.isLiked;
      if (post.isLiked) {
        post.likes++;
      } else {
        post.likes--;
      }
      notifyListeners();
    }
  }

  void toggleBookmark(String postId) {
    if (_bookmarkedIds.contains(postId)) {
      _bookmarkedIds.remove(postId);
    } else {
      _bookmarkedIds.add(postId);
    }
    _saveBookmarks();
    notifyListeners();
  }

  void addPost(PostModel post) {
    _posts.insert(0, post);
    notifyListeners();
  }

  Future<void> refreshFeed() async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 1200));
    _isLoading = false;
    notifyListeners();
  }
}
