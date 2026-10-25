import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:share_plus/share_plus.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/image_filter_math.dart';
import '../../../../core/utils/ui_helpers.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/providers/dynamic_dock_provider.dart';
import '../../../../shared/widgets/liquid_glass.dart';
import '../../../../core/transitions/bubble_page_transitions.dart';
import 'camera_screen.dart';
import 'photo_detail_viewer_screen.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

class GalleryScreen extends ConsumerStatefulWidget {
  const GalleryScreen({super.key});

  @override
  ConsumerState<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends ConsumerState<GalleryScreen>
    with WidgetsBindingObserver {
  // Device Albums & Media
  List<AssetPathEntity> _albums = [];
  AssetPathEntity? _currentAlbum;
  List<AssetEntity> _assets = [];
  bool _isLoading = true;
  bool _hasPermission = false;

  // Multi-Selection State
  final Set<AssetEntity> _selectedAssets = {};
  bool get _isSelectionMode => _selectedAssets.isNotEmpty;

  final FilterPreset _cameraFilter = ImageFilterMath.presets[0];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadGallery(requestPermission: true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_selectedAssets.isNotEmpty) {
      ref.read(dynamicDockProvider.notifier).resetToNavigation();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadGallery(requestPermission: false);
    }
  }

  void _syncSelectionDock() {
    if (_selectedAssets.isEmpty) {
      ref.read(dynamicDockProvider.notifier).resetToNavigation();
      return;
    }

    final count = _selectedAssets.length;
    ref
        .read(dynamicDockProvider.notifier)
        .setSelectionMode(
          count: count,
          title: '$count Selected',
          onCancel: () {
            setState(() {
              _selectedAssets.clear();
            });
          },
          actions: [
            DynamicDockAction(
              icon: PhosphorIconsRegular.shareFat,
              label: 'Share',
              onTap: _shareSelectedAssets,
            ),
            DynamicDockAction(
              icon: PhosphorIconsRegular.trash,
              label: 'Delete',
              isDestructive: true,
              onTap: _deleteSelectedAssets,
            ),
            DynamicDockAction(
              icon: PhosphorIconsRegular.paperPlaneRight,
              label: 'Post ($count)',
              isPrimary: true,
              onTap: _goToPostPage,
            ),
          ],
          popouts: [
            DynamicDockPopoutItem(
              icon: PhosphorIconsRegular.checkSquare,
              label: 'Select All',
              onTap: _selectAllAssets,
            ),
          ],
        );
  }

  void _selectAllAssets() {
    SafeHaptics.selectionClick();
    setState(() {
      _selectedAssets.addAll(_assets);
    });
    _syncSelectionDock();
  }

