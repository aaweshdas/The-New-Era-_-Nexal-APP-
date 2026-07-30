import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/post_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class FeedProvider extends ChangeNotifier {
  final List<PostModel> _posts = [];
  final Set<String> _bookmarkedIds = {};
  bool _isLoading = false;

  List<PostModel> get posts => List.unmodifiable(_posts);
  Set<String> get bookmarkedIds => Set.unmodifiable(_bookmarkedIds);
  bool get isLoading => _isLoading;

  String get _bookmarkKey {
    final uid = AuthService.instance.currentUser?.uid ?? '';
    return uid.isNotEmpty ? 'bookmarked_posts_$uid' : 'bookmarked_posts';
  }

  FeedProvider() {
    _loadBookmarks();
    fetchLivePosts();
  }

  void reset() {
    _posts.clear();
    _bookmarkedIds.clear();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_bookmarkKey) ?? [];
    _bookmarkedIds.clear();
    _bookmarkedIds.addAll(list);
    notifyListeners();
  }

  Future<void> _saveBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_bookmarkKey, _bookmarkedIds.toList());
  }

  Future<void> fetchLivePosts() async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await ApiService.instance.get('/api/posts');
      if (res is List) {
        final fetched = res.map((json) => PostModel.fromJson(json)).toList();
        _posts.clear();
        _posts.addAll(fetched);
      }
    } catch (_) {
      // Backend error or offline — leave feed clear or keep optimistic posts
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void toggleLike(String postId) {
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index != -1) {
      final post = _posts[index];
      final wasLiked = post.isLiked;
      post.isLiked = !wasLiked;
      if (post.isLiked) {
        post.likes++;
      } else {
        post.likes--;
      }
      notifyListeners();
      ApiService.instance.post('/api/posts/$postId/like', {}).catchError((_) {
        // Rollback optimistic update on error
        post.isLiked = wasLiked;
        if (wasLiked) {
          post.likes++;
        } else {
          post.likes--;
        }
        notifyListeners();
        return null;
      });
    }
  }

  void toggleBookmark(String postId) {
    final wasBookmarked = _bookmarkedIds.contains(postId);
    if (wasBookmarked) {
      _bookmarkedIds.remove(postId);
    } else {
      _bookmarkedIds.add(postId);
    }
    _saveBookmarks();
    notifyListeners();
    ApiService.instance.post('/api/posts/$postId/bookmark', {}).catchError((_) {
      if (wasBookmarked) {
        _bookmarkedIds.add(postId);
      } else {
        _bookmarkedIds.remove(postId);
      }
      _saveBookmarks();
      notifyListeners();
      return null;
    });
  }

  void addPost(PostModel post) {
    _posts.insert(0, post);
    notifyListeners();
    ApiService.instance.post('/api/posts', post.toJson()).catchError((_) => null);
  }

  Future<void> refreshFeed() async {
    await fetchLivePosts();
  }
}
