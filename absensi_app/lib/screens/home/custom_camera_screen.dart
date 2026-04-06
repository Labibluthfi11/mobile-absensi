import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'dart:io';

// Warna konsisten dengan absensi_masuk_screen
const Color kPrimaryColor    = Color(0xFF152C5C);
const Color kSuccessColor    = Color(0xFF10B981);
const Color kSecondaryColor  = Color(0xFF3B82F6);
const Color kErrorColor      = Color(0xFFEF4444);

class CustomCameraScreen extends StatefulWidget {
  const CustomCameraScreen({super.key});

  @override
  State<CustomCameraScreen> createState() => _CustomCameraScreenState();
}

class _CustomCameraScreenState extends State<CustomCameraScreen>
    with WidgetsBindingObserver {

  CameraController? _controller;
  List<CameraDescription> _cameras = [];

  bool _isInitialized   = false;
  bool _isTakingPicture = false;
  bool _isFrontCamera   = true;

  FlashMode _flashMode  = FlashMode.off;
  File?     _previewFile;

  // Untuk animasi tap-to-focus
  Offset?   _focusPoint;
  bool      _showFocusCircle = false;

  // ─── LIFECYCLE ───────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Paksa portrait
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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

  // ─── INISIALISASI KAMERA ─────────────────────────────────

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        _showSnackbar('Tidak ada kamera yang tersedia.', isError: true);
        return;
      }

      // Default: kamera depan untuk selfie absensi
      final frontCam = _cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras.first,
      );

      await _initCameraWith(frontCam);
    } catch (e) {
      _showSnackbar('Gagal inisialisasi kamera: $e', isError: true);
    }
  }

  Future<void> _initCameraWith(CameraDescription description) async {
    // Dispose controller lama dulu
    await _controller?.dispose();

    final ctrl = CameraController(
      description,
      ResolutionPreset.veryHigh, // ✅ Resolusi terbaik
      enableAudio: false,        // ✅ Hemat resource, absensi ga butuh audio
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    _controller = ctrl;

    try {
      await ctrl.initialize();

      // ✅ Setting terbaik untuk foto wajah yang tajam
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

  // ─── AKSI KAMERA ─────────────────────────────────────────

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

  // ✅ Tap to focus + exposure
  Future<void> _onTapToFocus(TapUpDetails details, BoxConstraints constraints) async {
    if (_controller == null || !_isInitialized) return;

    final offset = Offset(
      details.localPosition.dx / constraints.maxWidth,
      details.localPosition.dy / constraints.maxHeight,
    );

    // Tampilkan animasi lingkaran fokus
    setState(() {
      _focusPoint = details.localPosition;
      _showFocusCircle = true;
    });

    try {
      await _controller!.setFocusPoint(offset);
      await _controller!.setExposurePoint(offset);
    } catch (_) {}

    // Sembunyikan lingkaran setelah 1.5 detik
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) setState(() => _showFocusCircle = false);
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_isTakingPicture) return;

    setState(() => _isTakingPicture = true);

    try {
      // ✅ Auto flash saat capture (pakai mode auto, bukan torch terus)
      await _controller!.setFlashMode(FlashMode.auto);
      final XFile imageFile = await _controller!.takePicture();
      // Kembalikan flash mode ke pilihan user
      await _controller!.setFlashMode(_flashMode);

      if (mounted) {
        setState(() {
          _previewFile   = File(imageFile.path);
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

  // ─── BUILD ───────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _previewFile != null
          ? _buildPreviewMode()
          : _buildCameraMode(),
    );
  }

  // =====================================================
  // UI MODE 1: Live Camera
  // =====================================================

  Widget _buildCameraMode() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // ── Preview ──
        _isInitialized && _controller != null
            ? _buildCameraPreview()
            : const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text('Memuat kamera...', style: TextStyle(color: Colors.white70)),
                  ],
                ),
              ),

        // ── Overlay UI ──
        SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              const Spacer(),
              _buildFaceGuide(),
              const Spacer(),
              _buildBottomControls(),
              const SizedBox(height: 30),
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
          // ✅ Tap to focus
          onTapUp: (details) => _onTapToFocus(details, constraints),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Preview full screen
              SizedBox(
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: constraints.maxWidth,
                    height: constraints.maxWidth *
                        (_controller!.value.aspectRatio),
                    child: CameraPreview(_controller!),
                  ),
                ),
              ),

              // ✅ Animasi lingkaran fokus
              if (_showFocusCircle && _focusPoint != null)
                Positioned(
                  left:  _focusPoint!.dx - 30,
                  top:   _focusPoint!.dy - 30,
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
      tween: Tween(begin: 1.3, end: 1.0),
      duration: const Duration(milliseconds: 200),
      builder: (_, value, child) => Transform.scale(scale: value, child: child),
      child: Container(
        width:  60,
        height: 60,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.yellowAccent, width: 2),
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _circleIconButton(
            icon: Icons.arrow_back,
            onTap: () => Navigator.of(context).pop(),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Foto Absensi',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          _circleIconButton(
            icon: _flashMode == FlashMode.off ? Icons.flash_off : Icons.flash_on,
            iconColor: _flashMode == FlashMode.torch ? Colors.yellowAccent : Colors.white,
            onTap: _toggleFlash,
          ),
        ],
      ),
    );
  }

  // ✅ Oval guide biar user tau posisi wajah yang benar
  Widget _buildFaceGuide() {
    return Column(
      children: [
        Container(
          width:  210,
          height: 270,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(120),
            border: Border.all(
              color: Colors.white.withOpacity(0.75),
              width: 2.5,
            ),
          ),
          child: const Center(
            child: Icon(Icons.person, color: Colors.white24, size: 80),
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'Pastikan wajah Anda terlihat jelas',
            style: TextStyle(color: Colors.white, fontSize: 13),
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [

          // Flip Camera
          _circleIconButton(
            icon: Icons.flip_camera_ios_outlined,
            size: 52,
            onTap: _cameras.length > 1 ? _toggleCamera : null,
          ),

          // ✅ Shutter button premium
          GestureDetector(
            onTap: _isTakingPicture ? null : _takePicture,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              width:  82,
              height: 82,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                color: _isTakingPicture
                    ? Colors.white38
                    : Colors.white,
              ),
              child: _isTakingPicture
                  ? const Center(
                      child: SizedBox(
                        width:  32,
                        height: 32,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: kPrimaryColor,
                        ),
                      ),
                    )
                  : Container(
                      margin: const EdgeInsets.all(7),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: kPrimaryColor,
                      ),
                    ),
            ),
          ),

          // Placeholder biar tombol tengah simetris
          const SizedBox(width: 52, height: 52),
        ],
      ),
    );
  }

  // =====================================================
  // UI MODE 2: Preview setelah foto
  // =====================================================

  Widget _buildPreviewMode() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Foto hasil
        Image.file(_previewFile!, fit: BoxFit.cover),

        // Gradient bawah
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Container(
            height: 240,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end:   Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.88)],
              ),
            ),
          ),
        ),

        // Tombol aksi
        SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Text(
                'Hasil Foto',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Sudah jelas dan terlihat wajahnya?',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Ulangi
                  OutlinedButton.icon(
                    onPressed: _retakePicture,
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    label: const Text('Ulangi', style: TextStyle(color: Colors.white)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white54),
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                  ),

                  // Gunakan
                  ElevatedButton.icon(
                    onPressed: _confirmPicture,
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Gunakan Foto'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kSuccessColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      elevation: 6,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 44),
            ],
          ),
        ),
      ],
    );
  }

  // ─── HELPERS ─────────────────────────────────────────────

  Widget _circleIconButton({
    required IconData icon,
    VoidCallback? onTap,
    double size = 46,
    Color iconColor = Colors.white,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withOpacity(0.45),
        ),
        child: Icon(
          icon,
          color: onTap == null ? Colors.white30 : iconColor,
          size: size * 0.48,
        ),
      ),
    );
  }

  void _showSnackbar(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? kErrorColor : kSecondaryColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}