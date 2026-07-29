import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../services/webrtc_service.dart';

class CallScreen extends StatefulWidget {
  final String peerName;
  final CallType callType;

  const CallScreen({
    super.key,
    required this.peerName,
    required this.callType,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  bool _isMuted = false;
  bool _isCameraOff = false;
  bool _isSpeakerOn = true;

  @override
  void initState() {
    super.initState();
    WebRtcService.instance.startCall('peer_user', widget.peerName, widget.callType);
  }

  @override
  void dispose() {
    WebRtcService.instance.endCall();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF040711),
      body: Stack(
        children: [
          // Background Remote Video or Ambient Glow
          if (widget.callType == CallType.video && !_isCameraOff)
            Positioned.fill(
              child: RTCVideoView(
                WebRtcService.instance.remoteRenderer,
                objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
              ),
            )
          else
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF0F172A), Color(0xFF040711)],
                  ),
                ),
              ),
            ),

          // Dark Overlay Gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.4),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.8),
                  ],
                ),
              ),
            ),
          ),

          // Floating Local Video Preview (PICTURE IN PICTURE)
          if (widget.callType == CallType.video && !_isCameraOff)
            Positioned(
              top: 50,
              right: 20,
              child: Container(
                width: 110,
                height: 160,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.5), width: 1.5),
                  boxShadow: const [
                    BoxShadow(color: Colors.black45, blurRadius: 12),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: RTCVideoView(
                    WebRtcService.instance.localRenderer,
                    mirror: true,
                    objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                  ),
                ),
              ),
            ),

          // Top Peer Info
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(colors: [Color(0xFF00E5FF), Color(0xFF8B5CF6)]),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFF00E5FF).withValues(alpha: 0.3), blurRadius: 20),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          widget.peerName.isNotEmpty ? widget.peerName[0].toUpperCase() : 'N',
                          style: GoogleFonts.sora(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      widget.peerName,
                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.callType == CallType.video ? 'HD Video Call · Connected' : 'Encrypted Voice Call · Connected',
                      style: GoogleFonts.outfit(color: const Color(0xFF00E5FF), fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Control Panel
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 36),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Mute Microphone
                    _callControlBtn(
                      icon: _isMuted ? LucideIcons.micOff : LucideIcons.mic,
                      isActive: _isMuted,
                      onTap: () {
                        setState(() => _isMuted = !_isMuted);
                        WebRtcService.instance.toggleMute();
                      },
                    ),

                    // Camera Toggle (Video Call only)
                    if (widget.callType == CallType.video)
                      _callControlBtn(
                        icon: _isCameraOff ? LucideIcons.videoOff : LucideIcons.video,
                        isActive: _isCameraOff,
                        onTap: () {
                          setState(() => _isCameraOff = !_isCameraOff);
                          WebRtcService.instance.toggleCamera();
                        },
                      ),

                    // Speakerphone Toggle
                    _callControlBtn(
                      icon: _isSpeakerOn ? LucideIcons.volume2 : LucideIcons.volumeX,
                      isActive: !_isSpeakerOn,
                      onTap: () {
                        setState(() => _isSpeakerOn = !_isSpeakerOn);
                      },
                    ),

                    // End Call (Red)
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFEF4444),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                              blurRadius: 18,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(LucideIcons.phoneOff, color: Colors.white, size: 26),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _callControlBtn({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.15),
          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        ),
        child: Icon(
          icon,
          color: isActive ? Colors.black : Colors.white,
          size: 22,
        ),
      ),
    );
  }
}
