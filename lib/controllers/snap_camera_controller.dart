import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

enum FlashModeState { off, on, auto }

class DrawingPoint {
  final Offset offset;
  final Paint paint;
  DrawingPoint({required this.offset, required this.paint});
}

class SnapFilterItem {
  final String id;
  final String name;
  final String category;
  final String iconUrl;

  const SnapFilterItem({
    required this.id,
    required this.name,
    required this.category,
    required this.iconUrl,
  });
}

class SnapCameraController extends ChangeNotifier {
  CameraController? cameraController;
  List<CameraDescription> cameras = [];
  int selectedCameraIndex = 0;
  bool isInitialized = false;
  bool isPermissionDenied = false;

  // Flash & Tools
  FlashModeState flashState = FlashModeState.off;
  int timerDuration = 0; // 0 = off, 3, 10
  double zoomLevel = 1.0;
  bool isZoomVisible = false;
  Timer? _zoomTimer;
  Offset? focusPoint;
  bool showFocusRing = false;
  Timer? _focusTimer;

  // Recording & Capture
  bool isRecording = false;
  bool isHandsFreeLocked = false;
  bool isMultiSnapMode = false;
  double recordingProgress = 0.0; // 0.0 to 1.0
  int recordingSeconds = 0;
  Timer? _recordingTimer;
  XFile? capturedFile;
  bool isVideoSnap = false;

