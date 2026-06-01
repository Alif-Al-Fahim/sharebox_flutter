import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/tool_provider.dart';
import '../../models/tool_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/tool_card.dart';
import '../tool_detail/tool_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchCtrl = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    final toolProvider = context.read<ToolProvider>();
    if (query.isEmpty) {
      toolProvider.clearSearch();
    } else {
      toolProvider.searchTools(query);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();
    final toolProvider = context.watch<ToolProvider>();
    final userName = auth.userName.split(' ').first;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── App Bar ─────────────────────────────────────────────
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            elevation: 0,
            scrolledUnderElevation: 0,
            expandedHeight: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: Theme.of(context).scaffoldBackgroundColor,
              ),
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Hello, $userName 👋',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    Text(
                      'Find tools near you',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                // Notification bell
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.05), blurRadius: 8),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.notifications_outlined, size: 22),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Search Bar ───────────────────────────────────
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 12,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (val) {
                        setState(() => _isSearching = val.isNotEmpty);
                        _onSearch(val);
                      },
                      decoration: InputDecoration(
                        hintText: 'Search tools, drills, saws...',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        prefixIcon: const Icon(Icons.search_rounded,
                            color: AppTheme.primaryColor),
                        suffixIcon: _isSearching
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  setState(() => _isSearching = false);
                                  context.read<ToolProvider>().clearSearch();
                                },
                              )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Category Chips ───────────────────────────────
                  Text('Categories',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          // Category horizontal scroll
          SliverToBoxAdapter(
            child: SizedBox(
              height: 46,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _CategoryChip(
                    label: '🔥 All',
                    isSelected: toolProvider.selectedCategory == null,
                    onTap: () => context.read<ToolProvider>().filterByCategory(null),
                  ),
                  ...ToolCategory.values.map((cat) => _CategoryChip(
                        label: '${cat.emoji} ${cat.displayName}',
                        isSelected: toolProvider.selectedCategory == cat,
                        onTap: () => context
                            .read<ToolProvider>()
                            .filterByCategory(cat),
                      )),
                ],
              ),
            ),
          ),

          // ── Recommended Section ──────────────────────────────────
          if (!_isSearching && toolProvider.recommendedTools.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('✨ Recommended for You',
                        style: Theme.of(context).textTheme.titleLarge),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 230,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: toolProvider.recommendedTools.length,
                  itemBuilder: (ctx, i) {
                    final tool = toolProvider.recommendedTools[i];
                    return Container(
                      width: 165,
                      margin: const EdgeInsets.only(right: 12),
                      child: ToolCard(
                        tool: tool,
                        isFavorite: toolProvider.isFavorite(tool.id),
                        onTap: () => Navigator.push(
                          context,
                          _slideRoute(ToolDetailScreen(tool: tool)),
                        ),
                        onFavorite: () {
                          final uid =
                              context.read<AppAuthProvider>().userId;
                          context
                              .read<ToolProvider>()
                              .toggleFavorite(uid, tool.id);
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          ],

          // ── All Tools ────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isSearching
                        ? '🔍 Search Results'
                        : toolProvider.selectedCategory != null
                            ? '${toolProvider.selectedCategory!.emoji} ${toolProvider.selectedCategory!.displayName}'
                            : '🛠️ Available Tools',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    '${toolProvider.tools.length} tools',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),

          toolProvider.isLoading
              ? SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.72,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (_, __) => const ToolCardSkeleton(),
                      childCount: 6,
                    ),
                  ),
                )
              : toolProvider.tools.isEmpty
                  ? SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(48),
                        child: Column(
                          children: [
                            Icon(Icons.search_off_rounded,
                                size: 56, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              _isSearching
                                  ? 'No tools found for "${_searchCtrl.text}"'
                                  : 'No tools available yet',
                              style: Theme.of(context).textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.68,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) {
                            final tool = toolProvider.tools[i];
                            return ToolCard(
                              tool: tool,
                              isFavorite: toolProvider.isFavorite(tool.id),
                              onTap: () => Navigator.push(
                                context,
                                _slideRoute(ToolDetailScreen(tool: tool)),
                              ),
                              onFavorite: () {
                                final uid =
                                    context.read<AppAuthProvider>().userId;
                                context
                                    .read<ToolProvider>()
                                    .toggleFavorite(uid, tool.id);
                              },
                            );
                          },
                          childCount: toolProvider.tools.length,
                        ),
                      ),
                    ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  PageRoute _slideRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected ? AppTheme.primaryGradient : null,
          color: isSelected ? null : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(AppRadius.circular),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppTheme.primaryColor.withOpacity(0.3)
                  : Colors.black.withOpacity(0.04),
              blurRadius: isSelected ? 8 : 4,
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
