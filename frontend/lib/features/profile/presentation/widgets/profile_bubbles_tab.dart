import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../../../shared/widgets/liquid_glass.dart';
import '../../../search/domain/entities/bubble.dart';

class ProfileBubblesTab extends StatelessWidget {
  final List<dynamic> bubbles;
  final bool isLoading;
  final String emptyMessage;
  final VoidCallback? onCreateBubble;

  const ProfileBubblesTab({
    super.key,
    required this.bubbles,
    this.isLoading = false,
    this.emptyMessage = 'No bubbles joined yet.',
    this.onCreateBubble,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (bubbles.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                emptyMessage,
                style: TextStyle(color: LiquidGlassTheme.textSecondary(context)),
                textAlign: TextAlign.center,
              ),
              if (onCreateBubble != null) ...[
                const SizedBox(height: 16),
                LiquidGlassButton(
                  height: 38,
                  label: 'Create a Bubble',
                  icon: const Icon(PhosphorIconsRegular.plus, size: 16, color: Colors.white),
                  onPressed: onCreateBubble,
                ),
              ],
            ],
          ),
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalCount = bubbles.length + (onCreateBubble != null ? 1 : 0);

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: totalCount,
      itemBuilder: (context, index) {
        if (onCreateBubble != null && index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: GestureDetector(
              onTap: onCreateBubble,
              child: LiquidGlassContainer(
                borderRadius: BorderRadius.circular(18),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.10)
                            : const Color(0xFFE2E8F0),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.16)
                              : const Color(0xFFCBD5E1),
                          width: 1.0,
                        ),
                      ),
                      child: Icon(
                        PhosphorIconsRegular.plus,
                        color: LiquidGlassTheme.textPrimary(context),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Create a Bubble',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: LiquidGlassTheme.textPrimary(context),
                            ),
                          ),
                          Text(
                            'Start a new community bubble',
                            style: TextStyle(
                              fontSize: 12,
                              color: LiquidGlassTheme.textSecondary(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      PhosphorIconsRegular.caretRight,
                      size: 16,
                      color: LiquidGlassTheme.textSecondary(context),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final itemIndex = onCreateBubble != null ? index - 1 : index;
        final item = bubbles[itemIndex];
        final String name;
        final String description;

        if (item is Bubble) {
          name = item.name;
          description = item.description;
        } else {
          final b = item is Map<String, dynamic> ? item : Map<String, dynamic>.from(item as Map);
          name = (b['name'] ?? '').toString();
          description = (b['description'] ?? '').toString();
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: LiquidGlassContainer(
            borderRadius: BorderRadius.circular(18),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LiquidGlassTheme.bubbleBlueGradient,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: isDark ? 0.25 : 0.40),
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(PhosphorIconsFill.circlesThree, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: LiquidGlassTheme.textPrimary(context),
                        ),
                      ),
                      if (description.isNotEmpty)
                        Text(
                          description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: LiquidGlassTheme.textSecondary(context),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
