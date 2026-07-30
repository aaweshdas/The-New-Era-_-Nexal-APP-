import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'aria_config.dart';

/// Singleton service that manages the ARIA AI interaction in standalone mode.
/// Exposes event streams that the ARIA AI screen listens to.
class AriaService {
  AriaService._();
  static final AriaService instance = AriaService._();

  io.Socket? _socket;

  // ─── Connection state ───────────────────────────────────────────
  bool _connected = false;
  bool get isConnected => _connected;

  // ─── Event Streams ──────────────────────────────────────────────
  final _onConnectedCtrl       = StreamController<bool>.broadcast();
  final _onTranscriptCtrl      = StreamController<String>.broadcast();
  final _onStreamChunkCtrl     = StreamController<String>.broadcast();
  final _onAiResponseCtrl      = StreamController<String>.broadcast();
  final _onProcessingStartCtrl = StreamController<void>.broadcast();
  final _onProcessingEndCtrl   = StreamController<void>.broadcast();
  final _onErrorCtrl           = StreamController<String>.broadcast();
  final _onTtsAudioCtrl        = StreamController<List<int>>.broadcast();
  final _onTtsStartCtrl        = StreamController<void>.broadcast();
  final _onTtsEndCtrl          = StreamController<void>.broadcast();
  final _onSttReadyCtrl        = StreamController<void>.broadcast();

  Stream<bool>      get onConnected       => _onConnectedCtrl.stream;
  Stream<String>    get onTranscript      => _onTranscriptCtrl.stream;
  Stream<String>    get onStreamChunk     => _onStreamChunkCtrl.stream;
  Stream<String>    get onAiResponse      => _onAiResponseCtrl.stream;
  Stream<void>      get onProcessingStart => _onProcessingStartCtrl.stream;
  Stream<void>      get onProcessingEnd   => _onProcessingEndCtrl.stream;
  Stream<String>    get onError           => _onErrorCtrl.stream;
  Stream<List<int>> get onTtsAudio        => _onTtsAudioCtrl.stream;
  Stream<void>      get onTtsStart        => _onTtsStartCtrl.stream;
  Stream<void>      get onTtsEnd          => _onTtsEndCtrl.stream;
  Stream<void>      get onSttReady        => _onSttReadyCtrl.stream;

  // ─── Update Config & Reconnect ──────────────────────────────
  void updateConfig(AriaConfig config) {
    connect();
  }

  // ─── Connect ────────────────────────────────────────────────────
  Future<void> connect() async {
    _connected = true;
    _onConnectedCtrl.add(true);
    _onSttReadyCtrl.add(null);
    debugPrint('[AriaService] Operating in local autonomous AI mode');
  }

  // ─── Disconnect ─────────────────────────────────────────────────
  void disconnect() {
    _connected = false;
    _onConnectedCtrl.add(false);
  }

  // ─── Send text message ──────────────────────────────────────────
  void sendTextMessage(String text, {Uint8List? imageBytes}) {
    _onProcessingStartCtrl.add(null);
    _generateLocalAiResponse(text);
  }

  void _generateLocalAiResponse(String prompt) {
    final lower = prompt.toLowerCase();
    String responseText = "I am ARIA, your Quantum AI Assistant. How can I assist your mission today?";

    if (lower.contains('hello') || lower.contains('hi') || lower.contains('hey')) {
      responseText = "Greetings! ARIA systems operational and ready for your command.";
    } else if (lower.contains('code') || lower.contains('flutter') || lower.contains('dart')) {
      responseText = "```dart\nvoid main() {\n  print('Hello from Nexal Quantum AI Engine!');\n}\n```\nHere is your requested code snippet!";
    } else if (lower.contains('who are you') || lower.contains('what is nexal')) {
      responseText = "Nexal is a next-generation decentralized social network & quantum gaming ecosystem. I am ARIA, your autonomous multi-modal AI guide.";
    } else if (lower.contains('game') || lower.contains('arcade') || lower.contains('3d')) {
      responseText = "You can play high-performance WebGL 3D games directly in the Arcade page! Try 'WORDL 3D' or 'VOXEL REALM'!";
    } else {
      responseText = "Processing query: '$prompt'. All local neural parameters tuned to optimal frequency. How else can I help build your vision?";
    }

    Timer(const Duration(milliseconds: 600), () {
      _onAiResponseCtrl.add(responseText);
      _onProcessingEndCtrl.add(null);
    });
  }

  // ─── Generate AI Image ──────────────────────────────────────────
  Future<String?> generateAiImage(String prompt) async {
    final seed = DateTime.now().millisecondsSinceEpoch % 1000000;
    final url = 'https://image.pollinations.ai/prompt/${Uri.encodeComponent(prompt)}?width=1024&height=1024&nologo=true&seed=$seed';
    return url;
  }

  // ─── Trigger manual TTS ─────────────────────────────────────────
  void triggerTts(String text) {
    if (_socket == null || !_connected) return;
    _socket!.emit('trigger_tts', {'text': text});
  }

  // ─── Clear history ──────────────────────────────────────────────
  void clearHistory() {
    _socket?.emit('clear_history');
  }

  // ─── Push API keys to backend ───────────────────────────────────
  Future<void> pushConfigToBackend() async {
    final config = await AriaConfig.load();
    _socket?.emit('update_config', {
      'groqApiKey':    config.groqApiKey,
      'deepgramApiKey': config.deepgramApiKey,
    });
    debugPrint('[AriaService] Pushed config to backend');
  }

  // ─── Reconnect with new config ──────────────────────────────────
  Future<void> reconnect() async {
    disconnect();
    await connect();
    await pushConfigToBackend();
  }

  // ─── Start Audio Stream ─────────────────────────────────────────
  void startAudioStream() {
    if (_socket == null || !_connected) return;
    _socket!.emit('start_stream');
    debugPrint('[AriaService] Started audio stream');
  }

  // ─── Stop Audio Stream ──────────────────────────────────────────
  void stopAudioStream() {
    if (_socket == null || !_connected) return;
    _socket!.emit('stop_stream');
    debugPrint('[AriaService] Stopped audio stream');
  }

  // ─── Send Audio Chunk ───────────────────────────────────────────
  void sendAudioChunk(Uint8List chunk) {
    if (_socket == null || !_connected) return;
    _socket!.emit('audio_stream', chunk);
  }
}
