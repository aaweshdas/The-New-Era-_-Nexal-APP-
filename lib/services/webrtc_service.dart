import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'socket_service.dart';

enum CallType { audio, video }
enum CallState { idle, calling, incoming, connected, ended }

class WebRtcService {
  WebRtcService._();
  static final WebRtcService instance = WebRtcService._();

  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;

  RTCVideoRenderer localRenderer = RTCVideoRenderer();
  RTCVideoRenderer remoteRenderer = RTCVideoRenderer();

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

  /// Initialize renderers
  Future<void> initRenderers() async {
    await localRenderer.initialize();
    await remoteRenderer.initialize();
  }

  /// Start an outgoing audio or video call
  Future<void> startCall(String recipientId, String recipientName, CallType type) async {
    _callState = CallState.calling;
    _callType = type;
    _activePeerName = recipientName;
    _callStateStreamCtrl.add(_callState);

    await initRenderers();
    await _createLocalStream(type);

    // Send call invite signal via Socket.IO
    SocketService.instance.sendMessage(recipientId, '[CALL_OFFER_${type.name.toUpperCase()}]');
  }

  /// Accept an incoming call
  Future<void> acceptCall() async {
    _callState = CallState.connected;
    _callStateStreamCtrl.add(_callState);

    await initRenderers();
    await _createLocalStream(_callType);
  }

  /// End current active call
  Future<void> endCall() async {
    _callState = CallState.ended;
    _callStateStreamCtrl.add(_callState);

    _localStream?.getTracks().forEach((track) => track.stop());
    await _localStream?.dispose();
    await _peerConnection?.close();

    _localStream = null;
    _remoteStream = null;
    _peerConnection = null;

    _callState = CallState.idle;
    _callStateStreamCtrl.add(_callState);
  }

  Future<void> _createLocalStream(CallType type) async {
    final Map<String, dynamic> mediaConstraints = {
      'audio': true,
      'video': type == CallType.video ? {'facingMode': 'user'} : false,
    };

    try {
      _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
      localRenderer.srcObject = _localStream;
    } catch (e) {
      debugPrint('[WebRtcService] Local stream error: $e');
    }
  }

  void toggleMute() {
    if (_localStream != null) {
      _isMuted = !_isMuted;
      for (var track in _localStream!.getAudioTracks()) {
        track.enabled = !_isMuted;
      }
    }
  }

  void toggleCamera() {
    if (_localStream != null && _callType == CallType.video) {
      _isCameraOff = !_isCameraOff;
      for (var track in _localStream!.getVideoTracks()) {
        track.enabled = !_isCameraOff;
      }
    }
  }

  void dispose() {
    localRenderer.dispose();
    remoteRenderer.dispose();
    _callStateStreamCtrl.close();
  }
}
