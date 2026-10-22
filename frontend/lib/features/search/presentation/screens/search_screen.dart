import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../controllers/search_controller.dart';
import '../../../../core/utils/ui_helpers.dart';
import '../../../../shared/widgets/post_card.dart';
import '../../../../shared/widgets/smart_user_avatar.dart';
import '../../../../shared/widgets/liquid_glass.dart';
import '../../../profile/presentation/controllers/profile_controller.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    Future.microtask(() {
      ref.read(searchControllerProvider.notifier).updateQuery('');
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchControllerProvider);
    final searchNotifier = ref.read(searchControllerProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final myProfile = ref.watch(profileControllerProvider).value;
    final myId = (myProfile?['id'] ?? myProfile?['_id'] ?? myProfile?['user_id'] ?? '').toString();

    final categories = ['#tech', '#design', '#music', '#gaming', '#art'];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: LiquidGlassAppBar(
        automaticallyImplyLeading: false,
        centerTitle: false,
        title: LiquidGlassSearchBar(
          controller: _searchController,
          hintText: 'Search friends, bubbles, posts...',
          onChanged: (val) => searchNotifier.updateQuery(val),
          onClear: () {
            searchNotifier.updateQuery('');
            FocusScope.of(context).unfocus();
          },
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(38),
          child: SizedBox(
            height: 38,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: categories.map((cat) {
                    final isSelected = searchState.category == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: LiquidGlassPill(
                        label: cat,
                        height: 28,
                        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
                        isSelected: isSelected,
                        onTap: () => searchNotifier.updateCategory(cat),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ),
      body: searchState.results.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text(
            'Error: $err',
            style: TextStyle(color: LiquidGlassTheme.textSecondary(context)),
          ),
        ),
        data: (results) {
          final topInset = MediaQuery.paddingOf(context).top + kToolbarHeight + 38;

          if (searchState.query.isEmpty) {
            if (results.isEmpty) {
              return Center(
                child: Text(
                  'No top posts yet.',
                  style: TextStyle(color: LiquidGlassTheme.textSecondary(context)),
                ),
              );
            }
            return ListView.builder(
              padding: EdgeInsets.only(top: topInset + 8, bottom: 100),
              itemCount: results.length,
              itemBuilder: (context, index) {
                return PostCard(post: results[index]);
              },
            );
          }

          if (results.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    PhosphorIconsRegular.magnifyingGlass,
                    size: 48,
                    color: LiquidGlassTheme.textSecondary(context).withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No results found',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: LiquidGlassTheme.textPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Try searching for another keyword or change category',
                    style: TextStyle(
                      fontSize: 13,
                      color: LiquidGlassTheme.textSecondary(context),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.only(top: topInset + 8, bottom: 100),
            itemCount: results.length,
            itemBuilder: (context, index) {
              final item = results[index];
              final isBubble = item['type'] == 'bubble' || item.containsKey('name');
              final isUser = !isBubble && item.containsKey('username');

              final title = (item['name'] ?? item['username'] ?? item['content'] ?? 'Result').toString();
              final subtitle = isBubble ? 'Bubble Community' : (isUser ? '@${item['username'] ?? ''}' : 'Post');

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: LiquidGlassContainer(
                  borderRadius: BorderRadius.circular(20),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  onTap: () {
                    final id = item['id']?.toString() ?? '';
                    if (id.isEmpty) return;
                    if (isUser) {
                      context.push('/user/$id');
                    } else if (!isBubble) {
                      context.push('/post/$id');
                    }
                  },
                  child: Row(
                    children: [
                      if (isBubble)
                        Container(
                          width: 42,
                          height: 42,
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
                          child: const Icon(PhosphorIconsFill.circlesThree, color: Colors.white, size: 22),
                        )
                      else if (isUser)
                        SmartUserAvatar(userId: item['id'].toString(), radius: 21)
                      else
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark ? Colors.white12 : Colors.black12,
                          ),
                          child: Icon(
                            PhosphorIconsRegular.article,
                            color: LiquidGlassTheme.textPrimary(context),
                            size: 20,
                          ),
                        ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: LiquidGlassTheme.textPrimary(context),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: 12,
                                color: LiquidGlassTheme.textSecondary(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isBubble)
                        LiquidGlassButton(
                          height: 32,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          onPressed: () async {
                            final ok = await searchNotifier.joinBubble(item['id'].toString());
                            if (context.mounted) {
                              if (ok) {
                                UiHelpers.showSuccess(context, "Joined bubble!");
                              } else {
                                UiHelpers.showError(context, "Could not join bubble.");
                              }
                            }
                          },
                          label: 'Join',
                        )
                      else if (isUser && item['id']?.toString() != myId)
                        LiquidGlassButton(
                          height: 32,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          onPressed: () async {
                            final ok = await searchNotifier.sendFriendRequest(item['id'].toString());
                            if (context.mounted) {
                              if (ok) {
                                UiHelpers.showSuccess(context, "Friend request sent!");
                              } else {
                                UiHelpers.showError(context, "Request failed.");
                              }
                            }
                          },
                          label: 'Add',
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
