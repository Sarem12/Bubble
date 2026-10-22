import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/image_filter_math.dart';
import '../../../../core/utils/ui_helpers.dart';
import '../../../../shared/widgets/liquid_glass.dart';
import '../../../../core/transitions/bubble_page_transitions.dart';
import '../../../../shared/widgets/user_avatar.dart';
import '../../../profile/presentation/controllers/profile_controller.dart';
import '../controllers/feed_controller.dart';
import 'camera_screen.dart';
import 'photo_editor_screen.dart';

/// Custom drag listener that starts drag after a fast 120ms delay instead of default 500ms
class FastReorderableDragListener extends ReorderableDragStartListener {
  const FastReorderableDragListener({
    super.key,
    required super.child,
    required super.index,
    super.enabled,
    this.delay = const Duration(milliseconds: 120),
  });

  final Duration delay;

  @override
  MultiDragGestureRecognizer createRecognizer() {
    return DelayedMultiDragGestureRecognizer(delay: delay, debugOwner: this);
  }
}

/// Photo card inside the inline reorder strip.
/// Supports smooth slide-up gesture to remove the photo, zero border radius,
/// top-left order badge, single tap to select, and double tap to exit to normal mode.
class _SlideUpPhotoCard extends StatefulWidget {
  const _SlideUpPhotoCard({
    super.key,
    required this.file,
    required this.index,
    required this.isSelected,
    required this.onTap,
    required this.onDoubleTap,
    required this.onRemove,
  });

  final XFile file;
  final int index;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDoubleTap;
  final VoidCallback onRemove;

  @override
  State<_SlideUpPhotoCard> createState() => _SlideUpPhotoCardState();
}

