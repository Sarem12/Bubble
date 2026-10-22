import 'package:flutter/material.dart';
import '../../core/utils/media_helpers.dart';
import 'liquid_glass.dart';

class UserAvatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final String? heroTag;

  const UserAvatar({
    super.key,
    this.imageUrl,
    this.radius = 20,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    final finalUrl = MediaHelpers.resolveUrl(imageUrl);
    final hasImage = finalUrl.isNotEmpty;
    // Calculate memory decode size bounded to device pixel ratio (~2.5x)
    final pixelSize = (radius * 2 * 2.5).round().clamp(40, 400);

    final avatarWidget = CircleAvatar(
      radius: radius,
      backgroundColor: LiquidGlassTheme.avatarBackground(context),
      backgroundImage: hasImage
          ? ResizeImage(
              NetworkImage(finalUrl),
              width: pixelSize,
              height: pixelSize,
              allowUpscaling: false,
            )
          : null,
      child: !hasImage
          ? Icon(
              Icons.person,
              size: radius * 1.05,
              color: LiquidGlassTheme.textSecondary(context).withValues(alpha: 0.6),
            )
          : null,
    );

    if (heroTag != null && heroTag!.isNotEmpty) {
      return Hero(
        tag: heroTag!,
        child: avatarWidget,
      );
    }

    return avatarWidget;
  }
}
