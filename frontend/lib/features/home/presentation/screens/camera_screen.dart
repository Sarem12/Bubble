import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../../../app/theme.dart';
import '../../../../core/utils/image_filter_math.dart';
import '../../../../core/utils/ui_helpers.dart';
import '../../../../shared/widgets/liquid_glass.dart';

class CameraScreen extends StatefulWidget {
  final FilterPreset? initialFilter;

  const CameraScreen({super.key, this.initialFilter});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  List<CameraDescription> _cameras = [];
  CameraController? _controller;
  Future<void> _cameraDisposal = Future<void>.value();
  int _cameraGeneration = 0;
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
    _cameraGeneration++;
    final controller = _controller;
    _controller = null;
    _scheduleCameraDisposal(controller);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _cameraGeneration++;
      final controller = _controller;
      _controller = null;
      _scheduleCameraDisposal(controller);
      if (mounted && _isCameraReady) {
        setState(() => _isCameraReady = false);
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_cameras.isEmpty) {
        _initCameras();
      } else if (_selectedCameraIndex < _cameras.length) {
        _initCameraController(_cameras[_selectedCameraIndex]);
      }
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
    final generation = ++_cameraGeneration;
    final previousController = _controller;
    _controller = null;
    _scheduleCameraDisposal(previousController);
    if (mounted) setState(() => _isCameraReady = false);

    await _cameraDisposal;
    if (!mounted || generation != _cameraGeneration) return;

    final controller = CameraController(
      description,
      ResolutionPreset.high,
      enableAudio: false,
    );
    _controller = controller;

    try {
      await controller.initialize();
      if (!mounted || generation != _cameraGeneration) {
        await controller.dispose();
        return;
      }
      await controller.setFlashMode(_flashMode);
      if (!mounted || generation != _cameraGeneration) {
        await controller.dispose();
        return;
      }
      setState(() => _isCameraReady = true);
    } catch (e) {
      debugPrint('Controller init error: $e');
      await controller.dispose();
      if (generation == _cameraGeneration) {
        _controller = null;
        if (mounted) setState(() => _isCameraReady = false);
      }
    }
  }

  void _scheduleCameraDisposal(CameraController? controller) {
    if (controller == null) return;
    final pendingDisposal = _cameraDisposal;
    _cameraDisposal = () async {
      await pendingDisposal;
      await controller.dispose();
    }();
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
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _isCapturing) {
      return;
    }

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
    return Theme(
      data: AppTheme.darkTheme,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Live Camera Viewfinder with Real-Time GPU Color Filter
              if (_isCameraReady &&
                  _controller != null &&
                  _controller!.value.isInitialized)
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
                top: 12,
                left: 16,
                right: 16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    _buildGlassIconButton(
                      icon: PhosphorIconsRegular.x,
                      tooltip: 'Close camera',
                      onTap: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Center(
                        child: LiquidGlassContainer(
                          borderRadius: BorderRadius.circular(22),
                          blur: 18,
                          hasBlur: true,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 9,
                          ),
                          border: Border.all(
                            color: Colors.white.withValues(
                              alpha: _activeFilter.id == 'normal' ? 0.16 : 0.45,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _activeFilter.icon,
                                size: 15,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 7),
                              Text(
                                _activeFilter.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _buildGlassIconButton(
                      icon: _flashIcon,
                      tooltip: 'Flash ${_flashMode.name}',
                      iconColor: _flashMode == FlashMode.off
                          ? Colors.white
                          : const Color(0xFFFBBF24),
                      onTap: _toggleFlash,
                    ),
                    if (_cameras.length > 1) ...[
                      const SizedBox(width: 8),
                      _buildGlassIconButton(
                        icon: PhosphorIconsRegular.cameraRotate,
                        tooltip: 'Switch camera',
                        onTap: _flipCamera,
                      ),
                    ],
                  ],
                ),
              ),

              // Floating glass control dock: filter selector and shutter.
              Positioned(
                bottom: 12,
                left: 14,
                right: 14,
                child: LiquidGlassContainer(
                  borderRadius: BorderRadius.circular(30),
                  blur: 22,
                  hasBlur: true,
                  padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 42,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          itemCount: ImageFilterMath.presets.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 7),
                          itemBuilder: (context, index) {
                            final preset = ImageFilterMath.presets[index];
                            final isSelected = _activeFilter.id == preset.id;
                            return LiquidGlassContainer(
                              borderRadius: BorderRadius.circular(20),
                              blur: 12,
                              hasBlur: true,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 13,
                                vertical: 7,
                              ),
                              gradient: isSelected
                                  ? LiquidGlassTheme.primaryLiquidGradient(
                                      context: context,
                                    )
                                  : null,
                              border: Border.all(
                                color: isSelected
                                    ? LiquidGlassTheme.pillBorderColor(
                                        context,
                                        isSelected: true,
                                      )
                                    : Colors.white.withValues(alpha: 0.12),
                              ),
                              onTap: () {
                                SafeHaptics.selectionClick();
                                setState(() => _activeFilter = preset);
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    preset.icon,
                                    size: 14,
                                    color: isSelected
                                        ? LiquidGlassTheme.primaryTextColor(
                                            context,
                                          )
                                        : Colors.white70,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    preset.name,
                                    style: TextStyle(
                                      color: isSelected
                                          ? LiquidGlassTheme.primaryTextColor(
                                              context,
                                            )
                                          : Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(width: 54),
                          GestureDetector(
                            onTap: _isCapturing
                                ? null
                                : () {
                                    SafeHaptics.mediumImpact();
                                    _takePicture();
                                  },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.24),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(5),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _isCapturing
                                      ? Colors.white70
                                      : Colors.white,
                                ),
                                child: _isCapturing
                                    ? const Center(
                                        child: SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.2,
                                            color: Colors.black,
                                          ),
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          SizedBox(
                            width: 40,
                            child: Text(
                              _controller?.description.lensDirection ==
                                      CameraLensDirection.front
                                  ? 'Front'
                                  : 'Back',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    Color iconColor = Colors.white,
  }) {
    return Tooltip(
      message: tooltip,
      child: LiquidGlassContainer(
        width: 42,
        height: 42,
        borderRadius: BorderRadius.circular(22),
        blur: 18,
        hasBlur: true,
        padding: const EdgeInsets.all(10),
        onTap: onTap,
        child: Icon(icon, color: iconColor, size: 20),
      ),
    );
  }
}