  // Filter Carousel
  int activeFilterIndex = 0;
  final List<SnapFilterItem> filters = const [
    SnapFilterItem(id: 'none', name: 'Normal', category: 'Basic', iconUrl: 'https://images.unsplash.com/photo-1451187580459-43490279c0fa?w=100&q=80'),
    SnapFilterItem(id: 'funny', name: 'Funny', category: 'Face', iconUrl: 'https://images.unsplash.com/photo-1601513470723-5132d52cf1d8?w=100&q=80'),
    SnapFilterItem(id: 'cute', name: 'Cute', category: 'Beauty', iconUrl: 'https://images.unsplash.com/photo-1577803645773-f96470509666?w=100&q=80'),
    SnapFilterItem(id: 'dog', name: 'Dog Ears', category: 'Animal', iconUrl: 'https://images.unsplash.com/photo-1543466835-00a7907e9de1?w=100&q=80'),
    SnapFilterItem(id: 'shades', name: 'Sunglasses', category: 'Face', iconUrl: 'https://images.unsplash.com/photo-1572637466528-ec60e7f77c5c?w=100&q=80'),
    SnapFilterItem(id: 'cyberpunk', name: 'Cyber Neon', category: 'Color', iconUrl: 'https://images.unsplash.com/photo-1563089145-599997674d42?w=100&q=80'),
    SnapFilterItem(id: 'golden', name: 'Warm Gold', category: 'Color', iconUrl: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=100&q=80'),
    SnapFilterItem(id: 'sepia', name: 'Retro Sepia', category: 'Color', iconUrl: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=100&q=80'),
  ];

  // Post-Capture Toolbar States
  List<DrawingPoint> drawingPoints = [];
  Color currentDrawColor = Colors.yellow;
  double currentStrokeWidth = 4.0;
  bool isDrawingMode = false;
  String captionText = '';
  int snapTimerSeconds = 10; // 1-10s or 0 (infinity)
  bool isAudioMuted = false;

  final ImagePicker _picker = ImagePicker();

  Future<void> initCamera() async {
    final status = await Permission.camera.request();
    if (status.isDenied || status.isPermanentlyDenied) {
      isPermissionDenied = true;
      notifyListeners();
      return;
    }
    await Permission.microphone.request();

    try {
      cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        // Find front camera first per specification
        int frontIndex = cameras.indexWhere((c) => c.lensDirection == CameraLensDirection.front);
        selectedCameraIndex = frontIndex != -1 ? frontIndex : 0;
        await _setCamera(selectedCameraIndex);
      }
    } catch (e) {
      debugPrint("Camera init error: $e");
    }
  }

  Future<void> _setCamera(int index) async {
    if (cameras.isEmpty) return;
    final controller = CameraController(
      cameras[index],
      ResolutionPreset.high,
      enableAudio: true,
      imageFormatGroup: Platform.isIOS ? ImageFormatGroup.bgra8888 : ImageFormatGroup.nv21,
    );
    cameraController = controller;
    try {
      await controller.initialize();
      isInitialized = true;
      isPermissionDenied = false;
      notifyListeners();
    } catch (e) {
      debugPrint("Camera controller initialize error: $e");
    }
  }

  Future<void> switchCamera() async {
    if (cameras.length < 2 || !isInitialized) return;
    selectedCameraIndex = (selectedCameraIndex + 1) % cameras.length;
    isInitialized = false;
    notifyListeners();
    await cameraController?.dispose();
    await _setCamera(selectedCameraIndex);
  }

  void cycleFlashMode() async {
    if (cameraController == null || !isInitialized) return;
    if (flashState == FlashModeState.off) {
      flashState = FlashModeState.on;
      await cameraController!.setFlashMode(FlashMode.always);
    } else if (flashState == FlashModeState.on) {
      flashState = FlashModeState.auto;
      await cameraController!.setFlashMode(FlashMode.auto);
    } else {
      flashState = FlashModeState.off;
      await cameraController!.setFlashMode(FlashMode.off);
    }
    notifyListeners();
  }

  void cycleTimer() {
    if (timerDuration == 0) {
      timerDuration = 3;
    } else if (timerDuration == 3) {
      timerDuration = 10;
    } else {
      timerDuration = 0;
    }
    notifyListeners();
  }

  void setZoom(double scale) async {
    if (cameraController == null || !isInitialized) return;
    zoomLevel = (zoomLevel * scale).clamp(1.0, 5.0);
    await cameraController!.setZoomLevel(zoomLevel);
    isZoomVisible = true;
    notifyListeners();

    _zoomTimer?.cancel();
    _zoomTimer = Timer(const Duration(seconds: 1), () {
      isZoomVisible = false;
      notifyListeners();
    });
  }

  void setFocus(TapUpDetails details, BoxConstraints constraints) async {
    if (cameraController == null || !isInitialized) return;
    final dx = details.localPosition.dx / constraints.maxWidth;
    final dy = details.localPosition.dy / constraints.maxHeight;
    focusPoint = details.localPosition;
    showFocusRing = true;
    notifyListeners();

    try {
      await cameraController!.setFocusPoint(Offset(dx, dy));
      await cameraController!.setExposurePoint(Offset(dx, dy));
    } catch (_) {}

    _focusTimer?.cancel();
    _focusTimer = Timer(const Duration(milliseconds: 600), () {
      showFocusRing = false;
      notifyListeners();
    });
  }

  void selectFilter(int index) {
    if (index >= 0 && index < filters.length) {
      activeFilterIndex = index;
      notifyListeners();
    }
  }

  void swipeFilter(int delta) {
    int nextIndex = (activeFilterIndex + delta).clamp(0, filters.length - 1);
    if (nextIndex != activeFilterIndex) {
      activeFilterIndex = nextIndex;
      notifyListeners();
    }
  }

  // ── PHOTO CAPTURE ──
  Future<XFile?> takePhoto() async {
    if (cameraController == null || !isInitialized || isRecording) return null;
    try {
      if (timerDuration > 0) {
        await Future.delayed(Duration(seconds: timerDuration));
      }
      final XFile photo = await cameraController!.takePicture();
      capturedFile = photo;
      isVideoSnap = false;
      notifyListeners();
      return photo;
    } catch (e) {
      debugPrint("Take photo error: $e");
      return null;
    }
  }

  // ── VIDEO RECORDING ──
  Future<void> startVideoRecording() async {
    if (cameraController == null || !isInitialized || isRecording) return;
    try {
      await cameraController!.startVideoRecording();
      isRecording = true;
      recordingSeconds = 0;
      recordingProgress = 0.0;
      notifyListeners();

      _recordingTimer = Timer.periodic(const Duration(milliseconds: 100), (t) {
        recordingSeconds = t.tick ~/ 10;
        recordingProgress = (t.tick / 600.0).clamp(0.0, 1.0); // max 60 seconds
        notifyListeners();
        if (t.tick >= 600) {
          stopVideoRecording();
        }
      });
    } catch (e) {
      debugPrint("Start video recording error: $e");
    }
  }

  Future<XFile?> stopVideoRecording() async {
    if (cameraController == null || !isRecording) return null;
    _recordingTimer?.cancel();
    try {
      final XFile video = await cameraController!.stopVideoRecording();
      isRecording = false;
      recordingProgress = 0.0;
      capturedFile = video;
      isVideoSnap = true;
      notifyListeners();
      return video;
    } catch (e) {
      debugPrint("Stop video recording error: $e");
      isRecording = false;
      notifyListeners();
      return null;
    }
  }

  Future<XFile?> pickGalleryImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        capturedFile = image;
        isVideoSnap = false;
        notifyListeners();
        return image;
      }
    } catch (e) {
      debugPrint("Gallery pick error: $e");
    }
    return null;
  }

  void resetCapturedSnap() {
    capturedFile = null;
    drawingPoints.clear();
    captionText = '';
    isDrawingMode = false;
    notifyListeners();
  }

  void addDrawingPoint(Offset point) {
    drawingPoints.add(
      DrawingPoint(
        offset: point,
        paint: Paint()
          ..color = currentDrawColor
          ..isAntiAlias = true
          ..strokeWidth = currentStrokeWidth
          ..strokeCap = StrokeCap.round,
      ),
    );
    notifyListeners();
  }

  void clearDrawing() {
    drawingPoints.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _zoomTimer?.cancel();
    _focusTimer?.cancel();
    _recordingTimer?.cancel();
    cameraController?.dispose();
    super.dispose();
  }
}
