import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../../../core/utils/image_filter_math.dart';
import '../../../../core/utils/ui_helpers.dart';
import '../../../../shared/widgets/liquid_glass.dart';

class CameraScreen extends StatefulWidget {
  final FilterPreset? initialFilter;

  const CameraScreen({
    super.key,
    this.initialFilter,
  });

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver {
  List<CameraDescription> _cameras = [];
  CameraController? _controller;
  int _selectedCameraIndex = 0;
  bool _isCameraReady = false;
  bool _isCapturing = false;

  FlashMode _flashMode = FlashMode.off;
  late FilterPreset _activeFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _activeFilter = widget.initialFilter ?? ImageFilterMath.presets[0];
    _initCameras();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? camera = _controller;
    if (camera == null || !camera.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      camera.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCameraController(camera.description);
    }
  }

  Future<void> _initCameras() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        final status = await Permission.camera.request();
        if (status.isGranted || status.isLimited) {
          _cameras = await availableCameras();
        }
      }

      if (_cameras.isNotEmpty) {
        // Default to back camera
        final backIndex = _cameras.indexWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
        );
        _selectedCameraIndex = backIndex >= 0 ? backIndex : 0;
        await _initCameraController(_cameras[_selectedCameraIndex]);
      }
    } catch (e) {
      debugPrint('Camera init error: $e');
      if (mounted) setState(() => _isCameraReady = false);
    }
  }

  Future<void> _initCameraController(CameraDescription description) async {
    await _controller?.dispose();
    final controller = CameraController(
      description,
      ResolutionPreset.high,
      enableAudio: false,
    );
    _controller = controller;

    try {
      await controller.initialize();
      await controller.setFlashMode(_flashMode);
      if (mounted) {
        setState(() {
          _isCameraReady = true;
        });
      }
    } catch (e) {
      debugPrint('Controller init error: $e');
      if (mounted) setState(() => _isCameraReady = false);
    }
  }

  Future<void> _flipCamera() async {
    if (_cameras.length < 2) return;
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    await _initCameraController(_cameras[_selectedCameraIndex]);
  }

  Future<void> _toggleFlash() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    FlashMode nextMode;
    switch (_flashMode) {
      case FlashMode.off:
        nextMode = FlashMode.auto;
        break;
      case FlashMode.auto:
        nextMode = FlashMode.always;
        break;
      default:
        nextMode = FlashMode.off;
        break;
    }

    try {
      await _controller!.setFlashMode(nextMode);
      setState(() => _flashMode = nextMode);
    } catch (_) {}
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized || _isCapturing) return;

    setState(() => _isCapturing = true);
    try {
      final XFile rawPhoto = await _controller!.takePicture();
      XFile finalPhoto = rawPhoto;

      // If a non-normal filter is selected, bake mathematical matrix into raw bytes
      if (_activeFilter.matrix != ImageFilterMath.identityMatrix) {
        final rawBytes = await rawPhoto.readAsBytes();
        final processedBytes = ImageFilterMath.processImageBytes(
          rawBytes: rawBytes,
          matrix: _activeFilter.matrix,
        );
        final tempDir = await getTemporaryDirectory();
        final path =
            '${tempDir.path}/camera_snap_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final file = File(path);
        await file.writeAsBytes(processedBytes);
        finalPhoto = XFile(file.path);
      }

      // Save photo to device gallery
      try {
        final bytes = await finalPhoto.readAsBytes();
        await PhotoManager.editor.saveImage(
          bytes,
          filename: 'Bubble_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
      } catch (saveErr) {
        debugPrint('Auto-save to device gallery error: $saveErr');
      }

      if (mounted) {
        Navigator.pop(context, finalPhoto);
      }
    } catch (e) {
      debugPrint('Capture error: $e');
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  IconData get _flashIcon {
    switch (_flashMode) {
      case FlashMode.auto:
        return PhosphorIconsRegular.lightning;
      case FlashMode.always:
        return PhosphorIconsFill.lightning;
      default:
        return PhosphorIconsRegular.lightningSlash;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Live Camera Viewfinder with Real-Time GPU Color Filter
            if (_isCameraReady && _controller != null && _controller!.value.isInitialized)
              Center(
                child: ClipRect(
                  child: ColorFiltered(
                    colorFilter: ColorFilter.matrix(_activeFilter.matrix),
                    child: CameraPreview(_controller!),
                  ),
                ),
              )
            else
              const Center(
                child: CircularProgressIndicator(color: Colors.white54),
              ),

            // 2. Top Header Controls (Close, Flash, Flip)
            Positioned(
              top: 14,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Close button
                  GestureDetector(
                    onTap: () {
                      SafeHaptics.lightImpact();
                      Navigator.pop(context);
                    },
                    child: LiquidGlassContainer(
                      borderRadius: BorderRadius.circular(22),
                      blur: 16,
                      hasBlur: true,
                      padding: const EdgeInsets.all(10),
                      child: const Icon(PhosphorIconsRegular.x, color: Colors.white, size: 20),
                    ),
                  ),

                  // Center indicator (Active filter name)
                  Flexible(
                    child: LiquidGlassContainer(
                    borderRadius: BorderRadius.circular(20),
                    blur: 16,
                    hasBlur: true,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    border: _activeFilter.id != 'normal'
                        ? Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.2)
                        : null,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _activeFilter.icon,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                          _activeFilter.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                          ),
                      ],
                    ),
                  ),
                  ),

                  // Right actions (Flash & Flip)
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          SafeHaptics.lightImpact();
                          _toggleFlash();
                        },
                        child: LiquidGlassContainer(
                          borderRadius: BorderRadius.circular(22),
                          blur: 16,
                          hasBlur: true,
                          padding: const EdgeInsets.all(10),
                          child: Icon(
                            _flashIcon,
                            color: _flashMode != FlashMode.off
                                ? const Color(0xFFFBBF24)
                                : Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      if (_cameras.length > 1) ...[
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () {
                            SafeHaptics.lightImpact();
                            _flipCamera();
                          },
                          child: LiquidGlassContainer(
                            borderRadius: BorderRadius.circular(22),
                            blur: 16,
                            hasBlur: true,
                            padding: const EdgeInsets.all(10),
                            child: const Icon(
                              PhosphorIconsRegular.cameraRotate,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // 3. Bottom Controls: Filter Carousel + Shutter Button
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Filter Presets Horizontal Selector
                  SizedBox(
                    height: 52,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: ImageFilterMath.presets.length,
                      itemBuilder: (context, index) {
                        final preset = ImageFilterMath.presets[index];
                        final isSelected = _activeFilter.id == preset.id;

                        return GestureDetector(
                          onTap: () {
                            SafeHaptics.selectionClick();
                            setState(() {
                              _activeFilter = preset;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                            child: LiquidGlassContainer(
                              borderRadius: BorderRadius.circular(20),
                              blur: 14,
                              hasBlur: true,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              gradient: isSelected
                                  ? LiquidGlassTheme.primaryLiquidGradient(context: context)
                                  : null,
                              border: isSelected
                                  ? Border.all(color: LiquidGlassTheme.pillBorderColor(context, isSelected: true), width: 1.4)
                                  : null,
                              child: Row(
                                children: [
                                  Icon(
                                    preset.icon,
                                    size: 14,
                                    color: isSelected ? LiquidGlassTheme.primaryTextColor(context) : Colors.white,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    preset.name,
                                    style: TextStyle(
                                      color: isSelected ? LiquidGlassTheme.primaryTextColor(context) : Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Liquid Glass Shutter Button
                  GestureDetector(
                    onTap: () {
                      SafeHaptics.mediumImpact();
                      _takePicture();
                    },
                    child: Container(
                      width: 82,
                      height: 82,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.8),
                          width: 3.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(5),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isCapturing
                              ? Colors.grey.withValues(alpha: 0.8)
                              : Colors.white,
                        ),
                        child: _isCapturing
                            ? const Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.black,
                                  ),
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