class _SlideUpPhotoCardState extends State<_SlideUpPhotoCard>
    with SingleTickerProviderStateMixin {
  double _dragOffsetY = 0.0;
  late final AnimationController _resetController;
  late Animation<double> _resetAnimation;

  @override
  void initState() {
    super.initState();
    _resetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _resetController.dispose();
    super.dispose();
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    // Only allow dragging upwards (negative dy)
    setState(() {
      _dragOffsetY = (_dragOffsetY + details.delta.dy).clamp(-220.0, 0.0);
    });
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (_dragOffsetY < -60 || velocity < -350) {
      // Threshold reached -> trigger remove
      SafeHaptics.mediumImpact();
      widget.onRemove();
    } else {
      // Spring back down to 0 smoothly
      _resetAnimation = Tween<double>(begin: _dragOffsetY, end: 0.0).animate(
        CurvedAnimation(parent: _resetController, curve: Curves.easeOutCubic),
      )..addListener(() {
          setState(() {
            _dragOffsetY = _resetAnimation.value;
          });
        });
      _resetController.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final removeProgress = (-_dragOffsetY / 80).clamp(0.0, 1.0);

    return GestureDetector(
      onVerticalDragUpdate: _onVerticalDragUpdate,
      onVerticalDragEnd: _onVerticalDragEnd,
      onTapDown: (_) => widget.onTap(),
      onTap: widget.onTap,
      onDoubleTap: widget.onDoubleTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        width: 170,
        height: 218,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Background indicator for swipe-up delete (red trash indicator)
            if (_dragOffsetY < 0)
              Positioned.fill(
                child: Container(
                  color: Colors.red.withValues(alpha: 0.85 * removeProgress),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.white.withValues(alpha: removeProgress),
                    size: 32,
                  ),
                ),
              ),

            // Card body translated upwards with _dragOffsetY
            Transform.translate(
              offset: Offset(0, _dragOffsetY),
              child: Opacity(
                opacity: (1.0 - (removeProgress * 0.4)).clamp(0.0, 1.0),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Photo: ZERO border radius, sharp clean edges
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: widget.isSelected
                              ? LiquidGlassTheme.bubbleBlue
                              : Colors.white24,
                          width: widget.isSelected ? 2.5 : 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.55),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                          if (widget.isSelected)
                            BoxShadow(
                              color: LiquidGlassTheme.bubbleBlue.withValues(alpha: 0.4),
                              blurRadius: 10,
                            ),
                        ],
                      ),
                      child: kIsWeb
                          ? Image.network(widget.file.path, fit: BoxFit.cover)
                          : Image.file(File(widget.file.path), fit: BoxFit.cover),
                    ),

                    // Top-Left Order Number Badge (①, ②, ③...)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          gradient: LiquidGlassTheme.bubbleBlueGradient,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: LiquidGlassTheme.bubbleBlue.withValues(alpha: 0.18),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            '${widget.index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CreatePostScreen extends ConsumerStatefulWidget {
  final List<XFile>? initialImages;

  const CreatePostScreen({super.key, this.initialImages});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  // Step 0: Instagram Media Picker, Step 1: Caption & Share
  int _currentStep = 0;

  final TextEditingController _contentController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  // Camera state for Tile #1
  List<CameraDescription> _cameras = [];
  CameraController? _cameraController;
  bool _isCameraReady = false;
  FilterPreset _cameraFilterPreset = ImageFilterMath.presets[0]; // Active camera filter

  // Gallery state
  List<AssetEntity> _galleryAssets = [];
  bool _isLoadingGallery = false;
  bool _hasGalleryPermission = false;

  // Selected images state (always multiple selection by default)
  final List<XFile> _selectedImages = [];
  BoxFit _previewFit = BoxFit.cover; // Aspect ratio mode (Cover vs Contain)

  // Hero carousel controller & index
  final PageController _heroPageController = PageController();
  int _currentHeroIndex = 0;

  // Morph Animation Controller for smooth scale down/up reorder transitions
  late final AnimationController _morphController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );
  late final Animation<double> _morphAnimation = CurvedAnimation(
    parent: _morphController,
    curve: Curves.easeInOutCubic,
  );

  // Safety cache for edited photos (LRU: preserves at least 5 latest deselected edited photos)
  static const int _maxEditedCacheSize = 10;
  final Map<String, XFile> _editedPhotosCache = {};
  final List<String> _editedCacheOrder = [];
  final Map<String, String> _assetIdBySelectedPath = {};
  final Map<String, String> _originalPathBySelectedPath = {};

  bool _isLoading = false;
  String _uploadStatus = '';

  List<dynamic> _userBubbles = [];
  String? _selectedBubbleId;

  static const int _maxPhotos = 10;

  /// Cache an edited photo associated with a key (assetId or originalPath) with LRU eviction
  void _cacheEditedPhoto(String key, XFile editedFile) {
    _editedPhotosCache[key] = editedFile;
    _editedCacheOrder.remove(key);
    _editedCacheOrder.add(key);

    while (_editedCacheOrder.length > _maxEditedCacheSize) {
      final oldestKey = _editedCacheOrder.removeAt(0);
      final isCurrentlySelected = _selectedImages.any((img) =>
          img.path == oldestKey ||
          _assetIdBySelectedPath[img.path] == oldestKey ||
          _originalPathBySelectedPath[img.path] == oldestKey);
      if (!isCurrentlySelected) {
        _editedPhotosCache.remove(oldestKey);
      }
    }
  }

  /// Locates an asset in _selectedImages even if replaced by an edited XFile
  int _findSelectedIndexForAsset(AssetEntity asset, [String? filePath]) {
    return _selectedImages.indexWhere((img) {
      if (_assetIdBySelectedPath[img.path] == asset.id) return true;
      if (filePath != null && img.path == filePath) return true;
      if (filePath != null && _originalPathBySelectedPath[img.path] == filePath) return true;
      return false;
    });
  }

  bool _isReorderMode = false;

  void _enterReorderMode() {
    if (_selectedImages.length <= 1) return;
    SafeHaptics.mediumImpact();
    setState(() {
      _isReorderMode = true;
    });
    _morphController.forward(from: 0.0);
  }

  void _exitReorderMode() {
    if (_heroPageController.hasClients && _selectedImages.isNotEmpty) {
      _heroPageController.jumpToPage(_currentHeroIndex.clamp(0, _selectedImages.length - 1));
    }
    _morphController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _isReorderMode = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_heroPageController.hasClients && _selectedImages.isNotEmpty) {
            _heroPageController.jumpToPage(_currentHeroIndex.clamp(0, _selectedImages.length - 1));
          }
        });
      }
    });
  }

  void _removePhotoAt(int index) {
    if (index < 0 || index >= _selectedImages.length) return;
    final removed = _selectedImages.removeAt(index);
    final origPath = _originalPathBySelectedPath[removed.path] ?? removed.path;
    final assetId = _assetIdBySelectedPath[removed.path];
    if (assetId != null) {
      _cacheEditedPhoto(assetId, removed);
    }
    _cacheEditedPhoto(origPath, removed);

    setState(() {
      if (_selectedImages.length <= 1) {
        _isReorderMode = false;
        _morphController.reverse();
      }
      _currentHeroIndex = _currentHeroIndex.clamp(0, _selectedImages.length - 1);
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.initialImages != null && widget.initialImages!.isNotEmpty) {
      for (final img in widget.initialImages!) {
        _selectedImages.add(img);
        _assetIdBySelectedPath[img.path] = img.path;
        _originalPathBySelectedPath[img.path] = img.path;
      }
      _currentHeroIndex = 0;
    }
    _initCamera();
    _loadDeviceGallery(requestPermissionIfNotGranted: false);
    _fetchUserBubbles();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _contentController.dispose();
    _heroPageController.dispose();
    _morphController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? camera = _cameraController;
    if (camera == null || !camera.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      camera.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCameraController(camera.description);
    }
  }

  bool _isInitializingCamera = false;

  Future<void> _initCamera() async {
    if (_isInitializingCamera) return;
    setState(() => _isInitializingCamera = true);

    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        final cameraDesc = _cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
          orElse: () => _cameras[0],
        );
        await _initCameraController(cameraDesc);
      } else {
        if (mounted) setState(() => _isCameraReady = false);
      }
    } catch (e) {
      debugPrint('Camera discovery error: $e');
      // If error occurred (e.g. permission required before discovery), request permission and retry
      try {
        final status = await Permission.camera.request();
        if (status.isGranted || status.isLimited) {
          _cameras = await availableCameras();
          if (_cameras.isNotEmpty) {
            await _initCameraController(_cameras[0]);
          }
        }
      } catch (inner) {
        debugPrint('Camera permission retry error: $inner');
      }
      if (mounted && (_cameraController == null || !_cameraController!.value.isInitialized)) {
        setState(() => _isCameraReady = false);
      }
    } finally {
      if (mounted) setState(() => _isInitializingCamera = false);
    }
  }

  Future<void> _initCameraController(CameraDescription description) async {
    _cameraController?.dispose();
    final controller = CameraController(
      description,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    _cameraController = controller;

    try {
      await controller.initialize();
      if (mounted) setState(() => _isCameraReady = true);
    } catch (e) {
      debugPrint('Camera controller init error: $e');
      // Retry once after requesting camera permission if needed
      try {
        final status = await Permission.camera.request();
        if (status.isGranted || status.isLimited) {
          await controller.initialize();
          if (mounted) setState(() => _isCameraReady = true);
          return;
        }
      } catch (_) {}
      if (mounted) setState(() => _isCameraReady = false);
    }
  }

  void _cycleCameraFilter() {
    final currentIndex =
        ImageFilterMath.presets.indexWhere((p) => p.id == _cameraFilterPreset.id);
    final nextIndex = (currentIndex + 1) % ImageFilterMath.presets.length;
    setState(() {
      _cameraFilterPreset = ImageFilterMath.presets[nextIndex];
    });
  }

  Future<void> _openPhotoEditor([XFile? imageToEdit]) async {
    if (_selectedImages.isEmpty) return;
    final int targetIndex;
    if (imageToEdit != null) {
      final idx = _selectedImages.indexWhere((img) => img.path == imageToEdit.path);
      targetIndex = idx >= 0 ? idx : _currentHeroIndex.clamp(0, _selectedImages.length - 1);
    } else {
      targetIndex = _currentHeroIndex.clamp(0, _selectedImages.length - 1);
    }
    final target = _selectedImages[targetIndex];

    final XFile? editedResult = await Navigator.push<XFile>(
      context,
      BubbleMorphModalRoute(
        page: PhotoEditorScreen(initialImage: target),
      ),
    );

    if (editedResult != null && mounted) {
      setState(() {
        final assetId = _assetIdBySelectedPath[target.path];
        final origPath = _originalPathBySelectedPath[target.path] ?? target.path;

        _selectedImages[targetIndex] = editedResult;

        // Persist edits in safety cache
        if (assetId != null) {
          _assetIdBySelectedPath[editedResult.path] = assetId;
          _cacheEditedPhoto(assetId, editedResult);
        }
        _originalPathBySelectedPath[editedResult.path] = origPath;
        _cacheEditedPhoto(origPath, editedResult);
      });
    }
  }

  Future<void> _openCameraScreen() async {
    final XFile? capturedPhoto = await Navigator.push<XFile>(
      context,
      BubbleMorphModalRoute(
        page: CameraScreen(initialFilter: _cameraFilterPreset),
      ),
    );

    if (capturedPhoto != null && mounted) {
      if (_selectedImages.length >= _maxPhotos) {
        UiHelpers.showError(context, 'You can select up to $_maxPhotos photos.');
        return;
      }
      setState(() {
        _selectedImages.add(capturedPhoto);
        _assetIdBySelectedPath[capturedPhoto.path] = capturedPhoto.path;
        _originalPathBySelectedPath[capturedPhoto.path] = capturedPhoto.path;
        _currentHeroIndex = _selectedImages.length - 1;
        if (_heroPageController.hasClients) {
          _heroPageController.jumpToPage(_currentHeroIndex);
        }
      });
      // Refresh device gallery assets so the newly taken photo shows in the gallery grid
      _loadDeviceGallery(requestPermissionIfNotGranted: false);
    }
  }

  Future<void> _loadDeviceGallery({bool requestPermissionIfNotGranted = false}) async {
    setState(() => _isLoadingGallery = true);
    try {
      // Check permission state silently first (does not launch system gallery/dialog)
      final PermissionState currentPs = await PhotoManager.getPermissionState(
        requestOption: const PermissionRequestOption(
          androidPermission: AndroidPermission(
            type: RequestType.image,
            mediaLocation: false,
          ),
        ),
      );

      PermissionState ps = currentPs;
      if (!currentPs.isAuth && !currentPs.hasAccess && requestPermissionIfNotGranted) {
        ps = await PhotoManager.requestPermissionExtend();
      }

      if (ps.isAuth || ps.hasAccess) {
        _hasGalleryPermission = true;
        final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
          onlyAll: true,
          type: RequestType.image,
        );
        if (albums.isNotEmpty) {
          final List<AssetEntity> media = await albums[0].getAssetListPaged(page: 0, size: 80);
          if (mounted) {
            setState(() {
              _galleryAssets = media;
            });
            // Do NOT auto-select any gallery photo: user starts with empty state
          }
        }
      } else {
        _hasGalleryPermission = false;
      }
    } catch (e) {
      debugPrint('Gallery error: $e');
      _hasGalleryPermission = false;
    } finally {
      if (mounted) setState(() => _isLoadingGallery = false);
    }
  }

  Future<void> _onAssetTapped(AssetEntity asset) async {
    final existingIndex = _findSelectedIndexForAsset(asset);

    if (existingIndex >= 0) {
      // Instant Deselect: no async file loading needed!
      SafeHaptics.selectionClick();
      setState(() {
        final removed = _selectedImages.removeAt(existingIndex);
        _assetIdBySelectedPath.remove(removed.path);
        _originalPathBySelectedPath.remove(removed.path);
        if (_selectedImages.isNotEmpty) {
          _currentHeroIndex = _currentHeroIndex.clamp(0, _selectedImages.length - 1);
          if (_heroPageController.hasClients) {
            _heroPageController.jumpToPage(_currentHeroIndex);
          }
        }
      });
      return;
    }

    if (_selectedImages.length >= _maxPhotos) {
      UiHelpers.showError(context, 'Maximum $_maxPhotos photos allowed.');
      return;
    }

    SafeHaptics.selectionClick();

    // Check cached edited version first
    final cachedEdited = _editedPhotosCache[asset.id];
    if (cachedEdited != null) {
      setState(() {
        _selectedImages.add(cachedEdited);
        _assetIdBySelectedPath[cachedEdited.path] = asset.id;
        _originalPathBySelectedPath[cachedEdited.path] = cachedEdited.path;
        _currentHeroIndex = _selectedImages.length - 1;
        if (_heroPageController.hasClients) {
          _heroPageController.jumpToPage(_currentHeroIndex);
        }
      });
      return;
    }

    try {
      final file = await asset.file;
      if (file == null || !mounted) return;

      final filePath = file.path;
      final xFileToUse = XFile(filePath);

      setState(() {
        _selectedImages.add(xFileToUse);
        _assetIdBySelectedPath[xFileToUse.path] = asset.id;
        _originalPathBySelectedPath[xFileToUse.path] = filePath;
        _currentHeroIndex = _selectedImages.length - 1;
        if (_heroPageController.hasClients) {
          _heroPageController.jumpToPage(_currentHeroIndex);
        }
      });
    } catch (e) {
      if (mounted) UiHelpers.showError(context, 'Unable to load photo.');
    }
  }

  Future<void> _pickFromSystemPicker() async {
    if (_selectedImages.length >= _maxPhotos) {
      UiHelpers.showError(context, 'Maximum $_maxPhotos photos allowed.');
      return;
    }

    try {
      final List<XFile> photos = await _picker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (photos.isNotEmpty && mounted) {
        final remainingSlots = _maxPhotos - _selectedImages.length;
        final toAdd = photos.take(remainingSlots).toList();

        setState(() {
          for (final p in toAdd) {
            _selectedImages.add(p);
            _assetIdBySelectedPath[p.path] = p.path;
            _originalPathBySelectedPath[p.path] = p.path;
          }
          _currentHeroIndex = _selectedImages.length - 1;
          if (_heroPageController.hasClients) {
            _heroPageController.jumpToPage(_currentHeroIndex);
          }
        });
      }
    } catch (_) {
      if (mounted) UiHelpers.showError(context, 'Gallery access failed.');
    }
  }

  Future<void> _fetchUserBubbles() async {
    try {
      final profile = ref.read(profileControllerProvider).value;
      if (profile != null && profile['id'] != null) {
        final res = await ApiClient.dio.get('/bubbles/user/${profile['id']}');
        if (mounted && res.data is List) {
          setState(() {
            _userBubbles = res.data as List;
          });
        }
      }
    } catch (_) {}
  }

  void _goToCaptionStep() {
    if (_selectedImages.isEmpty) {
      UiHelpers.showError(context, 'Please select at least 1 photo.');
      return;
    }
    setState(() => _currentStep = 1);
  }

  Future<void> _handlePublish() async {
    if (_selectedImages.isEmpty) {
      UiHelpers.showError(context, 'Please add at least one photo.');
      return;
    }

    setState(() {
      _isLoading = true;
      _uploadStatus = 'Preparing media...';
    });

    try {
      final dataSource = ref.read(postDataSourceProvider);
      final List<Map<String, String>> uploadedMedia = [];

      for (int i = 0; i < _selectedImages.length; i++) {
        if (!mounted) return;
        setState(() {
          _uploadStatus = 'Uploading photo ${i + 1} of ${_selectedImages.length}...';
        });

        final image = _selectedImages[i];
        final url = await dataSource.uploadMedia(image.path);
        uploadedMedia.add({
          'media_type': 'IMAGE',
          'url': url,
        });
      }

      if (!mounted) return;
      setState(() => _uploadStatus = 'Publishing post...');

      final content = _contentController.text.trim();
      final bubbleIds = _selectedBubbleId != null ? [_selectedBubbleId!] : <String>[];

      await dataSource.createPost(
        content: content,
        bubbleIds: bubbleIds,
        bubbleId: _selectedBubbleId,
        media: uploadedMedia,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        UiHelpers.showSuccess(context, 'Post published successfully!');
        ref.read(feedControllerProvider.notifier).refresh();
        _safePop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        UiHelpers.showError(context, e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  void _safePop() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else if (context.canPop()) {
      context.pop();
    }
  }

  // -------------------------------------------------------------
  // STEP 0: INSTAGRAM SPLIT-SCREEN MEDIA PICKER
  // -------------------------------------------------------------

  /// Top Half: Large Active Photo Preview with swipe carousel & empty state
  /// Top Half: Large Active Photo Preview with inline reordering & swipe carousel
  /// Top Half: Large Active Photo Preview with inline reordering & swipe carousel
  Widget _buildActiveHeroPreview() {
    return AspectRatio(
      aspectRatio: 1.0, // Instagram standard square preview
      child: Container(
        color: Colors.black,
        child: AnimatedBuilder(
          animation: _morphAnimation,
          builder: (context, _) {
            final t = _morphAnimation.value;

            // If completely in standard view and not transitioning
            if (!_isReorderMode && t == 0.0) {
              return _buildStandardHeroView();
            }

            // If completely in reorder view and not transitioning
            if (_isReorderMode && t == 1.0) {
              return _buildInlineReorderView();
            }

            // True morph animation: scale down standard hero view and scale up reorder tray
            return Stack(
              fit: StackFit.expand,
              children: [
                Opacity(
                  opacity: (1.0 - t).clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: 1.0 - (0.28 * t),
                    child: _buildStandardHeroView(),
                  ),
                ),
                Opacity(
                  opacity: t.clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: 0.85 + (0.15 * t),
                    child: _buildInlineReorderView(),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Inline Reorder Mode: Photos decrease in size in the same square section,
  /// displayed in a horizontal reorderable strip where users drag and move them.
  Widget _buildInlineReorderView() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onDoubleTap: () {
        SafeHaptics.mediumImpact();
        _exitReorderMode();
      },
      child: Container(
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background subtle tint (double tap anywhere in empty space returns to normal mode)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onDoubleTap: () {
                  SafeHaptics.mediumImpact();
                  _exitReorderMode();
                },
                child: Container(
                  color: Colors.black.withValues(alpha: 0.95),
                ),
              ),
            ),

            // Top Header: Minimal "REORDER" indicator & "Done" Button
            Positioned(
              top: 12,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.swap_horiz_rounded, color: Colors.white, size: 15),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'REORDER',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: _exitReorderMode,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        'Done',
                        style: TextStyle(
                          color: LiquidGlassTheme.primaryTextColor(context),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Center: Shrunk photos (single tap to select, double tap to normal mode, swipe up to remove)
            Center(
              child: SizedBox(
                height: 230,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onDoubleTap: () {
                    SafeHaptics.mediumImpact();
                    _exitReorderMode();
                  },
                  child: ReorderableListView.builder(
                    buildDefaultDragHandles: false,
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _selectedImages.length,
                    onReorderStart: (_) => SafeHaptics.selectionClick(),
                    onReorderItem: (int oldIndex, int newIndex) {
                      SafeHaptics.mediumImpact();
                      setState(() {
                        final item = _selectedImages.removeAt(oldIndex);
                        _selectedImages.insert(newIndex, item);
                        _currentHeroIndex = newIndex;
                      });
                    },
                    itemBuilder: (context, index) {
                      final img = _selectedImages[index];
                      final isCurrent = index == _currentHeroIndex;

                      return FastReorderableDragListener(
                        key: ValueKey('drag_${img.path}'),
                        delay: const Duration(milliseconds: 120),
                        index: index,
                        child: _SlideUpPhotoCard(
                          key: ValueKey('card_${img.path}'),
                          file: img,
                          index: index,
                          isSelected: isCurrent,
                          onTap: () {
                            // Single tap selects this photo (highlights it and stays in reorder mode)
                            SafeHaptics.selectionClick();
                            setState(() => _currentHeroIndex = index);
                          },
                          onDoubleTap: () {
                            // Double tap on any photo (selected or non-selected) takes you to normal mode with that photo
                            SafeHaptics.mediumImpact();
                            setState(() => _currentHeroIndex = index);
                            _exitReorderMode();
                          },
                          onRemove: () => _removePhotoAt(index),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            // Bottom Hint: minimal swipe up reminder
            Positioned(
              bottom: 10,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'Swipe up to remove',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Standard Hero Preview: 1:1 view with swipe carousel
  Widget _buildStandardHeroView() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Preview Image Carousel or Empty State Placeholder
        if (_selectedImages.isNotEmpty)
          PageView.builder(
            controller: _heroPageController,
            itemCount: _selectedImages.length,
            onPageChanged: (index) {
              setState(() {
                _currentHeroIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final img = _selectedImages[index];
              return GestureDetector(
                onLongPress: _enterReorderMode,
                child: kIsWeb
                    ? Image.network(img.path, fit: _previewFit)
                    : Image.file(File(img.path), fit: _previewFit),
              );
            },
          )
        else
          const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.photo_library_outlined, size: 60, color: Colors.white38),
                SizedBox(height: 10),
                Text(
                  'Select a photo from below',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Choose from your gallery or capture from camera',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ),

        // Top Right: Multi-photo Counter & Reorder Button (e.g. "1/3")
        if (_selectedImages.length > 1)
          Positioned(
            top: 12,
            right: 12,
            child: GestureDetector(
              onTap: _enterReorderMode,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white24, width: 0.8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.swap_horiz_rounded, color: Colors.white70, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${_currentHeroIndex + 1}/${_selectedImages.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Carousel Pagination Dots (when multiple photos are selected)
        if (_selectedImages.length > 1)
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _enterReorderMode,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(_selectedImages.length, (dotIdx) {
                      final isActive = dotIdx == _currentHeroIndex;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2.5),
                        width: isActive ? 7 : 5,
                        height: isActive ? 7 : 5,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isActive ? Colors.white : Colors.white38,
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),

        // Bottom Left: Aspect ratio toggle (< >)
        if (_selectedImages.isNotEmpty)
          Positioned(
            bottom: 12,
            left: 12,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _previewFit = _previewFit == BoxFit.cover ? BoxFit.contain : BoxFit.cover;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _previewFit == BoxFit.cover ? Icons.unfold_more : Icons.unfold_less,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),

        // Bottom Center-Left: EDIT PHOTO button (edits the currently viewed photo in carousel)
        if (_selectedImages.isNotEmpty)
          Positioned(
            bottom: 12,
            left: 54,
            child: GestureDetector(
              onTap: () => _openPhotoEditor(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white24, width: 0.8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_fix_high_rounded, color: Colors.white, size: 14),
                    SizedBox(width: 5),
                    Text(
                      'EDIT',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Middle Bar: Album header and file picker shortcut
  Widget _buildAlbumHeaderBar() {
    return LiquidGlassContainer(
      borderRadius: BorderRadius.zero,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      border: Border(
        top: BorderSide(
          color: LiquidGlassTheme.specularBorderColor(context),
          width: 0.8,
        ),
        bottom: BorderSide(
          color: LiquidGlassTheme.specularBorderColor(context),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          LiquidGlassPill(
            label: 'Recents',
            icon: const Icon(PhosphorIconsRegular.caretDown, size: 14),
            onTap: () {},
          ),
          Row(
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(PhosphorIconsRegular.camera, size: 20),
                tooltip: 'Camera',
                onPressed: _openCameraScreen,
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(PhosphorIconsRegular.folderOpen, size: 20),
                tooltip: 'Browse Files',
                onPressed: _pickFromSystemPicker,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Helper to render a constant 1:1 square gallery tile
  Widget _buildGalleryTile(AssetEntity asset) {
    final selectedIndex = _findSelectedIndexForAsset(asset);
    final isSelected = selectedIndex >= 0;
    final isCurrentPreview = isSelected && selectedIndex == _currentHeroIndex;

    return GestureDetector(
      onTap: () => _onAssetTapped(asset),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Fast cached Thumbnail with GPU acceleration
          AssetEntityImage(
            asset,
            isOriginal: false,
            thumbnailSize: const ThumbnailSize.square(200),
            thumbnailFormat: ThumbnailFormat.jpeg,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[850]),
          ),

          // Focused overlay with iridescent bubble tint
          if (isSelected || isCurrentPreview)
            Container(
              decoration: BoxDecoration(
                border: isSelected
                    ? Border.all(color: LiquidGlassTheme.bubbleBlue, width: 2.5)
                    : null,
                gradient: LiquidGlassTheme.selectionOverlayGradient(
                  opacity: isCurrentPreview ? 0.28 : 0.20,
                ),
              ),
            ),

          // Instagram Numbered Selection Badge (①, ②, ③...) with 3-color Bubble gradient
          Positioned(
            top: 5,
            right: 5,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                gradient: isSelected ? LiquidGlassTheme.bubbleBlueGradient : null,
                color: isSelected ? null : Colors.black.withValues(alpha: 0.35),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: LiquidGlassTheme.bubbleBlue.withValues(alpha: 0.18),
                          blurRadius: 4,
                        ),
                      ]
                    : null,
              ),
              child: isSelected
                  ? Center(
                      child: Text(
                        '${selectedIndex + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  /// The Camera Tile sized in a 9:16 aspect ratio showing live camera feed
  Widget _buildCameraTile({required double width, required double height}) {
    final previewSize = _cameraController?.value.previewSize;
    // Mobile camera sensors report previewSize in landscape (width > height)
    final double previewW = previewSize != null
        ? (previewSize.width > previewSize.height ? previewSize.height : previewSize.width)
        : width;
    final double previewH = previewSize != null
        ? (previewSize.width > previewSize.height ? previewSize.width : previewSize.height)
        : height;

    return GestureDetector(
      onTap: _openCameraScreen,
      child: Container(
        width: width,
        height: height,
        color: Colors.black,
        child: ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Real Camera Preview with Mathematical GPU Filter Matrix
              if (_isCameraReady &&
                  _cameraController != null &&
                  _cameraController!.value.isInitialized)
                ColorFiltered(
                  colorFilter: ColorFilter.matrix(_cameraFilterPreset.matrix),
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: previewW,
                      height: previewH,
                      child: CameraPreview(_cameraController!),
                    ),
                  ),
                )
              else if (_isInitializingCamera)
                const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54),
                  ),
                )
              else
                const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.camera_alt_rounded, color: Colors.white54, size: 28),
                      SizedBox(height: 4),
                      Text(
                        'Tap to start',
                        style: TextStyle(color: Colors.white38, fontSize: 10),
                      ),
                    ],
                  ),
                ),

              // Instagram subtle center camera icon overlay (when live)
              if (_isCameraReady)
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),

              // Top Right: Live Filter Chip Switcher (Tap to cycle math filters)
              Positioned(
                top: 6,
                right: 6,
                child: GestureDetector(
                  onTap: _cycleCameraFilter,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _cameraFilterPreset.id != 'normal'
                            ? Colors.white.withValues(alpha: 0.6)
                            : Colors.white24,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _cameraFilterPreset.icon,
                          size: 10,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                          _cameraFilterPreset.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Bottom Half: Media Grid with a Bigger Phone-Ratio Camera Tile + Adjacent & Continuous Gallery
  Widget _buildPhotoGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const double spacing = 1.5;
        final double totalWidth = constraints.maxWidth;
        // 3-column system so column width matches between camera and photo columns
        final double columnWidth = (totalWidth - (spacing * 2)) / 3.0;
        final double cameraHeight = columnWidth * (16.0 / 9.0); // 9:16 phone ratio
        final double photoHeight = (cameraHeight - spacing) / 2.0; // half of camera tile height

        // First 4 gallery photos go beside the camera in Columns 2 & 3
        final firstBatch = _galleryAssets.take(4).toList();
        final remainingAssets = _galleryAssets.skip(4).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Featured Top Row: Camera Tile (9:16) + 2 columns of photos (each photo half the camera height, same width)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0),
              child: SizedBox(
                height: cameraHeight,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Column 1: Phone-Ratio (9:16) Camera Tile
                    _buildCameraTile(width: columnWidth, height: cameraHeight),
                    const SizedBox(width: spacing),

                    // Column 2: 2 photos stacked (each with same width as camera, half camera height)
                    SizedBox(
                      width: columnWidth,
                      height: cameraHeight,
                      child: Column(
                        children: [
                          SizedBox(
                            width: columnWidth,
                            height: photoHeight,
                            child: firstBatch.isNotEmpty
                                ? _buildGalleryTile(firstBatch[0])
                                : Container(color: Colors.grey[900]),
                          ),
                          const SizedBox(height: spacing),
                          SizedBox(
                            width: columnWidth,
                            height: photoHeight,
                            child: firstBatch.length > 1
                                ? _buildGalleryTile(firstBatch[1])
                                : Container(color: Colors.grey[900]),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: spacing),

                    // Column 3: 2 photos stacked (each with same width as camera, half camera height)
                    SizedBox(
                      width: columnWidth,
                      height: cameraHeight,
                      child: Column(
                        children: [
                          SizedBox(
                            width: columnWidth,
                            height: photoHeight,
                            child: firstBatch.length > 2
                                ? _buildGalleryTile(firstBatch[2])
                                : Container(color: Colors.grey[900]),
                          ),
                          const SizedBox(height: spacing),
                          SizedBox(
                            width: columnWidth,
                            height: photoHeight,
                            child: firstBatch.length > 3
                                ? _buildGalleryTile(firstBatch[3])
                                : Container(color: Colors.grey[900]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: spacing),

            // If user hasn't granted gallery permission yet and gallery is empty
            if (!_hasGalleryPermission && _galleryAssets.isEmpty)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
                ),
                child: Column(
                  children: [
                    Icon(Icons.photo_library_outlined, size: 38, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 10),
                    Text(
                      'Access Device Photos',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: LiquidGlassTheme.textPrimary(context)),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Allow photo access to choose and upload images directly from your gallery.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: LiquidGlassTheme.textSecondary(context), fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _loadDeviceGallery(requestPermissionIfNotGranted: true),
                          icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                          label: const Text('Allow Access'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: LiquidGlassTheme.primaryTextColor(context),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: _pickFromSystemPicker,
                          icon: const Icon(Icons.folder_open_outlined, size: 18),
                          label: const Text('Browse'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            // 2. Remaining gallery photos continuing in 3-column grid (same photo width and height)
            if (remainingAssets.isNotEmpty)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: spacing,
                  mainAxisSpacing: spacing,
                  childAspectRatio: columnWidth / photoHeight,
                ),
                itemCount: remainingAssets.length,
                itemBuilder: (context, index) => _buildGalleryTile(remainingAssets[index]),
              ),
          ],
        );
      },
    );
  }

  Widget _buildStep0MediaPicker() {
    final bool canProceed = _selectedImages.isNotEmpty;

    return Scaffold(
      appBar: LiquidGlassAppBar(
        leading: IconButton(
          icon: const Icon(PhosphorIconsRegular.caretLeft),
          onPressed: _safePop,
        ),
        title: const Text('New Post'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: LiquidGlassButton(
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              label: 'Next',
              onPressed: canProceed ? _goToCaptionStep : null,
            ),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // 1. Top Half: Large Active Photo Preview
          SliverToBoxAdapter(child: _buildActiveHeroPreview()),

          // 2. Middle Bar: Recents ▾ & Shortcuts
          SliverToBoxAdapter(child: _buildAlbumHeaderBar()),

          // 3. Bottom Half: 4-Column Photo Grid (Camera #1 + Gallery)
          if (_isLoadingGallery)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            )
          else
            SliverToBoxAdapter(child: _buildPhotoGrid()),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // STEP 1: CAPTION & SHARE (INSTAGRAM SCREEN 2)
  // -------------------------------------------------------------

  Widget _buildStep1Caption() {
    final profile = ref.watch(profileControllerProvider).value;
    final username = profile?['username'] ?? 'You';
    final profilePic = profile?['profile_picture_url'] ?? '';

    return Scaffold(
      appBar: LiquidGlassAppBar(
        leading: IconButton(
          icon: const Icon(PhosphorIconsRegular.caretLeft),
          onPressed: _isLoading ? null : () => setState(() => _currentStep = 0),
        ),
        title: const Text('New Post'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: LiquidGlassButton(
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              label: 'Share',
              isLoading: _isLoading,
              onPressed: _isLoading ? null : _handlePublish,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Top Row: Selected photo thumbnail + Caption textfield
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Square thumbnail with multi-photo count badge & edit shortcut
                      if (_selectedImages.isNotEmpty)
                        GestureDetector(
                          onTap: () => _openPhotoEditor(_selectedImages[0]),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: SizedBox(
                              width: 68,
                              height: 68,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  kIsWeb
                                      ? Image.network(_selectedImages[0].path, fit: BoxFit.cover)
                                      : Image.file(File(_selectedImages[0].path), fit: BoxFit.cover),
                                  // Edit icon overlay in top-left
                                  Positioned(
                                    top: 3,
                                    left: 3,
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.6),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.edit_rounded, color: Colors.white, size: 10),
                                    ),
                                  ),
                                  if (_selectedImages.length > 1)
                                    Positioned(
                                      bottom: 3,
                                      right: 3,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.75),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.copy_rounded, color: Colors.white, size: 10),
                                            const SizedBox(width: 2),
                                            Text(
                                              '${_selectedImages.length}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(width: 14),

                      // Caption input
                      Expanded(
                        child: TextField(
                          controller: _contentController,
                          maxLines: 4,
                          autofocus: true,
                          decoration: const InputDecoration(
                            hintText: 'Write a caption...',
                            hintStyle: TextStyle(color: Colors.grey),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),

                // 2. Audience / Bubble Destination row
                ListTile(
                  leading: UserAvatar(imageUrl: profilePic, radius: 16),
                  title: Text(
                    'Sharing as $username',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  subtitle: _userBubbles.isNotEmpty
                      ? DropdownButtonHideUnderline(
                          child: DropdownButton<String?>(
                            value: _selectedBubbleId,
                            isDense: true,
                            items: [
                              DropdownMenuItem<String?>(
                                value: null,
                                child: Text('Personal Profile',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                              ),
                              ..._userBubbles.map((b) => DropdownMenuItem<String?>(
                                    value: b['id']?.toString(),
                                    child: Text(
                                      'Bubble: ${b['name']}',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  )),
                            ],
                            onChanged: _isLoading
                                ? null
                                : (val) => setState(() => _selectedBubbleId = val),
                          ),
                        )
                      : const Text('Posting to Personal Profile', style: TextStyle(fontSize: 12)),
                ),

                const Divider(height: 1),

                // 3. Photo Carousel strip overview
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                        '${_selectedImages.length} Photo${_selectedImages.length == 1 ? '' : 's'} Selected',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_selectedImages.length > 1) ...[
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _currentStep = 0;
                                  _isReorderMode = true;
                                });
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.swap_horiz_rounded, size: 16, color: Theme.of(context).colorScheme.primary),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Reorder',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                          ],
                          GestureDetector(
                            onTap: () => setState(() => _currentStep = 0),
                            child: Text(
                              'Edit Selection',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(
                  height: 70,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: _selectedImages.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final img = _selectedImages[index];
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _currentStep = 0;
                            _currentHeroIndex = index;
                            _isReorderMode = true;
                          });
                        },
                        onLongPress: () {
                          setState(() {
                            _currentStep = 0;
                            _currentHeroIndex = index;
                            _isReorderMode = true;
                          });
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: AspectRatio(
                            aspectRatio: 1.0,
                            child: kIsWeb
                                ? Image.network(img.path, fit: BoxFit.cover)
                                : Image.file(File(img.path), fit: BoxFit.cover),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 36),

                // 4. Primary Share button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: LiquidGlassButton(
                    height: 50,
                    label: 'Share Post',
                    icon: const Icon(PhosphorIconsFill.paperPlaneTilt, size: 18, color: Colors.white),
                    isLoading: _isLoading,
                    onPressed: _isLoading ? null : _handlePublish,
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),

          // Uploading Modal Progress Overlay
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: Center(
                  child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 20),
                          Text(
                            _uploadStatus,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Please keep the app open.',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentStep == 0) {
      return _buildStep0MediaPicker();
    } else {
      return _buildStep1Caption();
    }
  }
}
