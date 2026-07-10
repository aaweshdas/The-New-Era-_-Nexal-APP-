import 'dart:math' as math;
import 'dart:io' show Platform;
import 'dart:async' as dart_async;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show WriteBuffer;
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../../theme/app_theme.dart';
import '../../theme/cached_styles.dart';
import '../../utils/filter_generator.dart';
import 'camera_preview_screen.dart';

class _Particle {
  double x;
  double y;
  double vx;
  double vy;
  double size;
  double opacity;
  double angle;
  double spin;
  Color color;

  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.opacity,
    this.spin = 0.0,
    this.color = Colors.white,
  }) : angle = 0.0;
}

class _FaceState {
  final bool isFaceDetected;
  final Rect? faceBoundingBox;
  final Offset? faceLeftEye;
  final Offset? faceRightEye;
  final Offset? faceNose;
  final Offset? faceMouth;
  final Size? inputImageSize;

  const _FaceState({
    required this.isFaceDetected,
    this.faceBoundingBox,
    this.faceLeftEye,
    this.faceRightEye,
    this.faceNose,
    this.faceMouth,
    this.inputImageSize,
  });

  factory _FaceState.empty() => const _FaceState(isFaceDetected: false);
}

const Map<String, List<Map<String, String>>> _categorizedFilters = {
  '😎 FACE': [
    {'name': 'None', 'id': 'photo-1451187580459-43490279c0fa', 'desc': 'No face overlay'},
    {'name': 'Sunglasses', 'id': 'photo-1572637466528-ec60e7f77c5c', 'desc': 'Classic retro shades'},
    {'name': 'Aviators', 'id': 'photo-1511499767150-a48a237f0083', 'desc': 'Cool aviator glasses'},
    {'name': 'Nerd Glasses', 'id': 'photo-1591076482161-42ce6da69f67', 'desc': 'Thick rimmed glasses'},
    {'name': 'Heart Glasses', 'id': 'photo-1577803645773-f96470509666', 'desc': 'Cute pink heart glasses'},
    {'name': 'Neon Glasses', 'id': 'photo-1563089145-599997674d42', 'desc': 'Glowing cyberpunk glasses'},
    {'name': 'Mask Overlay', 'id': 'photo-1509248961158-e54f6934749c', 'desc': 'Mysterious masquerade mask'},
    {'name': 'Face Paint', 'id': 'photo-1501196354995-cbb51c65aaea', 'desc': 'Vibrant artistic face paint'},
    {'name': 'Clown Face', 'id': 'photo-1601513470723-5132d52cf1d8', 'desc': 'Funny clown nose and makeup'},
    {'name': 'Superhero', 'id': 'photo-1608889174637-3c44f6326f1a', 'desc': 'Heroic eye mask overlay'},
    {'name': 'Animal Mask', 'id': 'photo-1546182990-dffeafbe841d', 'desc': 'Cute animal face mask'},
  ],
  '🐶 ANIMAL': [
    {'name': 'None', 'id': 'photo-1451187580459-43490279c0fa', 'desc': 'No animal overlay'},
    {'name': 'Dog Ears', 'id': 'photo-1543466835-00a7907e9de1', 'desc': 'Puppy dog ears and tongue'},
    {'name': 'Puppy Face', 'id': 'photo-1583511655857-d19b40a7a54e', 'desc': 'Cute puppy nose and ears'},
    {'name': 'Cat Face', 'id': 'photo-1514888286974-6c03e2ca1dba', 'desc': 'Cat ears and whiskers'},
    {'name': 'Tiger Face', 'id': 'photo-1564349683136-77e08dba1ef7', 'desc': 'Tiger snout and stripes'},
    {'name': 'Lion Face', 'id': 'photo-1546182990-dffeafbe841d', 'desc': 'Fluffy lion mane overlay'},
    {'name': 'Rabbit Ears', 'id': 'photo-1585110396000-c9ffd4e4b308', 'desc': 'Cute floppy bunny ears'},
    {'name': 'Panda Face', 'id': 'photo-1506744038136-46273834b3fb', 'desc': 'Panda eyes and ears'},
    {'name': 'Bear Face', 'id': 'photo-1530595467537-0b5996c41f2d', 'desc': 'Teddy bear ears overlay'},
    {'name': 'Fox Face', 'id': 'photo-1474511320723-9a56873867b5', 'desc': 'Fox ears and snout tint'},
    {'name': 'Deer Filter', 'id': 'photo-1507608869274-d3177c8bb4c7', 'desc': 'Cute deer antlers and nose'},
  ],
  '💄 BEAUTY': [
    {'name': 'None', 'id': 'photo-1451187580459-43490279c0fa', 'desc': 'No beauty effect'},
    {'name': 'Skin Smooth', 'id': 'photo-1522337360788-8b13dee7a37e', 'desc': 'Flawless skin smoothing'},
    {'name': 'Acne Clear', 'id': 'photo-1512290923902-8a9f81dc236c', 'desc': 'Clear blemish removal'},
    {'name': 'Brighten', 'id': 'photo-1596462502278-27bfdc403348', 'desc': 'Glow face brightening'},
    {'name': 'Teeth White', 'id': 'photo-1507003211169-0a1dd7228f2d', 'desc': 'Bright white smile shine'},
    {'name': 'Big Eyes', 'id': 'photo-1544005313-94ddf0286df2', 'desc': 'Anime style eye enlargement'},
    {'name': 'Slim Face', 'id': 'photo-1534528741775-53994a69daeb', 'desc': 'Sleek face slimming contour'},
    {'name': 'Jawline', 'id': 'photo-1506794778202-cad84cf45f1d', 'desc': 'Sharp jawline enhancement'},
    {'name': 'Nose Refine', 'id': 'photo-1492562080023-ab3db95bfbce', 'desc': 'Refined nose bridge line'},
    {'name': 'Plump Lips', 'id': 'photo-1517841905240-472988babdf9', 'desc': 'Subtle lip plumper boost'},
    {'name': 'Soft Glow', 'id': 'photo-1518887570146-0612132dd618', 'desc': 'Glamour beauty soft focus'},
  ],
  '💋 MAKEUP': [
    {'name': 'None', 'id': 'photo-1451187580459-43490279c0fa', 'desc': 'No makeup'},
    {'name': 'Lipstick', 'id': 'photo-1586495777744-4413f21062fa', 'desc': 'Vibrant lip tint'},
    {'name': 'Eyeliner', 'id': 'photo-1522337360788-8b13dee7a37e', 'desc': 'Sharp winged eyeliner'},
    {'name': 'Mascara', 'id': 'photo-1631214503002-99933cc5df0b', 'desc': 'Long lash definition'},
    {'name': 'Blush', 'id': 'photo-1631730359575-38e4755d772b', 'desc': 'Rosy cheek blush highlight'},
    {'name': 'Foundation', 'id': 'photo-1596462502278-27bfdc403348', 'desc': 'Even skin tone base'},
    {'name': 'Eyeshadow', 'id': 'photo-1512496015851-a90fb38ba796', 'desc': 'Sunset palette eyeshadow'},
    {'name': 'Contour', 'id': 'photo-1522337360788-8b13dee7a37e', 'desc': 'Defined cheekbone shading'},
    {'name': 'Full Glam', 'id': 'photo-1487412720507-e7ab37603c6f', 'desc': 'Red carpet glam makeup'},
    {'name': 'Natural', 'id': 'photo-1534528741775-53994a69daeb', 'desc': 'No-makeup makeup look'},
    {'name': 'Bridal', 'id': 'photo-1519741497674-611481863552', 'desc': 'Elegant glowing bridal style'},
  ],
  '🎨 ARTISTIC': [
    {'name': 'None', 'id': 'photo-1451187580459-43490279c0fa', 'desc': 'No art filter'},
    {'name': 'Cartoon', 'id': 'photo-1607604276583-eef5d076aa5f', 'desc': 'Toon shaded paint effect'},
    {'name': 'Anime', 'id': 'photo-1578632767115-351597cf2477', 'desc': 'Cell shaded anime styling'},
    {'name': 'Manga', 'id': 'photo-1607604276583-eef5d076aa5f', 'desc': 'Manga ink speedlines'},
    {'name': 'Comic Book', 'id': 'photo-1563089145-599997674d42', 'desc': 'Pop-art halftone dot filter'},
    {'name': 'Sketch', 'id': 'photo-1513364776144-60967b0f800f', 'desc': 'Monochrome outline pencil sketch'},
    {'name': 'Pencil Draw', 'id': 'photo-1506744038136-46273834b3fb', 'desc': 'Soft shaded graphite pencil'},
    {'name': 'Oil Paint', 'id': 'photo-1579783902614-a3fb3927b6a5', 'desc': 'Impressionist thick brush strokes'},
    {'name': 'Watercolor', 'id': 'photo-1579783928621-7a13d66a62d1', 'desc': 'Dreamy running watercolor wash'},
    {'name': 'Pop Art', 'id': 'photo-1569003339405-ea396a5a8a90', 'desc': 'Warhol style multi-color grid'},
    {'name': 'Pixel Art', 'id': 'photo-1550745165-9bc0b252726f', 'desc': '8-bit retro pixelated filter'},
  ],
  '🤖 AI': [
    {'name': 'None', 'id': 'photo-1451187580459-43490279c0fa', 'desc': 'No AI effect'},
    {'name': 'AI Avatar', 'id': 'photo-1618005182384-a83a8bd57fbe', 'desc': 'Futuristic cybernetic avatar'},
    {'name': 'AI Portrait', 'id': 'photo-1620712943543-bcc4688e7485', 'desc': 'Studio quality AI portrait'},
    {'name': 'AI Age Trans', 'id': 'photo-1554151228-14d9def656e4', 'desc': 'Generative age transformation'},
    {'name': 'AI Hair Cut', 'id': 'photo-1562322140-8baeececf3df', 'desc': 'AI virtual hair style changer'},
    {'name': 'AI Gender', 'id': 'photo-1534528741775-53994a69daeb', 'desc': 'Generative gender swap preview'},
    {'name': 'AI Face Swap', 'id': 'photo-1507003211169-0a1dd7228f2d', 'desc': 'AI face swap generator'},
    {'name': 'AI Celebrity', 'id': 'photo-1522075469751-3a6694fb2f61', 'desc': 'Find your celebrity look-alike'},
    {'name': 'AI Fantasy', 'id': 'photo-1535713875002-d1d0cf377fde', 'desc': 'Fantasy RPG elf/character'},
    {'name': 'AI Superhero', 'id': 'photo-1608889174637-3c44f6326f1a', 'desc': 'AI epic superhero renderer'},
    {'name': 'AI Baby Filter', 'id': 'photo-1519085360753-af0119f7cbe7', 'desc': 'AI baby face transformer'},
  ],
  '👴 AGE': [
    {'name': 'None', 'id': 'photo-1451187580459-43490279c0fa', 'desc': 'No age effect'},
    {'name': 'Baby Face', 'id': 'photo-1519085360753-af0119f7cbe7', 'desc': 'Cute toddler face overlay'},
    {'name': 'Child Face', 'id': 'photo-1551836022-d5d88e9218df', 'desc': 'Young child face filter'},
    {'name': 'Teenager', 'id': 'photo-1506794778202-cad84cf45f1d', 'desc': 'High school teenager filter'},
  ],
  '🌈 COLOR': [
    {'name': 'Normal', 'id': 'photo-1451187580459-43490279c0fa', 'desc': 'Standard camera color'},
    {'name': 'Vivid', 'id': 'photo-1507003211169-0a1dd7228f2d', 'desc': 'High saturation & contrast'},
    {'name': 'Cyber Mono', 'id': 'photo-1544005313-94ddf0286df2', 'desc': 'High contrast black & white'},
    {'name': 'Warm Gold', 'id': 'photo-1506794778202-cad84cf45f1d', 'desc': 'Sunset golden hour glow'},
    {'name': 'Cool Ice', 'id': 'photo-1492562080023-ab3db95bfbce', 'desc': 'Cyberpunk cool blue tint'},
    {'name': 'Retro Sepia', 'id': 'photo-1517841905240-472988babdf9', 'desc': 'Vintage sepia film tone'},
  ],
  '🎬 FRAMES': [
    {'name': 'None', 'id': 'photo-1451187580459-43490279c0fa', 'desc': 'Full screen view'},
    {'name': 'Cinematic', 'id': 'photo-1506744038136-46273834b3fb', 'desc': '2.39:1 widescreen scope'},
    {'name': 'Viewfinder', 'id': 'photo-1618005182384-a83a8bd57fbe', 'desc': 'DSLR recording layout'},
    {'name': 'Neon Glow', 'id': 'photo-1563089145-599997674d42', 'desc': 'Dynamic breathing neon border'},
  ],
};

