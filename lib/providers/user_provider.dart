import 'package:flutter/material.dart';

class UserProvider extends ChangeNotifier {
  final Set<String> _followingUserIds = {};

  Set<String> get followingUserIds => Set.unmodifiable(_followingUserIds);

  bool isFollowing(String userId) => _followingUserIds.contains(userId);

  void toggleFollow(String userId) {
    if (_followingUserIds.contains(userId)) {
      _followingUserIds.remove(userId);
    } else {
      _followingUserIds.add(userId);
    }
    notifyListeners();
  }
}
