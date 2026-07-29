import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';

class UserProvider extends ChangeNotifier {
  final Set<String> _followingUserIds = {};

  Set<String> get followingUserIds => Set.unmodifiable(_followingUserIds);

  bool isFollowing(String userId) => _followingUserIds.contains(userId);

  void reset() {
    _followingUserIds.clear();
    notifyListeners();
  }

  Future<void> loadFollowing() async {
    final currentUserId = AuthService.instance.currentUser?.uid;
    if (currentUserId == null || currentUserId.isEmpty) return;
    try {
      final res = await Supabase.instance.client
          .from('follows')
          .select('following_id')
          .eq('follower_id', currentUserId);
      _followingUserIds.clear();
      for (final item in res) {
        final fid = item['following_id']?.toString();
        if (fid != null && fid.isNotEmpty) {
          _followingUserIds.add(fid);
        }
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> toggleFollow(String userId) async {
    final currentUserId = AuthService.instance.currentUser?.uid;
    if (_followingUserIds.contains(userId)) {
      _followingUserIds.remove(userId);
      notifyListeners();
      if (currentUserId != null && currentUserId.isNotEmpty) {
        try {
          await Supabase.instance.client
              .from('follows')
              .delete()
              .eq('follower_id', currentUserId)
              .eq('following_id', userId);
        } catch (_) {}
      }
    } else {
      _followingUserIds.add(userId);
      notifyListeners();
      if (currentUserId != null && currentUserId.isNotEmpty) {
        try {
          await Supabase.instance.client.from('follows').insert({
            'follower_id': currentUserId,
            'following_id': userId,
          });
        } catch (_) {}
      }
    }
  }
}
