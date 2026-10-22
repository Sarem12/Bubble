import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../../../core/utils/media_helpers.dart';
import '../../../../shared/widgets/liquid_glass.dart';
import '../../../home/domain/entities/post.dart';

class ProfilePostsGrid extends StatelessWidget {
  final List<dynamic> posts;
  final bool isLoading;
  final String emptyMessage;

  const ProfilePostsGrid({
    super.key,
    required this.posts,
    this.isLoading = false,
    this.emptyMessage = 'No posts yet.',
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (posts.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          style: TextStyle(color: LiquidGlassTheme.textSecondary(context)),
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(2, 2, 2, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final item = posts[index];
        final String postId;
        final String content;
        final String? firstMediaUrl;
        final bool isMultiPhoto;

        if (item is FeedItem) {
          postId = item.id;
          content = item.content;
          firstMediaUrl = item.hasMedia ? item.media.first.resolvedUrl : null;
          isMultiPhoto = item.media.length > 1;
        } else {
          final postMap = item is Map<String, dynamic> ? item : Map<String, dynamic>.from(item as Map);
          postId = (postMap['id'] ?? '').toString();
          content = (postMap['content'] ?? '').toString();
          final mediaList = postMap['media'] as List?;
          if (mediaList != null && mediaList.isNotEmpty) {
            final first = mediaList[0];
            final rawUrl = first is Map ? (first['url'] ?? '') : first.toString();
            firstMediaUrl = MediaHelpers.resolveUrl(rawUrl);
            isMultiPhoto = mediaList.length > 1;
          } else {
            firstMediaUrl = null;
            isMultiPhoto = false;
          }
        }

        final hasMedia = firstMediaUrl != null && firstMediaUrl.isNotEmpty;

        return RepaintBoundary(
          child: GestureDetector(
            onTap: () {
              if (postId.isNotEmpty) {
                context.push('/post/$postId');
              }
            },
            child: Container(
              color: LiquidGlassTheme.gridBackground(context),
              child: hasMedia
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          firstMediaUrl,
                          fit: BoxFit.cover,
                          cacheWidth: 360,
                          cacheHeight: 360,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: isDark ? const Color(0xFF27272A) : Colors.grey[300],
                            child: Center(
                              child: Icon(
                                Icons.broken_image,
                                color: LiquidGlassTheme.textSecondary(context),
                              ),
                            ),
                          ),
                        ),
                        if (isMultiPhoto)
                          Positioned(
                            top: 6,
                            right: 6,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Icon(
                                PhosphorIconsFill.browsers,
                                color: Colors.white,
                                size: 13,
                              ),
                            ),
                          ),
                      ],
                    )
                  : Center(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          content,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: LiquidGlassTheme.textPrimary(context),
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }
}