  Future<void> _loadGallery({bool requestPermission = false}) async {
    setState(() => _isLoading = true);
    try {
      PermissionState ps = await PhotoManager.getPermissionState(
        requestOption: const PermissionRequestOption(
          androidPermission: AndroidPermission(
            type: RequestType.image,
            mediaLocation: false,
          ),
        ),
      );

      if (!ps.isAuth && !ps.hasAccess && requestPermission) {
        ps = await PhotoManager.requestPermissionExtend();
      }

      if (ps.isAuth || ps.hasAccess) {
        _hasPermission = true;
        final albums = await PhotoManager.getAssetPathList(
          onlyAll: false,
          type: RequestType.image,
        );

        if (albums.isNotEmpty) {
          _albums = albums;
          _currentAlbum = _albums[0];
          final media = await _currentAlbum!.getAssetListPaged(
            page: 0,
            size: 48,
          );
          if (mounted) {
            setState(() {
              _assets = media;
            });
          }
        }
      } else {
        _hasPermission = false;
      }
    } catch (e) {
      debugPrint('Gallery load error: $e');
      _hasPermission = false;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _switchAlbum(AssetPathEntity album) async {
    setState(() {
      _currentAlbum = album;
      _isLoading = true;
      _selectedAssets.clear();
    });
    _syncSelectionDock();
    try {
      final media = await album.getAssetListPaged(page: 0, size: 48);
      if (mounted) {
        setState(() {
          _assets = media;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _toggleSelection(AssetEntity asset) {
    SafeHaptics.selectionClick();
    setState(() {
      if (_selectedAssets.contains(asset)) {
        _selectedAssets.remove(asset);
      } else {
        _selectedAssets.add(asset);
      }
    });
    _syncSelectionDock();
  }

  Future<void> _openPhotoViewer(AssetEntity asset) async {
    try {
      await Navigator.of(context, rootNavigator: true).push(
        BubblePhotoMorphRoute(
          page: PhotoDetailViewerScreen(
            asset: asset,
            onModified: () => _loadGallery(requestPermission: false),
          ),
        ),
      );
    } finally {
      if (mounted) {
        _syncSelectionDock();
      }
    }
  }

  Future<void> _openCamera() async {
    final XFile? captured = await Navigator.of(context, rootNavigator: true)
        .push<XFile>(
          BubbleMorphModalRoute(
            page: CameraScreen(initialFilter: _cameraFilter),
          ),
        );
    if (captured != null && mounted) {
      await _loadGallery(requestPermission: false);
    }
  }

  /// Opens CreatePostScreen on rootNavigator to hide the bottom navigation bar.
  /// If photos are selected, pre-populates them.
  /// If no photo is selected, opens empty creator studio where user can pick & create.
  Future<void> _goToPostPage() async {
    final List<XFile> initialFiles = [];
    if (_selectedAssets.isNotEmpty) {
      try {
        final files = await Future.wait(_selectedAssets.map((a) => a.file));
        for (final file in files) {
          if (file != null) {
            initialFiles.add(XFile(file.path));
          }
        }
      } catch (e) {
        if (mounted) {
          UiHelpers.showError(context, 'Failed to prepare photos: $e');
        }
        return;
      }
    }

    if (!mounted) return;
    ref.read(dynamicDockProvider.notifier).resetToNavigation();
    context.push('/create', extra: initialFiles);
  }

  Future<void> _deleteSelectedAssets() async {
    if (_selectedAssets.isEmpty) return;
    final count = _selectedAssets.length;
    final confirmed = await showBubbleDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete $count photo${count > 1 ? 's' : ''}?'),
        content: const Text('These photos will be deleted from your device.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final ids = _selectedAssets.map((a) => a.id).toList();
        final deletedIds = await PhotoManager.editor.deleteWithIds(ids);
        if (deletedIds.isNotEmpty) {
          setState(() {
            _assets.removeWhere((a) => deletedIds.contains(a.id));
            _selectedAssets.clear();
          });
          _syncSelectionDock();
          if (mounted) {
            UiHelpers.showSuccess(
              context,
              'Deleted $count photo${count > 1 ? 's' : ''}',
            );
          }
        }
      } catch (e) {
        if (mounted) UiHelpers.showError(context, 'Delete failed: $e');
      }
    }
  }

  Future<void> _shareSelectedAssets() async {
    if (_selectedAssets.isEmpty) return;
    try {
      final List<XFile> xFiles = [];
      for (final asset in _selectedAssets) {
        final file = await asset.file;
        if (file != null) {
          xFiles.add(XFile(file.path));
        }
      }
      if (xFiles.isNotEmpty) {
        await SharePlus.instance.share(
          ShareParams(files: xFiles, text: 'Shared from Bubble Gallery'),
        );
      }
    } catch (e) {
      if (mounted) UiHelpers.showError(context, 'Share failed: $e');
    }
  }

  void _showAlbumPickerSheet() {
    if (_albums.isEmpty) return;
    showBubbleModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: LiquidGlassTheme.glassShadows(ctx, blur: 24),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LiquidGlassTheme.glassGradient(ctx),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                  border: Border(
                    top: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.18)
                          : Colors.white.withValues(alpha: 0.85),
                      width: 1.2,
                    ),
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Handle pill
                      Center(
                        child: Container(
                          margin: const EdgeInsets.only(top: 10, bottom: 8),
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white24 : Colors.black12,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18.0,
                          vertical: 8.0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Albums',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: LiquidGlassTheme.textPrimary(ctx),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.pop(ctx),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white10
                                      : Colors.black.withValues(alpha: 0.05),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  PhosphorIconsRegular.x,
                                  size: 16,
                                  color: LiquidGlassTheme.textPrimary(ctx),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Divider(
                        height: 1,
                        color: isDark
                            ? Colors.white10
                            : Colors.black.withValues(alpha: 0.05),
                      ),
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _albums.length,
                          itemBuilder: (ctx, i) {
                            final album = _albums[i];
                            final isSelected = album.id == _currentAlbum?.id;
                            return FutureBuilder<int>(
                              future: album.assetCountAsync,
                              builder: (ctx, countSnap) {
                                final count = countSnap.data ?? 0;
                                return ListTile(
                                  leading: Icon(
                                    isSelected
                                        ? PhosphorIconsFill.folder
                                        : PhosphorIconsRegular.folder,
                                    color: isSelected
                                        ? (isDark
                                              ? Colors.white
                                              : const Color(0xFF18181B))
                                        : LiquidGlassTheme.textSecondary(ctx),
                                  ),
                                  title: Text(
                                    album.name,
                                    style: TextStyle(
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? (isDark
                                                ? Colors.white
                                                : const Color(0xFF18181B))
                                          : LiquidGlassTheme.textPrimary(ctx),
                                    ),
                                  ),
                                  subtitle: Text(
                                    '$count photo${count == 1 ? '' : 's'}',
                                    style: TextStyle(
                                      color: LiquidGlassTheme.textSecondary(
                                        ctx,
                                      ),
                                    ),
                                  ),
                                  trailing: isSelected
                                      ? Icon(
                                          PhosphorIconsFill.checkCircle,
                                          color: isDark
                                              ? Colors.white
                                              : const Color(0xFF18181B),
                                          size: 20,
                                        )
                                      : null,
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    _switchAlbum(album);
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Subheader Bar: Album selector & total photo count
          _buildSubHeaderBar(),

          // Photos Grid
          Expanded(child: _buildGridContent()),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final canGoBack = Navigator.of(context).canPop() || context.canPop();
    return LiquidGlassAppBar(
      automaticallyImplyLeading: false,
      leading: canGoBack ? const BubbleBackButton() : null,
      centerTitle: false,
      title: Text(
        'Gallery',
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 22,
          letterSpacing: -0.4,
          color: LiquidGlassTheme.textPrimary(context),
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            PhosphorIconsRegular.camera,
            size: 22,
            color: LiquidGlassTheme.textPrimary(context),
          ),
          tooltip: 'Camera',
          onPressed: _openCamera,
        ),
        Padding(
          padding: const EdgeInsets.only(right: 14.0, left: 6.0),
          child: LiquidGlassButton(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            onPressed: _goToPostPage,
            icon: Icon(
              PhosphorIconsRegular.plus,
              size: 16,
              color: LiquidGlassTheme.textPrimary(context),
            ),
            label: 'Post',
            isPrimary: true,
          ),
        ),
      ],
    );
  }

  Widget _buildSubHeaderBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          LiquidGlassPill(
            onTap: _showAlbumPickerSheet,
            customContent: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    _currentAlbum?.name ?? 'Recents',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: LiquidGlassTheme.textPrimary(context),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  PhosphorIconsRegular.caretDown,
                  size: 15,
                  color: LiquidGlassTheme.textSecondary(context),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              '${_assets.length} photos',
              style: TextStyle(
                color: LiquidGlassTheme.textSecondary(context),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_hasPermission) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.photo_library_outlined,
              size: 60,
              color: Colors.grey,
            ),
            const SizedBox(height: 12),
            const Text(
              'Gallery access required',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => _loadGallery(requestPermission: true),
              child: const Text('Grant Permission'),
            ),
          ],
        ),
      );
    }

    // Grid: All gallery assets without camera tile
    return GridView.builder(
      padding: const EdgeInsets.all(2),
      scrollCacheExtent: const ScrollCacheExtent.viewport(
        2.0,
      ), // Preload images beyond screen bounds
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        childAspectRatio: 1.0,
      ),
      itemCount: _assets.length,
      itemBuilder: (context, index) {
        final asset = _assets[index];
        return _buildAssetTile(asset);
      },
    );
  }

  Widget _buildAssetTile(AssetEntity asset) {
    final isSelected = _selectedAssets.contains(asset);

    return GestureDetector(
      onTap: () {
        if (_isSelectionMode) {
          _toggleSelection(asset);
        } else {
          _openPhotoViewer(asset);
        }
      },
      onLongPress: () => _toggleSelection(asset),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Thumbnail with Hero morph animation
          Hero(
            tag: 'gallery_asset_${asset.id}',
            child: _GalleryThumbnailWidget(asset: asset),
          ),

          // Highlight border & iridescent bubble overlay if selected
          if (isSelected)
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: LiquidGlassTheme.bubbleBlue,
                  width: 2.8,
                ),
                gradient: LiquidGlassTheme.selectionOverlayGradient(
                  opacity: 0.25,
                ),
              ),
            ),

          // Selection badge circle (top right) - ONLY shown when selection mode is active
          if (_isSelectionMode)
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: isSelected
                      ? LiquidGlassTheme.bubbleBlueGradient
                      : null,
                  color: isSelected
                      ? null
                      : Colors.black.withValues(alpha: 0.45),
                  border: Border.all(
                    color: Colors.white,
                    width: isSelected ? 1.0 : 1.5,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: LiquidGlassTheme.bubbleBlue.withValues(
                              alpha: 0.18,
                            ),
                            blurRadius: 4,
                          ),
                        ]
                      : null,
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 16,
                      )
                    : null,
              ),
            ),
        ],
      ),
    );
  }
}

class _GalleryThumbnailWidget extends StatelessWidget {
  final AssetEntity asset;
  const _GalleryThumbnailWidget({required this.asset});

  @override
  Widget build(BuildContext context) {
    return AssetEntityImage(
      asset,
      isOriginal: false,
      thumbnailSize: const ThumbnailSize.square(180),
      thumbnailFormat: ThumbnailFormat.jpeg,
      fit: BoxFit.cover,
      gaplessPlayback: true,
      errorBuilder: (context, error, stackTrace) =>
          Container(color: Colors.grey[900]),
    );
  }
}
