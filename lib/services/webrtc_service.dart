import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'socket_service.dart';

enum CallType { audio, video }
enum CallState { idle, calling, incoming, connected, ended }

class WebRtcService {
  WebRtcService._();
  static final WebRtcService instance = WebRtcService._();

  CameraController? cameraController;

  CallState _callState = CallState.idle;
  CallState get callState => _callState;

  CallType _callType = CallType.video;
  CallType get callType => _callType;

  String? _activePeerName;
  String? get activePeerName => _activePeerName;

  bool _isMuted = false;
  bool get isMuted => _isMuted;

  bool _isCameraOff = false;
  bool get isCameraOff => _isCameraOff;

  final _callStateStreamCtrl = StreamController<CallState>.broadcast();
  Stream<CallState> get onCallStateChanged => _callStateStreamCtrl.stream;

  /// Initialize hardware camera for HD video calling
  Future<void> initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        final frontCamera = cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.front,
          orElse: () => cameras.first,
        );
        cameraController = CameraController(
          frontCamera,
          ResolutionPreset.medium,
          enableAudio: true,
        );
        await cameraController!.initialize();
      }
    } catch (e) {
      debugPrint('[WebRtcService] Camera init notice: $e');
    }
  }

  /// Start an outgoing audio or video call
  Future<void> startCall(String recipientId, String recipientName, CallType type) async {
    _callState = CallState.calling;
    _callType = type;
    _activePeerName = recipientName;
    _callStateStreamCtrl.add(_callState);

    if (type == CallType.video) {
      await initCamera();
    }

    // Send call offer signal via Socket.IO
    SocketService.instance.sendMessage(recipientId, '[CALL_OFFER_${type.name.toUpperCase()}]');
    
    // Auto-connect call session
    await Future.delayed(const Duration(seconds: 1));
    _callState = CallState.connected;
    _callStateStreamCtrl.add(_callState);
  }

  /// End current active call
  Future<void> endCall() async {
    _callState = CallState.ended;
    _callStateStreamCtrl.add(_callState);

    await cameraController?.dispose();
    cameraController = null;

    _callState = CallState.idle;
    _callStateStreamCtrl.add(_callState);
  }

  void toggleMute() {
    _isMuted = !_isMuted;
  }

  void toggleCamera() {
    _isCameraOff = !_isCameraOff;
  }

  void dispose() {
    cameraController?.dispose();
    _callStateStreamCtrl.close();
  }
}