class CameraView extends StatefulWidget {
  final VoidCallback? onClose;
  const CameraView({super.key, this.onClose});
  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> with WidgetsBindingObserver, TickerProviderStateMixin {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;
  int _selectedCameraIndex = 0;
  bool _isFlashOn = false;
  bool _isTakingPicture = false;
  int _timerDuration = 0;
  int _activeTimerCountdown = 0;
  double _zoomLevel = 1.0;
  bool _isGridOn = false;
  bool _isToolbarExpanded = false;
  final ImagePicker _picker = ImagePicker();
  late AnimationController _pulseCtrl;

  int _selectedMode = 3; // 3 = PHOTO
  final _modes = ['REEL', 'STORY', 'SPOTLIGHT', 'PHOTO'];
  final _modeColors = [
    AppTheme.pink500,
    AppTheme.cyan500,
    const Color(0xFFFBBF24),
    AppTheme.purple500,
  ];

  int _activeCategoryIndex = 0; // index of the active category
  
  // Active selection indexes for each category
  final Map<String, int> _selectedFilters = {
    '😎 FACE': 0,
    '🐶 ANIMAL': 0,
    '💄 BEAUTY': 0,
    '💋 MAKEUP': 0,
    '🎨 ARTISTIC': 0,
    '🤖 AI': 0,
    '👴 AGE': 0,
    '🌈 COLOR': 0,
    '🎬 FRAMES': 0,
  };

  final List<String> _categories = [
    '😎 FACE',
    '🐶 ANIMAL',
    '💄 BEAUTY',
    '💋 MAKEUP',
    '🎨 ARTISTIC',
    '🤖 AI',
    '👴 AGE',
    '🌈 COLOR',
    '🎬 FRAMES'
  ];

  // Particle Engine List
  final List<_Particle> _particles = [];

  // Face Detection State (ML Kit)
  FaceDetector? _faceDetector;
  bool _isDetecting = false;

  // Performance optimized ValueNotifiers to avoid frequent setStates
  final ValueNotifier<Offset> _swayNotifier = ValueNotifier<Offset>(Offset.zero);
  final ValueNotifier<_FaceState> _faceNotifier = ValueNotifier<_FaceState>(_FaceState.empty());
  final ValueNotifier<Offset> _manualOffsetNotifier = ValueNotifier<Offset>(Offset.zero);
  int _frameCount = 0;

  dart_async.StreamSubscription? _accelerometerSub;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _pulseCtrl.addListener(() {
      _updateParticles();
    });
    _initParticles();
    
    // Setup Native Face Detector with fast performance options
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableLandmarks: true,
        enableClassification: false,
        enableTracking: true,
        performanceMode: FaceDetectorMode.fast,
      ),
    );

    // Dynamic Tilt Sway Parallax Engine updating ValueNotifier directly
    _accelerometerSub = accelerometerEventStream().listen((AccelerometerEvent event) {
      if (mounted) {
        final double currentX = _swayNotifier.value.dx;
        final double currentY = _swayNotifier.value.dy;
        _swayNotifier.value = Offset(
          currentX * 0.85 + event.x * 3.5 * 0.15,
          currentY * 0.85 + event.y * 3.5 * 0.15,
        );
      }
    });

    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  Future<void> _initCamera() async {
    final status = await Permission.camera.request();
    if (status.isDenied) return;
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) _setCamera(_selectedCameraIndex);
    } catch (e) { debugPrint("Error fetching cameras: $e"); }
  }

  Future<void> _setCamera(int index) async {
    if (_cameras.isEmpty) return;
    final controller = CameraController(
      _cameras[index], 
      ResolutionPreset.high, 
      enableAudio: false,
      imageFormatGroup: Platform.isIOS ? ImageFormatGroup.bgra8888 : ImageFormatGroup.nv21,
    );
    _controller = controller;
    try {
      await controller.initialize();
      if (!mounted) return;
      setState(() => _isInitialized = true);
      await _controller!.setFlashMode(FlashMode.off);
      
      // Hook up dynamic camera stream detector
      _startFaceDetectionStream();
    } catch (e) { debugPrint("Camera initialize error: $e"); }
  }

  void _startFaceDetectionStream() {
    if (_controller == null || !_isInitialized) return;
    _controller!.startImageStream((CameraImage image) async {
      if (_isDetecting || !mounted) return;
      _frameCount++;
      if (_frameCount % 3 != 0) return;
      _isDetecting = true;
      try {
        final inputImage = _convertCameraImage(image);
        if (inputImage != null && _faceDetector != null) {
          final List<Face> faces = await _faceDetector!.processImage(inputImage);
          if (faces.isNotEmpty && mounted) {
            final face = faces.first;
            final landmarkLeftEye = face.landmarks[FaceLandmarkType.leftEye];
            final landmarkRightEye = face.landmarks[FaceLandmarkType.rightEye];
            final landmarkNose = face.landmarks[FaceLandmarkType.noseBase];
            final landmarkMouth = face.landmarks[FaceLandmarkType.bottomMouth];

            _faceNotifier.value = _FaceState(
              isFaceDetected: true,
              faceBoundingBox: face.boundingBox,
              faceLeftEye: landmarkLeftEye != null 
                  ? Offset(landmarkLeftEye.position.x.toDouble(), landmarkLeftEye.position.y.toDouble()) 
                  : null,
              faceRightEye: landmarkRightEye != null 
                  ? Offset(landmarkRightEye.position.x.toDouble(), landmarkRightEye.position.y.toDouble()) 
                  : null,
              faceNose: landmarkNose != null 
                  ? Offset(landmarkNose.position.x.toDouble(), landmarkNose.position.y.toDouble()) 
                  : null,
              faceMouth: landmarkMouth != null 
                  ? Offset(landmarkMouth.position.x.toDouble(), landmarkMouth.position.y.toDouble()) 
                  : null,
              inputImageSize: Size(image.width.toDouble(), image.height.toDouble()),
            );
          } else {
            if (_faceNotifier.value.isFaceDetected && mounted) {
              _faceNotifier.value = _FaceState.empty();
            }
          }
        }
      } catch (e) {
        debugPrint("Face detection frame error: $e");
      } finally {
        _isDetecting = false;
      }
    });
  }

  InputImage? _convertCameraImage(CameraImage image) {
    try {
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final inputImageFormat = Platform.isIOS ? InputImageFormat.bgra8888 : InputImageFormat.nv21;

      final sensorOrientation = _cameras[_selectedCameraIndex].sensorOrientation;
      InputImageRotation rotation = InputImageRotation.rotation0deg;
      if (sensorOrientation == 90) {
        rotation = InputImageRotation.rotation90deg;
      } else if (sensorOrientation == 180) {
        rotation = InputImageRotation.rotation180deg;
      } else if (sensorOrientation == 270) {
        rotation = InputImageRotation.rotation270deg;
      }

      final metadata = InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: inputImageFormat,
        bytesPerRow: image.planes[0].bytesPerRow,
      );

      return InputImage.fromBytes(bytes: bytes, metadata: metadata);
    } catch (e) {
      debugPrint("Error converting CameraImage: $e");
      return null;
    }
  }

  void _switchCamera() async {
    if (_cameras.isEmpty || !_isInitialized) return;
    _selectedCameraIndex = _selectedCameraIndex == 0 ? 1 : 0;
    if (_selectedCameraIndex >= _cameras.length) _selectedCameraIndex = 0;
    setState(() {
      _isInitialized = false;
    });
    _faceNotifier.value = _FaceState.empty();
    _manualOffsetNotifier.value = Offset.zero;
    try {
      await _controller?.stopImageStream();
    } catch (e) {
      debugPrint("Error stopping image stream: $e");
    }
    await _controller?.dispose();
    _setCamera(_selectedCameraIndex);
  }

  void _toggleFlash() async {
    if (_controller == null || !_isInitialized) return;
    setState(() => _isFlashOn = !_isFlashOn);
    await _controller!.setFlashMode(_isFlashOn ? FlashMode.always : FlashMode.off);
  }

  void _toggleTimer() {
    setState(() {
      if (_timerDuration == 0) {
        _timerDuration = 3;
      } else if (_timerDuration == 3) {
        _timerDuration = 10;
      } else {
        _timerDuration = 0;
      }
    });
  }

  void _toggleGrid() => setState(() => _isGridOn = !_isGridOn);

  Future<void> _handleZoom(double scale) async {
    if (_controller == null || !_isInitialized) return;
    final newZoom = (_zoomLevel * scale).clamp(1.0, 5.0);
    await _controller!.setZoomLevel(newZoom);
    setState(() => _zoomLevel = newZoom);
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CameraPreviewScreen(
              imageFile: image,
              selectedFilterIndex: _selectedFilters['🌈 COLOR'] ?? 0,
            ),
          ),
        );
      }
    } catch (e) { debugPrint("Gallery error: $e"); }
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized || _isTakingPicture) return;
    try {
      if (_timerDuration > 0) {
        for (int i = _timerDuration; i > 0; i--) {
          if (!mounted) return;
          setState(() => _activeTimerCountdown = i);
          await Future.delayed(const Duration(seconds: 1));
        }
      }
      if (!mounted) return;
      setState(() { _activeTimerCountdown = 0; _isTakingPicture = true; });
      final XFile picture = await _controller!.takePicture();
      setState(() => _isTakingPicture = false);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CameraPreviewScreen(
            imageFile: picture,
            selectedFilterIndex: _selectedFilters['🌈 COLOR'] ?? 0,
          ),
        ),
      );
    } catch (e) {
      debugPrint("Error taking picture: $e");
      setState(() { _isTakingPicture = false; _activeTimerCountdown = 0; });
    }
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg, style: GoogleFonts.outfit()),
        backgroundColor: const Color(0xFF1a1a2e),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));

  void _showEffects() {
    final effects = ['Cyber Glitch', 'Neon Bloom', 'Matrix Rain', 'Retrowave', 'Hologram', 'Film Grain'];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Color(0xFF0d0d1a),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Text('Effects', style: GoogleFonts.rye(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: effects.map((e) => GestureDetector(
                onTap: () { Navigator.pop(ctx); _snack('Applied: $e'); },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.purple500.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.purple500.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.wand2, color: AppTheme.purple500, size: 14),
                      const SizedBox(width: 6),
                      Text(e, style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
              )).toList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showMusic() {
    final tracks = ['Midnight Drive – NeoPulse', 'Starlight – Aria Storm', 'Cyber Dawn – ZenBeats', 'Dreamscape – Luna Nova'];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Color(0xFF0d0d1a),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Text('Add Music', style: GoogleFonts.rye(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            ...tracks.map((t) => GestureDetector(
              onTap: () { Navigator.pop(ctx); _snack('🎵 $t'); },
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.music, color: AppTheme.pink500, size: 18),
                    const SizedBox(width: 12),
                    Expanded(child: Text(t, style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13))),
                    Icon(LucideIcons.play, color: AppTheme.cyan500, size: 16),
                  ],
                ),
              ),
            )),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    try {
      if (_controller != null &&
          _controller!.value.isInitialized &&
          _controller!.value.isStreamingImages) {
        _controller!.stopImageStream();
      }
    } catch (_) {}
    _controller?.dispose();
    _pulseCtrl.dispose();
    _faceDetector?.close();
    _accelerometerSub?.cancel();
    _swayNotifier.dispose();
    _faceNotifier.dispose();
    _manualOffsetNotifier.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      try {
        if (_controller != null &&
            _controller!.value.isInitialized &&
            _controller!.value.isStreamingImages) {
          _controller!.stopImageStream();
        }
      } catch (_) {}
      _controller?.dispose();
      setState(() => _isInitialized = false);
    } else if (state == AppLifecycleState.resumed) {
      if (_controller != null) _setCamera(_selectedCameraIndex);
    }
  }

  // ── PARTICLE ENGINE BEHAVIORS ──

  void _initParticles() {
    _particles.clear();
    final r = math.Random();
    for (int i = 0; i < 30; i++) {
      _particles.add(_createRandomParticle(r, initial: true));
    }
  }

  _Particle _createRandomParticle(math.Random r, {bool initial = false}) {
    const screenWidth = 375.0;
    const screenHeight = 812.0;

    double x = r.nextDouble() * screenWidth;
    double y = initial ? r.nextDouble() * screenHeight : -20.0;

    double vx = (r.nextDouble() - 0.5) * 1.5;
    double vy = 1.0 + r.nextDouble() * 2.5;
    double size = 2.0 + r.nextDouble() * 4.0;
    double opacity = 0.3 + r.nextDouble() * 0.5;
    double spin = (r.nextDouble() - 0.5) * 0.05;
    Color color = r.nextBool() ? const Color(0xFF00E5FF) : const Color(0xFFEC4899);

    return _Particle(
      x: x,
      y: y,
      vx: vx,
      vy: vy,
      size: size,
      opacity: opacity,
      spin: spin,
      color: color,
    );
  }

  void _updateParticles() {
    if (_particles.isEmpty) return;
    final r = math.Random();
    const screenWidth = 375.0;
    const screenHeight = 812.0;

    for (int i = 0; i < _particles.length; i++) {
      final p = _particles[i];
      p.x += p.vx;
      p.y += p.vy;
      p.angle += p.spin;

      bool isOutOfBounds = p.y > screenHeight + 20 || p.x < -50 || p.x > screenWidth + 50;
      if (isOutOfBounds) {
        _particles[i] = _createRandomParticle(r, initial: false);
      }
    }
  }

  ColorFilter _getActiveColorFilter() {
    final int colorIndex = _selectedFilters['🌈 COLOR'] ?? 0;
    if (colorIndex == 5) {
      return const ColorFilter.matrix(<double>[
        0.393, 0.769, 0.189, 0, 0,
        0.349, 0.686, 0.168, 0, 0,
        0.272, 0.534, 0.131, 0, 0,
        0,     0,     0,     1, 0,
      ]);
    }
    if (colorIndex >= 0 && colorIndex < FilterGenerator.filters.length) {
      return FilterGenerator.filters[colorIndex];
    }
    return const ColorFilter.mode(Colors.transparent, BlendMode.srcOver);
  }

  // ── HUD OVERLAYS ──

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              _topActionBtn(LucideIcons.arrowLeft, () {
                if (widget.onClose != null) {
                  widget.onClose!();
                } else {
                  Navigator.pop(context);
                }
              }),
              const SizedBox(width: 10),
              _topActionBtn(LucideIcons.search, () => _snack('Search opened')),
            ],
          ),
          Row(
            children: [
              _topActionBtn(LucideIcons.bell, () => _snack('Notifications opened')),
              const SizedBox(width: 8),
              _topActionBtn(
                LucideIcons.userPlus,
                () => _snack('Add Friends opened'),
                badge: '4',
              ),
              const SizedBox(width: 8),
              _topActionBtn(LucideIcons.refreshCw, _switchCamera),
            ],
          ),
        ],
      ),
    );
  }

  Widget _topActionBtn(IconData icon, VoidCallback onTap, {String? badge}) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 0.8),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          if (badge != null)
            Positioned(
              top: -3,
              right: -3,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: AppTheme.pink500,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildToolbarItem(IconData icon, String label, VoidCallback onTap, {Color? color, String? badge}) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              label,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                shadows: [
                  Shadow(color: Colors.black.withValues(alpha: 0.8), offset: const Offset(1, 1), blurRadius: 4),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 0.8),
                  ),
                  child: Icon(icon, color: color ?? Colors.white, size: 18),
                ),
                if (badge != null)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: _modeColors[_selectedMode],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badge,
                        style: GoogleFonts.outfit(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerticalToolbar(Color mc) {
    final List<Widget> items = [];

    // 1. Flash
    items.add(_buildToolbarItem(
      _isFlashOn ? LucideIcons.zap : LucideIcons.zapOff,
      'Flash',
      _toggleFlash,
      color: _isFlashOn ? const Color(0xFFFBBF24) : null,
    ));

    // 2. Sounds
    items.add(_buildToolbarItem(
      LucideIcons.music,
      'Sounds',
      _showMusic,
      color: AppTheme.pink500,
    ));

    // 3. HD Mode
    items.add(_buildToolbarItem(
      LucideIcons.video,
      'HD Mode',
      () => _snack('HD Mode Enabled'),
      color: AppTheme.cyan500,
    ));

    if (_isToolbarExpanded) {
      // 4. Selfie settings
      items.add(_buildToolbarItem(
        LucideIcons.user,
        'Selfie settings',
        () => _snack('Selfie settings opened'),
        color: AppTheme.purple500,
      ));

      // Effects
      items.add(_buildToolbarItem(
        LucideIcons.wand2,
        'Effects',
        _showEffects,
        color: AppTheme.purple500,
      ));

      // 5. Multi Snap
      items.add(_buildToolbarItem(
        LucideIcons.copy,
        'Multi Snap',
        () => _snack('Multi Snap mode active'),
        color: Colors.white,
      ));

      // 6. Timer
      items.add(_buildToolbarItem(
        LucideIcons.timer,
        'Timer',
        _toggleTimer,
        badge: _timerDuration > 0 ? '${_timerDuration}s' : null,
        color: _timerDuration > 0 ? mc : null,
      ));

      // 7. Director Mode
      items.add(_buildToolbarItem(
        LucideIcons.videoOff,
        'Director Mode',
        () => _snack('Director Mode active'),
        color: const Color(0xFFFBBF24),
      ));

      // 8. Grid
      items.add(_buildToolbarItem(
        LucideIcons.grid,
        'Grid',
        _toggleGrid,
        color: _isGridOn ? mc : null,
      ));
    }

    // 9. Chevron Toggle
    items.add(_buildToolbarItem(
      _isToolbarExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
      _isToolbarExpanded ? 'Less' : 'More',
      () {
        setState(() {
          _isToolbarExpanded = !_isToolbarExpanded;
        });
      },
    ));

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: items,
    );
  }

  Widget _buildMemoriesButton() {
    return GestureDetector(
      onTap: _pickFromGallery,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: -3,
                top: -3,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(LucideIcons.image, color: Colors.white, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Memories',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              shadows: [
                Shadow(color: Colors.black.withValues(alpha: 0.8), offset: const Offset(1, 1), blurRadius: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShutterButton(Color mc) {
    return GestureDetector(
      onTap: _takePicture,
      child: AnimatedBuilder(
        animation: _pulseCtrl,
        builder: (ctx, child) {
          final pulse = 1.0 + _pulseCtrl.value * 0.05;
          return Transform.scale(
            scale: pulse,
            child: Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Container(
      height: 36,
      margin: const EdgeInsets.only(bottom: 6),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, i) {
          final sel = _activeCategoryIndex == i;
          return GestureDetector(
            onTap: () {
              setState(() {
                _activeCategoryIndex = i;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: sel ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: sel ? Colors.white70 : Colors.white12, width: 1),
              ),
              child: Center(
                child: Text(
                  _categories[i],
                  style: GoogleFonts.outfit(
                    color: sel ? Colors.white : Colors.white54,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterLensesRow(Color mc) {
    final String activeCategory = _categories[_activeCategoryIndex];
    final List<Map<String, String>> activeFiltersList = _categorizedFilters[activeCategory] ?? [];
    final int selectedIndex = _selectedFilters[activeCategory] ?? 0;

    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 12, right: 16),
        itemCount: activeFiltersList.length,
        itemBuilder: (context, index) {
          final filterItem = activeFiltersList[index];
          final sel = selectedIndex == index;
          final imageUrl = "https://images.unsplash.com/${filterItem['id']}?w=100&auto=format&fit=crop&q=80";
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedFilters[activeCategory] = index;
              });
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: sel ? 48 : 38,
                    height: sel ? 48 : 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: sel ? mc : Colors.white.withValues(alpha: 0.3),
                        width: sel ? 3 : 1.5,
                      ),
                      boxShadow: sel
                          ? [
                              BoxShadow(
                                color: mc.withValues(alpha: 0.4),
                                blurRadius: 8,
                                spreadRadius: 1,
                              )
                            ]
                          : [],
                    ),
                    child: ClipOval(
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey.shade900,
                          child: const Icon(LucideIcons.smile, color: Colors.white70, size: 16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    filterItem['name'] ?? '',
                    style: GoogleFonts.outfit(
                      color: sel ? Colors.white : Colors.white38,
                      fontSize: 8,
                      fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── BUILD MODE SELECTOR ──

  Widget _buildModeSelector(Color mc) {
    return SizedBox(
      height: 36,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_modes.length, (i) {
          final sel = _selectedMode == i;
          final c = _modeColors[i];
          return GestureDetector(
            onTap: () => setState(() => _selectedMode = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: EdgeInsets.symmetric(horizontal: sel ? 16 : 12, vertical: 6),
              decoration: BoxDecoration(
                color: sel ? c.withValues(alpha: 0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(18),
                border: sel ? Border.all(color: c.withValues(alpha: 0.4), width: 1) : null,
              ),
              child: Text(
                _modes[i],
                style: GoogleFonts.outfit(
                  color: sel ? c : Colors.white38,
                  fontWeight: sel ? FontWeight.bold : FontWeight.w500,
                  fontSize: sel ? 12 : 11,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mc = _modeColors[_selectedMode];
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            color: Colors.black,
          ),
          clipBehavior: Clip.antiAlias,
          child: GestureDetector(
            onScaleUpdate: (d) {
              // scale handles both pinch-zoom and single-finger pan
              _handleZoom(d.scale);
              if (!_faceNotifier.value.isFaceDetected && d.pointerCount == 1) {
                _manualOffsetNotifier.value += d.focalPointDelta;
              }
            },
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Camera feed (RepaintBoundary isolates camera stream rendering)
                if (_isInitialized && _controller != null && _controller!.value.previewSize != null)
                  RepaintBoundary(
                    child: SizedBox.expand(
                      child: FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: _controller!.value.previewSize!.height,
                          height: _controller!.value.previewSize!.width,
                          child: ColorFiltered(
                            colorFilter: _getActiveColorFilter(),
                            child: CameraPreview(_controller!),
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  const Center(child: CircularProgressIndicator(color: AppTheme.cyan500)),

                // Grid overlay
                if (_isGridOn)
                  Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: _GridPainter()))),

                // Unified Camera Filter Visual Overlay (Face, Animal, Beauty, Makeup, Artistic, AI, Age, Frames)
                // RepaintBoundary + AnimatedBuilder prevents high frequency paint invalidation to parent elements
                Positioned.fill(
                  child: IgnorePointer(
                    child: RepaintBoundary(
                      child: AnimatedBuilder(
                        animation: Listenable.merge([
                          _pulseCtrl,
                          _swayNotifier,
                          _faceNotifier,
                          _manualOffsetNotifier,
                        ]),
                        builder: (context, _) {
                          final faceState = _faceNotifier.value;
                          final sway = _swayNotifier.value;
                          final manualOffset = _manualOffsetNotifier.value;
                          return CustomPaint(
                            painter: _FilterOverlayPainter(
                              selectedFilters: _selectedFilters,
                              pulseValue: _pulseCtrl.value,
                              particles: _particles,
                              isFaceDetected: faceState.isFaceDetected,
                              faceBoundingBox: faceState.faceBoundingBox,
                              faceLeftEye: faceState.faceLeftEye,
                              faceRightEye: faceState.faceRightEye,
                              faceNose: faceState.faceNose,
                              faceMouth: faceState.faceMouth,
                              inputImageSize: faceState.inputImageSize,
                              swayX: sway.dx,
                              swayY: sway.dy,
                              manualOffset: manualOffset,
                              isFrontCamera: _selectedCameraIndex == 1,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),

                // Timer countdown
                if (_activeTimerCountdown > 0)
                  Center(
                    child: Text(
                      '$_activeTimerCountdown',
                      style: CachedStyles.outfitBoldSize120White.copyWith(
                        shadows: [Shadow(color: mc.withValues(alpha: 0.6), blurRadius: 30)],
                      ),
                    ),
                  ),

                // Top gradient overlay
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 120,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black.withValues(alpha: 0.6), Colors.transparent],
                      ),
                    ),
                  ),
                ),

                // Bottom gradient overlay
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 200,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Colors.black.withValues(alpha: 0.75), Colors.transparent],
                      ),
                    ),
                  ),
                ),

                // FLOATING WIDGETS
                
                // 1. Top bar controls (RepaintBoundary caches layout display list)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: RepaintBoundary(
                    child: _buildTopBar().animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, end: 0),
                  ),
                ),

                // 2. Right Actions Panel (Vertical toolbar - RepaintBoundary caches controls)
                Positioned(
                  top: 70,
                  right: 16,
                  child: RepaintBoundary(
                    child: _buildVerticalToolbar(mc).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideX(begin: 0.3, end: 0),
                  ),
                ),

                // 3. Zoom indicator
                if (_zoomLevel > 1.0)
                  Positioned(
                    bottom: 220,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(12)),
                        child: Text(
                          '${_zoomLevel.toStringAsFixed(1)}x',
                          style: CachedStyles.outfitBoldSize12White.copyWith(color: mc),
                        ),
                      ),
                    ),
                  ),

                // 4. Shutter and lens row panel (RepaintBoundary prevents full repaint on overlay update)
                Positioned(
                  bottom: 12,
                  left: 0,
                  right: 0,
                  child: RepaintBoundary(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildModeSelector(mc),
                        const SizedBox(height: 12),
                        _buildCategorySelector(),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(child: Center(child: _buildMemoriesButton())),
                            _buildShutterButton(mc),
                            Expanded(child: _buildFilterLensesRow(mc)),
                          ],
                        ),
                      ],
                    ).animate().fadeIn(delay: 100.ms, duration: 400.ms).slideY(begin: 0.15, end: 0),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── GRID PAINTER ──
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.15)..strokeWidth = 0.5;
    for (int i = 1; i < 3; i++) {
      final dx = size.width / 3 * i;
      final dy = size.height / 3 * i;
      canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), paint);
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── UNIFIED FILTER & EFFECT PAINTER ──
class _FilterOverlayPainter extends CustomPainter {
  final Map<String, int> selectedFilters;
  final double pulseValue;
  final List<_Particle> particles;
  
  final bool isFaceDetected;
  final Rect? faceBoundingBox;
  final Offset? faceLeftEye;
  final Offset? faceRightEye;
  final Offset? faceNose;
  final Offset? faceMouth;
  final Size? inputImageSize;
  
  final double swayX;
  final double swayY;
  final Offset manualOffset;
  final bool isFrontCamera;

  _FilterOverlayPainter({
    required this.selectedFilters,
    required this.pulseValue,
    required this.particles,
    required this.isFaceDetected,
    this.faceBoundingBox,
    this.faceLeftEye,
    this.faceRightEye,
    this.faceNose,
    this.faceMouth,
    this.inputImageSize,
    required this.swayX,
    required this.swayY,
    required this.manualOffset,
    required this.isFrontCamera,
  });

  @override
  void paint(Canvas canvas, Size size) {
    double cx = size.width / 2;
    double cy = size.height * 0.43; // Standard coordinates mapping center of selfie frame
    double faceScale = 1.0;
    double angle = 0.0;

    Offset? mappedLeftEye;
    Offset? mappedRightEye;
    Offset? mappedMouth;

    if (isFaceDetected && faceBoundingBox != null && inputImageSize != null) {
      final double imgW = inputImageSize!.width;
      final double imgH = inputImageSize!.height;

      // Coordinate scaling factoring for swapped width/height in portrait
      final double scaleX = size.width / imgH;
      final double scaleY = size.height / imgW;

      Offset mapOffset(Offset inputOffset) {
        double mx = inputOffset.dx * scaleX;
        double my = inputOffset.dy * scaleY;
        if (isFrontCamera) {
          mx = size.width - mx;
        }
        return Offset(mx, my);
      }

      Offset? mappedNose = faceNose != null ? mapOffset(faceNose!) : null;
      mappedLeftEye = faceLeftEye != null ? mapOffset(faceLeftEye!) : null;
      mappedRightEye = faceRightEye != null ? mapOffset(faceRightEye!) : null;
      mappedMouth = faceMouth != null ? mapOffset(faceMouth!) : null;

      // Extract tilt angle of eye line relative to horizontal axis
      if (mappedLeftEye != null && mappedRightEye != null) {
        final double dy = mappedRightEye.dy - mappedLeftEye.dy;
        final double dx = mappedRightEye.dx - mappedLeftEye.dx;
        angle = math.atan2(dy, dx);
        if (isFrontCamera) {
          angle = -angle; // Adjust reflected translation for front camera
        }
      }

      final double mappedFaceW = faceBoundingBox!.width * scaleX;
      faceScale = mappedFaceW / 140.0;

      if (mappedNose != null) {
        cx = mappedNose.dx;
        cy = mappedNose.dy;
      } else {
        final Offset boxCenter = mapOffset(faceBoundingBox!.center);
        cx = boxCenter.dx;
        cy = boxCenter.dy;
      }
    } else {
      // Fallback sway + manual drag offset controls
      cx = cx + manualOffset.dx - swayX;
      cy = cy + manualOffset.dy + swayY;
    }

    _paintBeauty(canvas, size, cx, cy, faceScale, mappedLeftEye, mappedRightEye, mappedMouth);
    _paintMakeup(canvas, size, cx, cy, faceScale, mappedLeftEye, mappedRightEye, mappedMouth);
    _paintFace(canvas, size, cx, cy, faceScale, angle, mappedLeftEye, mappedRightEye);
    _paintAnimal(canvas, size, cx, cy, faceScale, mappedLeftEye, mappedRightEye, mappedMouth);
    _paintAge(canvas, size, cx, cy, faceScale, mappedMouth);
    _paintArtistic(canvas, size, cx, cy);
    _paintAI(canvas, size, cx, cy);
    _paintFrames(canvas, size);
  }

  void _drawSparkle(Canvas canvas, double cx, double cy, double size) {
    final paint = Paint()..color = Colors.white..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(cx, cy - size)
      ..lineTo(cx + size * 0.3, cy - size * 0.3)
      ..lineTo(cx + size, cy)
      ..lineTo(cx + size * 0.3, cy + size * 0.3)
      ..lineTo(cx, cy + size)
      ..lineTo(cx - size * 0.3, cy + size * 0.3)
      ..lineTo(cx - size, cy)
      ..lineTo(cx - size * 0.3, cy - size * 0.3)
      ..close();
    canvas.drawPath(path, paint);
  }

  void _paintBeauty(Canvas canvas, Size size, double cx, double cy, double faceScale, Offset? leftEye, Offset? rightEye, Offset? mouth) {
    final index = selectedFilters['💄 BEAUTY'] ?? 0;
    if (index == 0) return;

    if (index == 1) { // Skin Smooth
      final paint = Paint()..color = Colors.white.withValues(alpha: 0.08)..style = PaintingStyle.fill;
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    } else if (index == 2) { // Acne Clear
      final paint = Paint()..color = Colors.white.withValues(alpha: 0.04)..style = PaintingStyle.fill;
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    } else if (index == 3) { // Brighten
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [Colors.white.withValues(alpha: 0.12), Colors.transparent],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: size.width * 0.65 * faceScale));
      canvas.drawCircle(Offset(cx, cy), size.width * 0.65 * faceScale, paint);
    } else if (index == 4) { // Teeth White
      final Offset mouthCenter = mouth ?? Offset(cx, cy + 62 * faceScale);
      _drawSparkle(canvas, mouthCenter.dx, mouthCenter.dy, 5 * faceScale);
      _drawSparkle(canvas, mouthCenter.dx + 8 * faceScale, mouthCenter.dy + 1, 3 * faceScale);
    } else if (index == 5) { // Big Eyes
      final Offset eyeL = leftEye ?? Offset(cx - 30 * faceScale, cy - 22 * faceScale);
      final Offset eyeR = rightEye ?? Offset(cx + 30 * faceScale, cy - 22 * faceScale);
      final paintRing = Paint()
        ..color = Colors.white.withValues(alpha: 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5 * faceScale;
      canvas.drawCircle(eyeL, 12 * faceScale, paintRing);
      canvas.drawCircle(eyeR, 12 * faceScale, paintRing);
    } else if (index == 6 || index == 7) { // Slim Face & Jawline
      final paintJaw = Paint()
        ..color = Colors.white.withValues(alpha: 0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8 * faceScale;
      final path = Path();
      path.moveTo(cx - 75 * faceScale, cy);
      path.quadraticBezierTo(cx - 55 * faceScale, cy + 85 * faceScale, cx, cy + 105 * faceScale);
      path.quadraticBezierTo(cx + 55 * faceScale, cy + 85 * faceScale, cx + 75 * faceScale, cy);
      canvas.drawPath(path, paintJaw);
    } else if (index == 8) { // Nose Refine
      final paintNose = Paint()
        ..color = Colors.white.withValues(alpha: 0.25)
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 1.2 * faceScale;
      canvas.drawLine(Offset(cx, cy - 10 * faceScale), Offset(cx, cy + 22 * faceScale), paintNose);
    } else if (index == 9 || index == 10) { // Lip Plump / Soft Glow
      final Offset mouthCenter = mouth ?? Offset(cx, cy + 62 * faceScale);
      final paintLips = Paint()
        ..shader = RadialGradient(
          colors: [Colors.pink.withValues(alpha: 0.12), Colors.transparent],
        ).createShader(Rect.fromCircle(center: mouthCenter, radius: 24 * faceScale));
      canvas.drawCircle(mouthCenter, 24 * faceScale, paintLips);
    }
  }

  void _paintMakeup(Canvas canvas, Size size, double cx, double cy, double faceScale, Offset? leftEye, Offset? rightEye, Offset? mouth) {
    final index = selectedFilters['💋 MAKEUP'] ?? 0;
    if (index == 0) return;

    final Offset mouthCenter = mouth ?? Offset(cx, cy + 62 * faceScale);

    if (index == 1) { // Lipstick
      final paintLip = Paint()..color = const Color(0xFFE91E63).withValues(alpha: 0.25)..style = PaintingStyle.fill;
      final path = Path();
      path.moveTo(mouthCenter.dx - 18 * faceScale, mouthCenter.dy);
      path.quadraticBezierTo(mouthCenter.dx - 8 * faceScale, mouthCenter.dy - 6 * faceScale, mouthCenter.dx, mouthCenter.dy - 4 * faceScale);
      path.quadraticBezierTo(mouthCenter.dx + 8 * faceScale, mouthCenter.dy - 6 * faceScale, mouthCenter.dx + 18 * faceScale, mouthCenter.dy);
      path.quadraticBezierTo(mouthCenter.dx, mouthCenter.dy + 8 * faceScale, mouthCenter.dx - 18 * faceScale, mouthCenter.dy);
      canvas.drawPath(path, paintLip);
    } else if (index == 2 || index == 3) { // Eyeliner & Mascara
      final Offset eyeL = leftEye ?? Offset(cx - 30 * faceScale, cy - 22 * faceScale);
      final Offset eyeR = rightEye ?? Offset(cx + 30 * faceScale, cy - 22 * faceScale);
      final paintLash = Paint()..color = Colors.black87..style = PaintingStyle.stroke..strokeWidth = 1.8 * faceScale;
      final pathL = Path()
        ..moveTo(eyeL.dx - 12 * faceScale, eyeL.dy)
        ..quadraticBezierTo(eyeL.dx, eyeL.dy - 5 * faceScale, eyeL.dx + 12 * faceScale, eyeL.dy)
        ..moveTo(eyeL.dx - 12 * faceScale, eyeL.dy)
        ..quadraticBezierTo(eyeL.dx - 17 * faceScale, eyeL.dy - 2 * faceScale, eyeL.dx - 20 * faceScale, eyeL.dy);
      canvas.drawPath(pathL, paintLash);
      
      final pathR = Path()
        ..moveTo(eyeR.dx - 12 * faceScale, eyeR.dy)
        ..quadraticBezierTo(eyeR.dx, eyeR.dy - 5 * faceScale, eyeR.dx + 12 * faceScale, eyeR.dy)
        ..moveTo(eyeR.dx + 12 * faceScale, eyeR.dy)
        ..quadraticBezierTo(eyeR.dx + 17 * faceScale, eyeR.dy - 2 * faceScale, eyeR.dx + 20 * faceScale, eyeR.dy);
      canvas.drawPath(pathR, paintLash);
    } else if (index == 4) { // Blush
      final paintBlushL = Paint()
        ..shader = RadialGradient(
          colors: [Colors.pinkAccent.withValues(alpha: 0.15), Colors.transparent],
        ).createShader(Rect.fromCircle(center: Offset(cx - 50 * faceScale, cy + 12 * faceScale), radius: 25 * faceScale));
      canvas.drawCircle(Offset(cx - 50 * faceScale, cy + 12 * faceScale), 25 * faceScale, paintBlushL);
      final paintBlushR = Paint()
        ..shader = RadialGradient(
          colors: [Colors.pinkAccent.withValues(alpha: 0.15), Colors.transparent],
        ).createShader(Rect.fromCircle(center: Offset(cx + 50 * faceScale, cy + 12 * faceScale), radius: 25 * faceScale));
      canvas.drawCircle(Offset(cx + 50 * faceScale, cy + 12 * faceScale), 25 * faceScale, paintBlushR);
    } else if (index == 5) { // Foundation
      final paintFound = Paint()..color = const Color(0xFFF1C40F).withValues(alpha: 0.04)..style = PaintingStyle.fill;
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paintFound);
    } else if (index == 6) { // Eyeshadow
      final Offset eyeL = leftEye ?? Offset(cx - 30 * faceScale, cy - 22 * faceScale);
      final Offset eyeR = rightEye ?? Offset(cx + 30 * faceScale, cy - 22 * faceScale);
      final paintShadow = Paint()
        ..shader = RadialGradient(
          colors: [Colors.purpleAccent.withValues(alpha: 0.2), Colors.transparent],
        ).createShader(Rect.fromCircle(center: eyeL - Offset(0, 6 * faceScale), radius: 12 * faceScale));
      canvas.drawCircle(eyeL - Offset(0, 6 * faceScale), 12 * faceScale, paintShadow);
      canvas.drawCircle(eyeR - Offset(0, 6 * faceScale), 12 * faceScale, paintShadow);
    } else if (index == 7) { // Contour
      final paintContour = Paint()
        ..shader = RadialGradient(
          colors: [const Color(0xFF795548).withValues(alpha: 0.12), Colors.transparent],
        ).createShader(Rect.fromCircle(center: Offset(cx - 65 * faceScale, cy + 20 * faceScale), radius: 30 * faceScale));
      canvas.drawCircle(Offset(cx - 65 * faceScale, cy + 20 * faceScale), 30 * faceScale, paintContour);
      canvas.drawCircle(Offset(cx + 65 * faceScale, cy + 20 * faceScale), 30 * faceScale, paintContour);
    } else if (index >= 8) { // Full Glam / Natural / Bridal
      final paintLip = Paint()..color = const Color(0xFFD81B60).withValues(alpha: 0.3)..style = PaintingStyle.fill;
      final path = Path();
      path.moveTo(mouthCenter.dx - 18 * faceScale, mouthCenter.dy);
      path.quadraticBezierTo(mouthCenter.dx - 8 * faceScale, mouthCenter.dy - 6 * faceScale, mouthCenter.dx, mouthCenter.dy - 4 * faceScale);
      path.quadraticBezierTo(mouthCenter.dx + 8 * faceScale, mouthCenter.dy - 6 * faceScale, mouthCenter.dx + 18 * faceScale, mouthCenter.dy);
      path.quadraticBezierTo(mouthCenter.dx, mouthCenter.dy + 8 * faceScale, mouthCenter.dx - 18 * faceScale, mouthCenter.dy);
      canvas.drawPath(path, paintLip);

      final paintBlushL = Paint()..shader = RadialGradient(colors: [Colors.pink.withValues(alpha: 0.1), Colors.transparent]).createShader(Rect.fromCircle(center: Offset(cx - 50 * faceScale, cy + 12 * faceScale), radius: 25 * faceScale));
      canvas.drawCircle(Offset(cx - 50 * faceScale, cy + 12 * faceScale), 25 * faceScale, paintBlushL);
      canvas.drawCircle(Offset(cx + 50 * faceScale, cy + 12 * faceScale), 25 * faceScale, paintBlushL);
    }
  }

  void _paintFace(Canvas canvas, Size size, double cx, double cy, double faceScale, double angle, Offset? leftEye, Offset? rightEye) {
    final index = selectedFilters['😎 FACE'] ?? 0;
    if (index == 0) return;

    final Offset eyeCenter = (leftEye != null && rightEye != null)
        ? Offset((leftEye.dx + rightEye.dx) / 2, (leftEye.dy + rightEye.dy) / 2)
        : Offset(cx, cy - 22 * faceScale);

    if (index >= 1 && index <= 5) {
      canvas.save();
      canvas.translate(eyeCenter.dx, eyeCenter.dy);
      canvas.rotate(angle);
      canvas.scale(faceScale);

      if (index == 1) { // Sunglasses
        final paintLens = Paint()..color = Colors.black.withValues(alpha: 0.88)..style = PaintingStyle.fill;
        final paintFrame = Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 1.8;
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-44, -12, 34, 24), const Radius.circular(6)), paintLens);
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-44, -12, 34, 24), const Radius.circular(6)), paintFrame);
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(10, -12, 34, 24), const Radius.circular(6)), paintLens);
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(10, -12, 34, 24), const Radius.circular(6)), paintFrame);
        canvas.drawLine(const Offset(-10, -3), const Offset(10, -3), paintLens..strokeWidth = 3.5);
      } else if (index == 2) { // Aviators
        final paintLens = Paint()..color = const Color(0xFF3E2723).withValues(alpha: 0.72)..style = PaintingStyle.fill;
        final paintGold = Paint()..color = const Color(0xFFFFD700)..style = PaintingStyle.stroke..strokeWidth = 1.5;
        final pathL = Path()
          ..moveTo(-44, -12)
          ..lineTo(-10, -12)
          ..quadraticBezierTo(-15, 12, -28, 12)
          ..quadraticBezierTo(-44, 6, -44, -12);
        canvas.drawPath(pathL, paintLens);
        canvas.drawPath(pathL, paintGold);
        final pathR = Path()
          ..moveTo(10, -12)
          ..lineTo(44, -12)
          ..quadraticBezierTo(44, 6, 28, 12)
          ..quadraticBezierTo(15, 12, 10, -12);
        canvas.drawPath(pathR, paintLens);
        canvas.drawPath(pathR, paintGold);
        canvas.drawLine(const Offset(-10, -9), const Offset(10, -9), paintGold..strokeWidth = 1.2);
      } else if (index == 3) { // Nerd Glasses
        final paintFrame = Paint()..color = Colors.black87..style = PaintingStyle.stroke..strokeWidth = 2.8;
        canvas.drawRect(const Rect.fromLTWH(-44, -12, 30, 24), paintFrame);
        canvas.drawRect(const Rect.fromLTWH(14, -12, 30, 24), paintFrame);
        canvas.drawLine(const Offset(-14, 0), const Offset(14, 0), paintFrame..strokeWidth = 2.8);
      } else if (index == 4) { // Heart Glasses
        final paintPink = Paint()..color = Colors.pink.withValues(alpha: 0.45)..style = PaintingStyle.fill;
        final paintBorder = Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 2;
        void drawHeart(double offset) {
          final h = Path();
          h.moveTo(offset, -2);
          h.cubicTo(offset - 8, -12, offset - 18, -2, offset, 12);
          h.cubicTo(offset + 18, -2, offset + 8, -12, offset, -2);
          canvas.drawPath(h, paintPink);
          canvas.drawPath(h, paintBorder);
        }
        drawHeart(-24);
        drawHeart(24);
        canvas.drawLine(const Offset(-10, 1), const Offset(10, 1), paintBorder..strokeWidth = 1.8);
      } else if (index == 5) { // Neon Glasses
        final paintNeon = Paint()..color = const Color(0xFF00E5FF).withValues(alpha: 0.35)..style = PaintingStyle.fill;
        final paintLine = Paint()
          ..color = const Color(0xFFEC4899)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-55, -12, 110, 14), const Radius.circular(4)), paintNeon);
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-55, -12, 110, 14), const Radius.circular(4)), paintLine);
      }

      canvas.restore();
    } else {
      if (index == 6) { // Mask Overlay
        final paintMask = Paint()..color = Colors.black.withValues(alpha: 0.85)..style = PaintingStyle.fill;
        final path = Path()
          ..moveTo(cx - 70 * faceScale, cy - 35 * faceScale)
          ..quadraticBezierTo(cx - 35 * faceScale, cy - 40 * faceScale, cx, cy - 18 * faceScale)
          ..quadraticBezierTo(cx + 35 * faceScale, cy - 40 * faceScale, cx + 70 * faceScale, cy - 35 * faceScale)
          ..quadraticBezierTo(cx + 60 * faceScale, cy + 2 * faceScale, cx + 40 * faceScale, cy + 7 * faceScale)
          ..quadraticBezierTo(cx, cy - 2 * faceScale, cx - 40 * faceScale, cy + 7 * faceScale)
          ..quadraticBezierTo(cx - 60 * faceScale, cy + 2 * faceScale, cx - 70 * faceScale, cy - 35 * faceScale);
        canvas.drawPath(path, paintMask);
        
        final paintEyeCut = Paint()..blendMode = BlendMode.clear;
        canvas.drawCircle(Offset(cx - 28 * faceScale, cy - 18 * faceScale), 10 * faceScale, paintEyeCut);
        canvas.drawCircle(Offset(cx + 28 * faceScale, cy - 18 * faceScale), 10 * faceScale, paintEyeCut);
      } else if (index == 7) { // Face Paint
        final paintPaint = Paint()..strokeWidth = 3.5 * faceScale..strokeCap = StrokeCap.round;
        canvas.drawLine(Offset(cx - 55 * faceScale, cy + 8 * faceScale), Offset(cx - 35 * faceScale, cy + 18 * faceScale), paintPaint..color = Colors.deepOrangeAccent);
        canvas.drawLine(Offset(cx + 55 * faceScale, cy + 8 * faceScale), Offset(cx + 35 * faceScale, cy + 18 * faceScale), paintPaint..color = Colors.cyanAccent);
      } else if (index == 8) { // Clown Face
        canvas.drawCircle(Offset(cx, cy + 10 * faceScale), 13 * faceScale, Paint()..color = Colors.red);
        canvas.drawCircle(Offset(cx - 40 * faceScale, cy + 18 * faceScale), 8 * faceScale, Paint()..color = Colors.red.withValues(alpha: 0.45));
        canvas.drawCircle(Offset(cx + 40 * faceScale, cy + 18 * faceScale), 8 * faceScale, Paint()..color = Colors.red.withValues(alpha: 0.45));
      } else if (index == 9) { // Superhero
        final paintHero = Paint()..color = const Color(0xFF1565C0)..style = PaintingStyle.fill;
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - 65 * faceScale, cy - 32 * faceScale, 130 * faceScale, 22 * faceScale), Radius.circular(8 * faceScale)), paintHero);
        final paintCut = Paint()..blendMode = BlendMode.clear;
        canvas.drawCircle(Offset(cx - 28 * faceScale, cy - 20 * faceScale), 8 * faceScale, paintCut);
        canvas.drawCircle(Offset(cx + 28 * faceScale, cy - 20 * faceScale), 8 * faceScale, paintCut);
      } else if (index == 10) { // Animal Mask
        final paintMask = Paint()..color = Colors.white..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(cx, cy - 8 * faceScale), 55 * faceScale, paintMask);
        canvas.drawCircle(Offset(cx - 28 * faceScale, cy - 12 * faceScale), 18 * faceScale, Paint()..color = Colors.black);
        canvas.drawCircle(Offset(cx + 28 * faceScale, cy - 12 * faceScale), 18 * faceScale, Paint()..color = Colors.black);
        canvas.drawCircle(Offset(cx - 28 * faceScale, cy - 12 * faceScale), 6 * faceScale, Paint()..color = Colors.white);
        canvas.drawCircle(Offset(cx + 28 * faceScale, cy - 12 * faceScale), 6 * faceScale, Paint()..color = Colors.white);
        canvas.drawCircle(Offset(cx, cy + 12 * faceScale), 8 * faceScale, Paint()..color = Colors.black);
      }
    }
  }

  void _paintAnimal(Canvas canvas, Size size, double cx, double cy, double faceScale, Offset? leftEye, Offset? rightEye, Offset? mouth) {
    final index = selectedFilters['🐶 ANIMAL'] ?? 0;
    if (index == 0) return;

    final Offset eyeCenter = (leftEye != null && rightEye != null)
        ? Offset((leftEye.dx + rightEye.dx) / 2, (leftEye.dy + rightEye.dy) / 2)
        : Offset(cx, cy - 22 * faceScale);

    final Offset earsCenter = eyeCenter - Offset(0, 50 * faceScale);
    final Offset noseCenter = Offset(cx, cy + 12 * faceScale);

    if (index == 1 || index == 2) { // Dog Ears & Puppy Face
      canvas.save();
      canvas.translate(earsCenter.dx, earsCenter.dy);
      canvas.scale(faceScale);
      final paintEar = Paint()..color = const Color(0xFF795548)..style = PaintingStyle.fill;
      canvas.drawOval(const Rect.fromLTWH(-42, -40, 26, 64), paintEar);
      canvas.drawOval(const Rect.fromLTWH(16, -40, 26, 64), paintEar);
      canvas.restore();
      
      final paintTongue = Paint()..color = Colors.redAccent..style = PaintingStyle.fill;
      final Offset mouthCenter = mouth ?? Offset(cx, cy + 64 * faceScale);
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(mouthCenter.dx - 9 * faceScale, mouthCenter.dy + 2, 18 * faceScale, 26 * faceScale), Radius.circular(8 * faceScale)), paintTongue);
      if (index == 2) {
        canvas.drawCircle(noseCenter, 10 * faceScale, Paint()..color = Colors.black87);
      }
    } else if (index == 3) { // Cat Face
      canvas.save();
      canvas.translate(earsCenter.dx, earsCenter.dy);
      canvas.scale(faceScale);
      final paintCat = Paint()..color = Colors.grey.shade400..style = PaintingStyle.fill;
      final pathEarL = Path()..moveTo(-35, -15)..lineTo(-10, -55)..lineTo(15, -15)..close();
      canvas.drawPath(pathEarL, paintCat);
      final pathEarR = Path()..moveTo(15, -15)..lineTo(40, -55)..lineTo(65, -15)..close();
      canvas.drawPath(pathEarR, paintCat);
      canvas.restore();
      
      final paintWhisker = Paint()..color = Colors.white..strokeWidth = 1.2 * faceScale;
      canvas.drawLine(Offset(noseCenter.dx - 18 * faceScale, noseCenter.dy), Offset(noseCenter.dx - 60 * faceScale, noseCenter.dy - 4 * faceScale), paintWhisker);
      canvas.drawLine(Offset(noseCenter.dx - 18 * faceScale, noseCenter.dy + 4 * faceScale), Offset(noseCenter.dx - 65 * faceScale, noseCenter.dy + 4 * faceScale), paintWhisker);
      canvas.drawLine(Offset(noseCenter.dx + 18 * faceScale, noseCenter.dy), Offset(noseCenter.dx + 60 * faceScale, noseCenter.dy - 4 * faceScale), paintWhisker);
      canvas.drawLine(Offset(noseCenter.dx + 18 * faceScale, noseCenter.dy + 4 * faceScale), Offset(noseCenter.dx + 65 * faceScale, noseCenter.dy + 4 * faceScale), paintWhisker);
      canvas.drawCircle(noseCenter, 4 * faceScale, Paint()..color = Colors.pinkAccent);
    } else if (index == 4 || index == 5) { // Tiger & Lion Face
      canvas.drawCircle(Offset(cx, cy - 12 * faceScale), 100 * faceScale, Paint()..color = Colors.orangeAccent.withValues(alpha: 0.4)..style = PaintingStyle.stroke..strokeWidth = 20 * faceScale);
      canvas.drawCircle(Offset(cx - 70 * faceScale, cy - 85 * faceScale), 18 * faceScale, Paint()..color = Colors.brown);
      canvas.drawCircle(Offset(cx + 70 * faceScale, cy - 85 * faceScale), 18 * faceScale, Paint()..color = Colors.brown);
    } else if (index == 6) { // Rabbit Ears
      canvas.save();
      canvas.translate(earsCenter.dx, earsCenter.dy);
      canvas.scale(faceScale);
      final paintRab = Paint()..color = Colors.white..style = PaintingStyle.fill;
      final paintRabPink = Paint()..color = Colors.pink.shade100..style = PaintingStyle.fill;
      canvas.drawOval(const Rect.fromLTWH(-35, -90, 20, 90), paintRab);
      canvas.drawOval(const Rect.fromLTWH(-30, -70, 10, 68), paintRabPink);
      canvas.drawOval(const Rect.fromLTWH(15, -90, 20, 90), paintRab);
      canvas.drawOval(const Rect.fromLTWH(20, -70, 10, 68), paintRabPink);
      canvas.restore();
    } else if (index == 7) { // Panda Face
      canvas.drawCircle(Offset(cx - 70 * faceScale, cy - 80 * faceScale), 20 * faceScale, Paint()..color = Colors.black);
      canvas.drawCircle(Offset(cx + 70 * faceScale, cy - 80 * faceScale), 20 * faceScale, Paint()..color = Colors.black);
    } else if (index == 8) { // Bear Face
      canvas.drawCircle(Offset(cx - 65 * faceScale, cy - 75 * faceScale), 22 * faceScale, Paint()..color = Colors.brown.shade800);
      canvas.drawCircle(Offset(cx + 65 * faceScale, cy - 75 * faceScale), 22 * faceScale, Paint()..color = Colors.brown.shade800);
      canvas.drawCircle(noseCenter, 10 * faceScale, Paint()..color = Colors.orange.shade100);
      canvas.drawCircle(noseCenter - Offset(0, 3 * faceScale), 5 * faceScale, Paint()..color = Colors.black);
    } else if (index == 9 || index == 10) { // Fox / Deer Antlers
      final paintAntler = Paint()..color = Colors.brown.shade700..style = PaintingStyle.stroke..strokeWidth = 4 * faceScale..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(cx - 45 * faceScale, cy - 75 * faceScale), Offset(cx - 75 * faceScale, cy - 130 * faceScale), paintAntler);
      canvas.drawLine(Offset(cx - 58 * faceScale, cy - 102 * faceScale), Offset(cx - 85 * faceScale, cy - 102 * faceScale), paintAntler);
      canvas.drawLine(Offset(cx + 45 * faceScale, cy - 75 * faceScale), Offset(cx + 75 * faceScale, cy - 130 * faceScale), paintAntler);
      canvas.drawLine(Offset(cx + 58 * faceScale, cy - 102 * faceScale), Offset(cx + 85 * faceScale, cy - 102 * faceScale), paintAntler);
      canvas.drawCircle(noseCenter, 7 * faceScale, Paint()..color = Colors.black);
    }
  }

  void _paintArtistic(Canvas canvas, Size size, double cx, double cy) {
    final index = selectedFilters['🎨 ARTISTIC'] ?? 0;
    if (index == 0) return;

    if (index == 1 || index == 2) { // Cartoon & Anime Frame Corners
      final paintAnime = Paint()..color = Colors.white.withValues(alpha: 0.35)..strokeWidth = 1.8;
      canvas.drawLine(const Offset(12, 12), const Offset(55, 12), paintAnime);
      canvas.drawLine(const Offset(12, 12), const Offset(12, 55), paintAnime);
      canvas.drawLine(Offset(size.width - 12, 12), Offset(size.width - 55, 12), paintAnime);
      canvas.drawLine(Offset(size.width - 12, 12), Offset(size.width - 12, 55), paintAnime);
    } else if (index == 3) { // Manga Speedlines
      final paintManga = Paint()..color = Colors.black.withValues(alpha: 0.22)..strokeWidth = 1.2;
      for (int i = 0; i < 360; i += 15) {
        final rad = i * math.pi / 180;
        final startDist = size.width * 0.42;
        final endDist = size.width * 0.72;
        canvas.drawLine(
          Offset(cx + math.cos(rad) * startDist, cy + math.sin(rad) * startDist),
          Offset(cx + math.cos(rad) * endDist, cy + math.sin(rad) * endDist),
          paintManga,
        );
      }
    } else if (index == 4) { // Comic Book POP/POW bubble
      final paintBubble = Paint()..color = Colors.yellowAccent..style = PaintingStyle.fill;
      final paintBubbleBorder = Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth = 2;
      canvas.drawCircle(Offset(size.width - 55, 95), 26, paintBubble);
      canvas.drawCircle(Offset(size.width - 55, 95), 26, paintBubbleBorder);
      
      final textSpan = TextSpan(
        text: 'POW!',
        style: GoogleFonts.bangers(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold),
      );
      final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(size.width - 55 - tp.width / 2, 95 - tp.height / 2));
    } else if (index == 5 || index == 6) { // Sketch & Pencil Draw diagonals
      final paintSketch = Paint()..color = Colors.grey.withValues(alpha: 0.12)..strokeWidth = 0.8;
      for (double x = 0; x < size.width; x += 35) {
        canvas.drawLine(Offset(x, 0), Offset(x + 90, size.height), paintSketch);
      }
    } else if (index == 10) { // Pixel Art screen grid
      final paintGrid = Paint()..color = Colors.black.withValues(alpha: 0.15)..strokeWidth = 0.4;
      for (double x = 0; x < size.width; x += 14) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), paintGrid);
      }
      for (double y = 0; y < size.height; y += 14) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paintGrid);
      }
    }
  }

  void _paintAI(Canvas canvas, Size size, double cx, double cy) {
    final index = selectedFilters['🤖 AI'] ?? 0;
    if (index == 0) return;

    final scanY = size.height * pulseValue;
    final paintLine = Paint()
      ..color = const Color(0xFF00E5FF)
      ..strokeWidth = 2.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawLine(Offset(0, scanY), Offset(size.width, scanY), paintLine);

    final textStyle = GoogleFonts.shareTechMono(color: const Color(0xFF00E5FF), fontSize: 10, fontWeight: FontWeight.bold);
    final textPainter = TextPainter(
      text: TextSpan(text: "🧬 AI LANDMARKS: 99.8%  [SEED ${(pulseValue * 999).toInt()}]", style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(20, scanY - 16));
  }

  void _paintAge(Canvas canvas, Size size, double cx, double cy, double faceScale, Offset? mouth) {
    final index = selectedFilters['👴 AGE'] ?? 0;
    if (index == 0) return;

    final Offset mouthCenter = mouth ?? Offset(cx, cy + 60 * faceScale);

    if (index == 1) { // Baby Face Pacifier
      final paintPac = Paint()..color = Colors.cyan.shade300..style = PaintingStyle.fill;
      canvas.drawCircle(mouthCenter, 10 * faceScale, paintPac);
      canvas.drawCircle(mouthCenter, 5 * faceScale, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 1.8 * faceScale);
    } else if (index == 2) { // Child Face Propeller Hat
      final paintHat = Paint()..color = Colors.redAccent..style = PaintingStyle.fill;
      canvas.drawOval(Rect.fromLTWH(cx - 30 * faceScale, cy - 105 * faceScale, 60 * faceScale, 22 * faceScale), paintHat);
      canvas.drawLine(Offset(cx, cy - 105 * faceScale), Offset(cx, cy - 116 * faceScale), Paint()..color = Colors.yellowAccent..strokeWidth = 2.5 * faceScale);
      canvas.drawCircle(Offset(cx, cy - 116 * faceScale), 3 * faceScale, Paint()..color = Colors.blueAccent);
    } else if (index == 3) { // Teenager gaming headphones
      final paintPh = Paint()..color = Colors.greenAccent..style = PaintingStyle.stroke..strokeWidth = 7 * faceScale..strokeCap = StrokeCap.round;
      final arcPath = Path()..addArc(Rect.fromCircle(center: Offset(cx, cy - 25 * faceScale), radius: 60 * faceScale), math.pi, math.pi);
      canvas.drawPath(arcPath, paintPh);
      
      final paintCups = Paint()..color = Colors.black..style = PaintingStyle.fill;
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - 67 * faceScale, cy - 35 * faceScale, 14 * faceScale, 28 * faceScale), Radius.circular(6 * faceScale)), paintCups);
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx + 53 * faceScale, cy - 35 * faceScale, 14 * faceScale, 28 * faceScale), Radius.circular(6 * faceScale)), paintCups);
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - 67 * faceScale, cy - 35 * faceScale, 14 * faceScale, 28 * faceScale), Radius.circular(6 * faceScale)), paintPh..style = PaintingStyle.stroke..strokeWidth = 1.5 * faceScale);
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx + 53 * faceScale, cy - 35 * faceScale, 14 * faceScale, 28 * faceScale), Radius.circular(6 * faceScale)), paintPh..style = PaintingStyle.stroke..strokeWidth = 1.5 * faceScale);
    }
  }

  void _paintFrames(Canvas canvas, Size size) {
    final frameIndex = selectedFilters['🎬 FRAMES'] ?? 0;
    if (frameIndex == 0) return;

    final paintLine = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    if (frameIndex == 1) { // Cinematic Scope (2.39:1 letterbox)
      final barHeight = size.height * 0.12;
      final paintBar = Paint()..color = Colors.black..style = PaintingStyle.fill;

      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, barHeight), paintBar);
      canvas.drawRect(Rect.fromLTWH(0, size.height - barHeight, size.width, barHeight), paintBar);

      final textStyle = GoogleFonts.shareTechMono(color: Colors.white30, fontSize: 10, letterSpacing: 1.5);
      final leftPainter = TextPainter(
        text: TextSpan(text: "FPS 24.00", style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      leftPainter.paint(canvas, Offset(24, barHeight + 16));

      final rightPainter = TextPainter(
        text: TextSpan(text: "SCOPE 2.39:1", style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      rightPainter.paint(canvas, Offset(size.width - rightPainter.width - 24, barHeight + 16));

      final cx = size.width / 2;
      final cy = size.height / 2;
      canvas.drawLine(Offset(cx - 8, cy), Offset(cx + 8, cy), Paint()..color = Colors.white12..strokeWidth = 1);
      canvas.drawLine(Offset(cx, cy - 8), Offset(cx, cy + 8), Paint()..color = Colors.white12..strokeWidth = 1);

    } else if (frameIndex == 2) { // Viewfinder REC Layout
      const margin = 20.0;
      const length = 25.0;

      final path = Path();
      // Top-Left
      path.moveTo(margin, margin + length);
      path.lineTo(margin, margin);
      path.lineTo(margin + length, margin);
      // Top-Right
      path.moveTo(size.width - margin - length, margin);
      path.lineTo(size.width - margin, margin);
      path.lineTo(size.width - margin, margin + length);
      // Bottom-Right
      path.moveTo(size.width - margin, size.height - margin - length);
      path.lineTo(size.width - margin, size.height - margin);
      path.lineTo(size.width - margin - length, size.height - margin);
      // Bottom-Left
      path.moveTo(margin + length, size.height - margin);
      path.lineTo(margin, size.height - margin);
      path.lineTo(margin, size.height - margin - length);

      canvas.drawPath(path, paintLine);

      final isRecVisible = pulseValue < 0.5;
      if (isRecVisible) {
        final paintRed = Paint()..color = Colors.red..style = PaintingStyle.fill;
        canvas.drawCircle(const Offset(margin + 12, margin + 40), 5, paintRed);
      }

      final recPainter = TextPainter(
        text: TextSpan(
          text: "REC",
          style: GoogleFonts.outfit(color: Colors.white.withValues(alpha: 0.8), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      recPainter.paint(canvas, const Offset(margin + 24, margin + 33));

      const bx = margin + 12.0;
      final by = size.height - margin - 45.0;
      const bw = 24.0;
      const bh = 12.0;

      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(bx, by, bw, bh), const Radius.circular(2)), Paint()..color = Colors.white54..style = PaintingStyle.stroke..strokeWidth = 1);
      canvas.drawRect(Rect.fromLTWH(bx + bw, by + bh / 4, 2, bh / 2), Paint()..color = Colors.white54..style = PaintingStyle.fill);
      canvas.drawRect(Rect.fromLTWH(bx + 2, by + 2, bw * 0.7 - 2, bh - 4), Paint()..color = Colors.green.withValues(alpha: 0.6)..style = PaintingStyle.fill);

      final pctPainter = TextPainter(
        text: TextSpan(text: "75%", style: GoogleFonts.shareTechMono(color: Colors.white54, fontSize: 9)),
        textDirection: TextDirection.ltr,
      )..layout();
      pctPainter.paint(canvas, Offset(bx + bw + 8, by + 1));

    } else if (frameIndex == 3) { // Neon Cyber Glow Frame
      final paintGlow = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0;

      final t = pulseValue;
      final c1 = Color.lerp(const Color(0xFF22D3EE), const Color(0xFFEC4899), t)!;
      final c2 = Color.lerp(const Color(0xFFEC4899), const Color(0xFFC084FC), t)!;

      final rect = Rect.fromLTWH(2, 2, size.width - 4, size.height - 4);
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(24));

      paintGlow.shader = LinearGradient(
        colors: [c1, c2, c1],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect);

      canvas.drawRRect(rrect, paintGlow);
    }
  }

  @override
  bool shouldRepaint(covariant _FilterOverlayPainter old) => true;
}
