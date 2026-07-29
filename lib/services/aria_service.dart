import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'aria_config.dart';

/// Singleton service that manages the Socket.IO connection to the ARIA backend.
/// Exposes event streams that the ARIA AI screen listens to.
class AriaService {
  AriaService._();
  static final AriaService instance = AriaService._();

  io.Socket? _socket;
  AriaConfig? _config;

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
    _config = config;
    connect();
  }

  // ─── Connect ────────────────────────────────────────────────────
  Future<void> connect() async {
    _config = await AriaConfig.load();
    final url = _config!.backendUrl;

    debugPrint('[AriaService] Connecting to $url');

    _socket?.dispose();
    _socket = io.io(url, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
      'reconnection': true,
      'reconnectionAttempts': 10,
      'reconnectionDelay': 2000,
    });

    _socket!.onConnect((_) {
      debugPrint('[AriaService] Connected');
      _connected = true;
      _onConnectedCtrl.add(true);
    });

    _socket!.onDisconnect((_) {
      debugPrint('[AriaService] Disconnected');
      _connected = false;
      _onConnectedCtrl.add(false);
    });

    _socket!.onConnectError((err) {
      debugPrint('[AriaService] Connection error: $err');
      _connected = false;
      _onConnectedCtrl.add(false);
    });

    // ── Backend events ──────────────────────────────────────────
    _socket!.on('transcript', (data) {
      final text = data is Map ? data['text']?.toString() ?? '' : data.toString();
      if (text.isNotEmpty) _onTranscriptCtrl.add(text);
    });

    _socket!.on('processing_start', (_) {
      _onProcessingStartCtrl.add(null);
    });

    _socket!.on('aria-stream-chunk', (data) {
      final chunk = data?.toString() ?? '';
      if (chunk.isNotEmpty) _onStreamChunkCtrl.add(chunk);
    });

    _socket!.on('ai_response', (data) {
      final text = data is Map ? data['text']?.toString() ?? '' : data.toString();
      _onAiResponseCtrl.add(text);
      _onProcessingEndCtrl.add(null);
    });

    _socket!.on('tts_start', (_) => _onTtsStartCtrl.add(null));
    _socket!.on('tts_end', (_) => _onTtsEndCtrl.add(null));

    _socket!.on('tts_audio', (data) {
      try {
        if (data is List) {
          final bytes = data.map((e) => (e as num).toInt()).toList();
          _onTtsAudioCtrl.add(bytes);
        }
      } catch (e) {
        debugPrint('[AriaService] Error parsing tts_audio payload: $e');
      }
    });

    _socket!.on('tts_fallback', (data) {
      // Could trigger platform TTS here if needed
      debugPrint('[AriaService] TTS fallback: ${data?['text']}');
    });

    _socket!.on('error', (data) {
      final msg = data is Map ? data['message']?.toString() ?? 'Unknown error' : data.toString();
      _onErrorCtrl.add(msg);
      _onProcessingEndCtrl.add(null);
    });

    _socket!.on('stt_ready', (_) {
      debugPrint('[AriaService] STT ready — Deepgram connected');
      _onSttReadyCtrl.add(null);
    });

    _socket!.on('history_cleared', (_) {
      debugPrint('[AriaService] History cleared');
    });

    _socket!.on('config_updated', (data) {
      debugPrint('[AriaService] Config updated: $data');
    });

    _socket!.connect();
  }

  // ─── Disconnect ─────────────────────────────────────────────────
  void disconnect() {
    _socket?.dispose();
    _socket = null;
    _connected = false;
    _onConnectedCtrl.add(false);
  }

  // ─── Send text message ──────────────────────────────────────────
  void sendTextMessage(String text, {Uint8List? imageBytes}) {
    if (_socket == null || !_connected) {
      _onErrorCtrl.add('Not connected to ARIA backend');
      return;
    }
    
    final payload = <String, dynamic>{'text': text};
    
    if (imageBytes != null) {
      final base64Image = base64Encode(imageBytes);
      payload['image'] = 'data:image/jpeg;base64,$base64Image';
    }
    
    _socket!.emit('text_input', payload);
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
