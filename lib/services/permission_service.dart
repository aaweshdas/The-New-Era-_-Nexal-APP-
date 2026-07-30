import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:flutter/foundation.dart';

class PermissionStatusModel {
  final bool photos;
  final bool camera;
  final bool microphone;
  final bool location;
  final bool notifications;

  PermissionStatusModel({
    required this.photos,
    required this.camera,
    required this.microphone,
    required this.location,
    required this.notifications,
  });

  bool get allGranted => photos && camera && microphone && location && notifications;
}

class PermissionService {
  PermissionService._();
  static final PermissionService instance = PermissionService._();

  static const String _onboardingKey = 'nexal_permissions_onboarding_shown_v1';

  /// Checks whether permission onboarding has been shown once after login
  Future<bool> hasShownOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingKey) ?? false;
  }

  /// Marks permission onboarding as completed
  Future<void> markOnboardingShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
  }

  /// Check current status of all 5 permissions
  Future<PermissionStatusModel> checkAllPermissions() async {
    try {
      final photosState = await PhotoManager.requestPermissionExtend();
      final photosGranted = photosState.isAuth || photosState.hasAccess;

      final camera = await Permission.camera.status.isGranted;
      final microphone = await Permission.microphone.status.isGranted;
      final location = await Permission.location.status.isGranted;
      final notifications = await Permission.notification.status.isGranted;

      return PermissionStatusModel(
        photos: photosGranted,
        camera: camera,
        microphone: microphone,
        location: location,
        notifications: notifications,
      );
    } catch (e) {
      debugPrint('[PermissionService] Error checking permissions: $e');
      return PermissionStatusModel(
        photos: false,
        camera: false,
        microphone: false,
        location: false,
        notifications: false,
      );
    }
  }

  /// Requests all 5 app permissions in sequence
  Future<PermissionStatusModel> requestAllPermissions() async {
    try {
      // 1. Photo Gallery Access
      final photosState = await PhotoManager.requestPermissionExtend();
      final photosGranted = photosState.isAuth || photosState.hasAccess;

      // 2. Camera, Mic, Location, Notifications
      Map<Permission, PermissionStatus> statuses = await [
        Permission.camera,
        Permission.microphone,
        Permission.location,
        Permission.notification,
      ].request();

      final cameraGranted = statuses[Permission.camera]?.isGranted ?? false;
      final micGranted = statuses[Permission.microphone]?.isGranted ?? false;
      final locGranted = statuses[Permission.location]?.isGranted ?? false;
      final notifGranted = statuses[Permission.notification]?.isGranted ?? false;

      return PermissionStatusModel(
        photos: photosGranted,
        camera: cameraGranted,
        microphone: micGranted,
        location: locGranted,
        notifications: notifGranted,
      );
    } catch (e) {
      debugPrint('[PermissionService] Error requesting permissions: $e');
      return await checkAllPermissions();
    }
  }
}
