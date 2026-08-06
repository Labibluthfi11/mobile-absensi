import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:universal_io/io.dart';
import 'dart:ui';
import 'package:image/image.dart' as img;

// Warna premium
const Color kPrimaryColor   = Color(0xFF152C5C);
const Color kSuccessColor   = Color(0xFF10B981);
const Color kSecondaryColor = Color(0xFF3B82F6);
const Color kErrorColor     = Color(0xFFEF4444);

class CustomCameraScreen extends StatefulWidget {
  final bool useBackCamera;
  const CustomCameraScreen({super.key, this.useBackCamera = false});

  @override
  State<CustomCameraScreen> createState() => _CustomCameraScreenState();
}

class _CustomCameraScreenState extends State<CustomCameraScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];

  bool _isInitialized = false;
  bool _isTakingPicture = false;
  bool _isFrontCamera = true;

  FlashMode _flashMode = FlashMode.off;
  File? _previewFile;

  // Untuk animasi tap-to-focus
  Offset? _focusPoint;
  bool _showFocusCircle = false;

  late AnimationController _animController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animController.dispose();
    _controller?.dispose();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final ctrl = _controller;
    if (ctrl == null || !ctrl.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      ctrl.dispose();
      if (mounted) setState(() => _isInitialized = false);
    } else if (state == AppLifecycleState.resumed) {
      _initCameraWith(ctrl.description);
    }
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        _showSnackbar('Tidak ada kamera yang tersedia.', isError: true);
        return;
      }

      final targetCam = _cameras.firstWhere(
        (c) => c.lensDirection == (widget.useBackCamera ? CameraLensDirection.back : CameraLensDirection.front),
        orElse: () => _cameras.first,
      );

      await _initCameraWith(targetCam);
    } catch (e) {
      _showSnackbar('Gagal inisialisasi kamera: $e', isError: true);
    }
  }

  Future<void> _initCameraWith(CameraDescription description) async {
    await _controller?.dispose();

    final ctrl = CameraController(
      description,
      ResolutionPreset.veryHigh,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    _controller = ctrl;

    try {
      await ctrl.initialize();
      await ctrl.setFlashMode(_flashMode);
      await ctrl.setFocusMode(FocusMode.auto);
      await ctrl.setExposureMode(ExposureMode.auto);

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _isFrontCamera = description.lensDirection == CameraLensDirection.front;
        });
      }
    } on CameraException catch (e) {
      _showSnackbar('Error kamera: ${e.description}', isError: true);
    }
  }

  Future<void> _toggleCamera() async {
    if (_cameras.length < 2 || !_isInitialized) return;

    setState(() => _isInitialized = false);

    final newCam = _isFrontCamera
        ? _cameras.firstWhere(
            (c) => c.lensDirection == CameraLensDirection.back,
            orElse: () => _cameras.last,
          )
        : _cameras.firstWhere(
            (c) => c.lensDirection == CameraLensDirection.front,
            orElse: () => _cameras.first,
          );

    await _initCameraWith(newCam);
  }

  Future<void> _toggleFlash() async {
    if (_controller == null || !_isInitialized) return;
    final next = _flashMode == FlashMode.off ? FlashMode.torch : FlashMode.off;
    await _controller!.setFlashMode(next);
    setState(() => _flashMode = next);
  }

  Future<void> _onTapToFocus(TapUpDetails details, BoxConstraints constraints) async {
    if (_controller == null || !_isInitialized) return;

    double dx = details.localPosition.dx / constraints.maxWidth;
    
    final offset = Offset(
      dx,
      details.localPosition.dy / constraints.maxHeight,
    );

    setState(() {
      _focusPoint = details.localPosition;
      _showFocusCircle = true;
    });

    try {
      await _controller!.setFocusPoint(offset);
      await _controller!.setExposurePoint(offset);
    } catch (_) {}

    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) setState(() => _showFocusCircle = false);
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_isTakingPicture) return;

    setState(() => _isTakingPicture = true);

    try {
      await _controller!.setFlashMode(FlashMode.auto);
      final XFile imageFile = await _controller!.takePicture();
      await _controller!.setFlashMode(_flashMode);

      File finalFile = File(imageFile.path);

      if (_isFrontCamera) {
        try {
          final bytes = await finalFile.readAsBytes();
          final decodedImage = img.decodeImage(bytes);
          if (decodedImage != null) {
            // Flip horizonal biar hasil foto tidak terbalik/miror untuk kamera depan
            final flippedImage = img.flipHorizontal(decodedImage);
            await finalFile.writeAsBytes(img.encodeJpg(flippedImage));
          }
        } catch (e) {
          debugPrint('Gagal ngebalik frame foto: $e');
        }
      }

      if (mounted) {
        setState(() {
          _previewFile = finalFile;
          _isTakingPicture = false;
        });
      }
    } on CameraException catch (e) {
      if (mounted) {
        setState(() => _isTakingPicture = false);
        _showSnackbar('Gagal mengambil foto: ${e.description}', isError: true);
      }
    }
  }

  void _retakePicture() => setState(() => _previewFile = null);

  void _confirmPicture() {
    if (_previewFile != null) {
      Navigator.of(context).pop(_previewFile);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _previewFile != null ? _buildPreviewMode() : _buildCameraMode(),
    );
  }

  Widget _buildCameraMode() {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (_isInitialized && _controller != null)
          _buildCameraPreview()
        else
          Container(
            color: Colors.black,
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                  SizedBox(height: 24),
                  Text('Memulai kamera...', style: TextStyle(color: Colors.white70, fontSize: 16)),
                ],
              ),
            ),
          ),

        SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              const Spacer(),
              _buildFaceGuide(),
              const Spacer(),
              _buildBottomControls(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCameraPreview() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTapUp: (details) => _onTapToFocus(details, constraints),
          child: Stack(
            fit: StackFit.expand,
            children: [
              SizedBox(
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: constraints.maxWidth,
                    height: constraints.maxWidth * _controller!.value.aspectRatio,
                    child: CameraPreview(_controller!),
                  ),
                ),
              ),

              if (_showFocusCircle && _focusPoint != null)
                Positioned(
                  left: _focusPoint!.dx - 35,
                  top: _focusPoint!.dy - 35,
                  child: _buildFocusCircle(),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFocusCircle() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1.5, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      builder: (_, value, child) => Transform.scale(scale: value, child: child),
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.amberAccent, width: 2.5),
          borderRadius: BorderRadius.circular(35),
          boxShadow: [
            BoxShadow(color: Colors.amberAccent.withOpacity(0.3), blurRadius: 8, spreadRadius: 2)
          ]
        ),
        child: const Center(
          child: Icon(Icons.add, color: Colors.amberAccent, size: 24),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildGlassIconButton(
            icon: Icons.close_rounded,
            onTap: () => Navigator.of(context).pop(),
          ),
          
          const SizedBox(width: 50),
          
          _buildGlassIconButton(
            icon: _flashMode == FlashMode.off ? Icons.flash_off_rounded : Icons.flash_on_rounded,
            iconColor: _flashMode == FlashMode.torch ? Colors.amberAccent : Colors.white,
            onTap: _toggleFlash,
          ),
        ],
      ),
    );
  }

  Widget _buildFaceGuide() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.25),
                        width: 2,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 280,
                    height: 280,
                    child: CustomPaint(
                      painter: FocusBracketPainter(),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 40),
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.15)),
              ),
              child: const Text(
                'Posisikan wajah di dalam area',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildGlassIconButton(
            icon: Icons.cameraswitch_rounded,
            size: 56,
            onTap: _cameras.length > 1 ? _toggleCamera : null,
          ),

          GestureDetector(
            onTap: _isTakingPicture ? null : _takePicture,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 86,
              height: 86,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.15),
                border: Border.all(
                  color: Colors.white.withOpacity(0.8),
                  width: 4,
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))
                ]
              ),
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: _isTakingPicture ? 35 : 68,
                  height: _isTakingPicture ? 35 : 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.rectangle,
                    borderRadius: _isTakingPicture ? BorderRadius.circular(10) : BorderRadius.circular(34),
                    color: Colors.white,
                  ),
                  child: _isTakingPicture
                      ? const Padding(
                          padding: EdgeInsets.all(6.0),
                          child: CircularProgressIndicator(color: kPrimaryColor, strokeWidth: 3),
                      )
                      : null,
                ),
              ),
            ),
          ),

          const SizedBox(width: 56, height: 56), 
        ],
      ),
    );
  }

  Widget _buildPreviewMode() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.file(_previewFile!, fit: BoxFit.cover),

        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.4),
                Colors.transparent,
                Colors.transparent,
                Colors.black.withOpacity(0.85),
              ],
              stops: const [0.0, 0.2, 0.5, 1.0],
            ),
          ),
        ),

        SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    _buildGlassIconButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: _retakePicture,
                      size: 48,
                    ),
                    const Expanded(
                      child: Text(
                        'Pratinjau Foto',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 48), 
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(bottom: 40, left: 24, right: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Pastikan wajah terlihat jelas dan tidak blur',
                      style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _retakePicture,
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white.withOpacity(0.3)),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.refresh_rounded, color: Colors.white, size: 22),
                                  SizedBox(width: 8),
                                  Text('Ulangi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: InkWell(
                            onTap: _confirmPicture,
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              decoration: BoxDecoration(
                                color: kSuccessColor,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: kSuccessColor.withOpacity(0.4),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  )
                                ]
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 22),
                                  SizedBox(width: 8),
                                  Text('Gunakan Foto', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGlassIconButton({
    required IconData icon,
    VoidCallback? onTap,
    double size = 48,
    Color iconColor = Colors.white,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size / 2),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.15),
              border: Border.all(color: Colors.white.withOpacity(0.25)),
            ),
            child: Icon(
              icon,
              color: onTap == null ? Colors.white.withOpacity(0.4) : iconColor,
              size: size * 0.45,
            ),
          ),
        ),
      ),
    );
  }

  void _showSnackbar(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: isError ? kErrorColor : kSuccessColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        elevation: 8,
      ),
    );
  }
}

class FocusBracketPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final double len = 35.0; 
    
    // Top-left
    canvas.drawPath(
      Path()
        ..moveTo(0, len)
        ..lineTo(0, 0)
        ..lineTo(len, 0),
      paint,
    );
    // Top-right
    canvas.drawPath(
      Path()
        ..moveTo(size.width - len, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width, len),
      paint,
    );
    // Bottom-left
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height - len)
        ..lineTo(0, size.height)
        ..lineTo(len, size.height),
      paint,
    );
    // Bottom-right
    canvas.drawPath(
      Path()
        ..moveTo(size.width - len, size.height)
        ..lineTo(size.width, size.height)
        ..lineTo(size.width, size.height - len),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}