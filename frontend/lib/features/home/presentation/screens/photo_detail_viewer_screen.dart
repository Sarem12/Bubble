import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../../../core/utils/ui_helpers.dart';
import '../../../../shared/providers/dynamic_dock_provider.dart';
import '../../../../shared/widgets/liquid_glass.dart';
import '../../../../core/transitions/bubble_page_transitions.dart';
import 'create_post_screen.dart';
import 'photo_editor_screen.dart';

class PhotoDetailViewerScreen extends ConsumerStatefulWidget {
  final AssetEntity asset;
  final VoidCallback? onModified;

  const PhotoDetailViewerScreen({
    super.key,
    required this.asset,
    this.onModified,
  });

  @override
  ConsumerState<PhotoDetailViewerScreen> createState() =>
      _PhotoDetailViewerScreenState();
}

class _PhotoDetailViewerScreenState
    extends ConsumerState<PhotoDetailViewerScreen> {
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    _loadFile();
  }

  Future<File?> _ensureImageFile() async {
    if (_imageFile != null) return _imageFile;
    try {
      final f = await widget.asset.file;
      if (mounted && f != null) {
        setState(() => _imageFile = f);
      }
      return f;
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadFile() async {
    try {
      final f = await widget.asset.file;
      if (mounted) {
        setState(() {
          _imageFile = f;
        });
      }
    } catch (_) {}
  }

  Future<void> _openEditor() async {
    final file = await _ensureImageFile();
    if (file == null) {
      if (mounted) UiHelpers.showError(context, 'Unable to load photo.');
      return;
    }
    if (!mounted) return;
    final XFile? editedResult = await Navigator.of(context, rootNavigator: true)
        .push<XFile>(
          BubbleMorphModalRoute(
            page: PhotoEditorScreen(initialImage: XFile(file.path)),
          ),
        );

    if (editedResult != null && mounted) {
      setState(() {
        _imageFile = File(editedResult.path);
      });
      widget.onModified?.call();
    }
  }

  Future<void> _sharePhoto() async {
    final file = await _ensureImageFile();
    if (file == null) {
      if (mounted) UiHelpers.showError(context, 'Unable to load photo.');
      return;
    }
    try {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: 'Shared from Bubble Gallery',
        ),
      );
    } catch (e) {
      if (mounted) UiHelpers.showError(context, 'Share failed: $e');
    }
  }

  Future<void> _postPhoto() async {
    final file = await _ensureImageFile();
    if (file == null) {
      if (mounted) UiHelpers.showError(context, 'Unable to load photo.');
      return;
    }
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).push(
      BubbleMorphModalRoute(
        page: CreatePostScreen(initialImages: [XFile(file.path)]),
      ),
    );
  }

  Future<void> _deletePhoto() async {
    final confirmed = await showBubbleDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: LiquidGlassCard(
          borderRadius: 24,
          blur: 16,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.redAccent.withValues(alpha: 0.15),
                ),
                child: const Icon(
                  PhosphorIconsRegular.trash,
                  color: Colors.redAccent,
                  size: 26,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Delete photo?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: LiquidGlassTheme.textPrimary(ctx),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This photo will be permanently deleted from your device.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: LiquidGlassTheme.textSecondary(ctx),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: LiquidGlassButton(
                      label: 'Cancel',
                      isPrimary: false,
                      onPressed: () => Navigator.pop(ctx, false),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: LiquidGlassButton(
                      label: 'Delete',
                      isPrimary: true,
                      onPressed: () => Navigator.pop(ctx, true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final deletedIds = await PhotoManager.editor.deleteWithIds([
          widget.asset.id,
        ]);
        if (deletedIds.isNotEmpty) {
          widget.onModified?.call();
          if (mounted) {
            ref.read(dynamicDockProvider.notifier).resetToNavigation();
            Navigator.pop(context);
            UiHelpers.showSuccess(context, 'Photo deleted');
          }
        }
      } catch (e) {
        if (mounted) UiHelpers.showError(context, 'Delete failed: $e');
      }
    }
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final createDate = widget.asset.createDateTime;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: LiquidGlassAppBar(
        leading: const BubbleBackButton(color: Colors.white),
        title: Text(
          _formatDate(createDate),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Zoomable & Pannable Full-Screen Photo
          InteractiveViewer(
            minScale: 1.0,
            maxScale: 4.5,
            child: Center(
              child: Hero(
                tag: 'gallery_asset_${widget.asset.id}',
                child: _imageFile != null
                    ? Image.file(_imageFile!, fit: BoxFit.contain)
                    : AssetEntityImage(
                        widget.asset,
                        isOriginal: false,
                        thumbnailSize: const ThumbnailSize.square(600),
                        thumbnailFormat: ThumbnailFormat.jpeg,
                        fit: BoxFit.contain,
                        gaplessPlayback: true,
                        loadingBuilder: (_, child, progress) {
                          if (progress == null) return child;
                          return AssetEntityImage(
                            widget.asset,
                            isOriginal: false,
                            thumbnailSize: const ThumbnailSize.square(180),
                            thumbnailFormat: ThumbnailFormat.jpeg,
                            fit: BoxFit.contain,
                            gaplessPlayback: true,
                          );
                        },
                      ),
              ),
            ),
          ),

          // Floating Liquid Glass Action Dock (Edit, Share, Post, Delete)
          Positioned(
            left: 20,
            right: 20,
            bottom: MediaQuery.paddingOf(context).bottom + 16,
            child: LiquidGlassContainer(
              borderRadius: BorderRadius.circular(28),
              blur: 16,
              hasBlur: true,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildActionButton(
                      icon: PhosphorIconsRegular.magicWand,
                      label: 'Edit',
                      onTap: _openEditor,
                    ),
                    _buildActionButton(
                      icon: PhosphorIconsRegular.shareNetwork,
                      label: 'Share',
                      onTap: _sharePhoto,
                    ),
                    _buildActionButton(
                      icon: PhosphorIconsFill.paperPlaneTilt,
                      label: 'Post',
                      isPrimary: true,
                      onTap: _postPhoto,
                    ),
                    _buildActionButton(
                      icon: PhosphorIconsRegular.trash,
                      label: 'Delete',
                      customColor: Colors.redAccent.shade100,
                      onTap: _deletePhoto,
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

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isPrimary = false,
    Color? customColor,
  }) {
    if (isPrimary) {
      return LiquidGlassButton(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        label: label,
        icon: Icon(
          icon,
          size: 16,
          color: LiquidGlassTheme.textPrimary(context),
        ),
        onPressed: onTap,
      );
    }

    final color = customColor ?? Colors.white;

    return GestureDetector(
      onTap: () {
        SafeHaptics.lightImpact();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: customColor != null
                    ? FontWeight.bold
                    : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
