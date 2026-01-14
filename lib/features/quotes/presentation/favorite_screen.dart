import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quotevault/features/quotes/data/quote_model.dart';
import 'package:quotevault/features/quotes/presentation/quote_list_screen.dart';
import 'package:quotevault/features/quotes/providers/quotes_list_provider.dart';

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  final _searchController = TextEditingController();
  bool _showSearch = false;
  String _searchQuery = '';
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (_searchController.text != _searchQuery) {
        setState(() => _searchQuery = _searchController.text);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _showSearch = false;
    });
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  List<Quote> _getFilteredFavorites(List<Quote> favorites) {
    if (_searchQuery.isEmpty) return favorites;

    final query = _searchQuery.toLowerCase();
    return favorites.where((quote) {
      return quote.text.toLowerCase().contains(query) ||
          quote.author.toLowerCase().contains(query) ||
          (quote.category?.toLowerCase().contains(query) ?? false) ||
          quote.tags.any((tag) => tag.toLowerCase().contains(query)) ||
          (quote.notes?.toLowerCase().contains(query) ?? false) ||
          (quote.source?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final allFavorites = ref.watch(favoriteQuotesProvider);
    final filteredFavorites = _getFilteredFavorites(allFavorites);
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Get unique categories from favorites
    final favoriteCategories = <String>{'All'};
    final categoryCounts = <String, int>{'All': allFavorites.length};

    for (final quote in allFavorites) {
      final category = quote.category?.trim().isNotEmpty == true
          ? quote.category!
          : 'Uncategorized';
      favoriteCategories.add(category);
      categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
    }

    final categories = favoriteCategories.toList()
      ..sort((a, b) {
        if (a == 'All') return -1;
        if (b == 'All') return 1;
        return a.compareTo(b);
      });

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.grey[50],
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // --- App Bar Section ---
          SliverAppBar(
            floating: true,
            pinned: true,
            snap: false,
            expandedHeight: 150.0,
            backgroundColor: colorScheme.primary,
            foregroundColor: Colors.white,
            // foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              title: AnimatedOpacity(
                opacity: _showSearch ? 0 : 1,
                duration: const Duration(milliseconds: 200),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Favorite Quotes',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${allFavorites.length} ${allFavorites.length == 1 ? 'Quote' : 'Quotes'}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              centerTitle: true,
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.primary,
                      colorScheme.primary.withOpacity(0.8),
                      colorScheme.primary.withOpacity(0.6),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _showSearch
                    ? Container(
                        width: MediaQuery.of(context).size.width - 100,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TextField(
                          controller: _searchController,
                          autofocus: true,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Search favorites...',
                            hintStyle: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                            ),
                            border: InputBorder.none,
                            prefixIcon: Icon(
                              Icons.search,
                              color: Colors.white.withOpacity(0.7),
                            ),
                            suffixIcon: IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white,
                              ),
                              onPressed: _clearSearch,
                            ),
                          ),
                        ),
                      )
                    : Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.search),
                            onPressed: () => setState(() => _showSearch = true),
                            tooltip: 'Search Favorites',
                          ),
                          if (allFavorites.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () =>
                                  _showClearAllDialog(context, ref),
                              tooltip: 'Clear All Favorites',
                            ),

                          const SizedBox(width: 8),
                        ],
                      ),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(54.0),
              child: Container(
                color: Colors.white.withOpacity(0.05),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${filteredFavorites.length} ${filteredFavorites.length == 1 ? 'result' : 'results'}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (_searchQuery.isNotEmpty ||
                          filteredFavorites.length < allFavorites.length)
                        TextButton(
                          onPressed: _clearSearch,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Clear search',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // --- Category Chips Section ---
          if (allFavorites.isNotEmpty)
            SliverToBoxAdapter(
              child: Container(
                color: isDarkMode ? Colors.grey[850] : Colors.white,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Categories',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDarkMode
                                  ? Colors.grey[200]
                                  : Colors.grey[800],
                            ),
                          ),
                          Text(
                            '${categories.length - 1} categories',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: categories.map((category) {
                            final isSelected =
                                category == 'All' && _searchQuery.isEmpty;
                            final categoryCount = categoryCounts[category] ?? 0;

                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: FilterChip(
                                label: Text('$category ($categoryCount)'),
                                selected: isSelected,
                                onSelected: (selected) {
                                  if (category != 'All') {
                                    // Filter by category
                                    _searchController.text = category;
                                    setState(() => _searchQuery = category);
                                  } else {
                                    _clearSearch();
                                  }
                                  _scrollToTop();
                                },
                                backgroundColor: isSelected
                                    ? Colors.pinkAccent.withOpacity(0.1)
                                    : Colors.transparent,
                                selectedColor: Colors.pinkAccent.withOpacity(
                                  0.2,
                                ),
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? Colors.pinkAccent
                                      : Colors.grey[700],
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                                shape: StadiumBorder(
                                  side: BorderSide(
                                    color: isSelected
                                        ? Colors.pinkAccent
                                        : Colors.grey[300]!,
                                    width: isSelected ? 1.5 : 1.0,
                                  ),
                                ),
                                showCheckmark: false,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // --- Favorites List ---
          SliverPadding(
            padding: const EdgeInsets.only(top: 8.0),
            sliver: _buildFavoritesList(
              filteredFavorites,
              isDarkMode,
              colorScheme,
            ),
          ),
        ],
      ),
      /* floatingActionButton: filteredFavorites.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => _shareAllFavorites(context, ref),
              backgroundColor: Colors.pinkAccent,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.share_rounded),
              label: const Text('Share All'),
            )
          : null, */
    );
  }

  Widget _buildFavoritesList(
    List<Quote> favorites,
    bool isDarkMode,
    ColorScheme colorScheme,
  ) {
    if (favorites.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _searchQuery.isEmpty
                    ? Icons.favorite_border_rounded
                    : Icons.search_off_rounded,
                size: 80,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 20),
              Text(
                _searchQuery.isEmpty
                    ? 'No favorite quotes yet'
                    : 'No matching favorites',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _searchQuery.isEmpty
                    ? 'Tap the heart icon on any quote'
                    : 'Try a different search term',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
              const SizedBox(height: 30),
              if (_searchQuery.isNotEmpty)
                FilledButton(
                  onPressed: _clearSearch,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.pinkAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    child: Text('Clear Search'),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final quote = favorites[index];
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            10,
            20,
            index == favorites.length - 1 ? 100 : 10,
          ),
          child: AnimatedScale(
            scale: 1,
            duration: Duration(milliseconds: 200 + (index * 50)),
            child: QuoteCard(quote: quote),
          ),
        );
      }, childCount: favorites.length),
    );
  }

  Future<void> _showClearAllDialog(BuildContext context, WidgetRef ref) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Favorites?'),
        content: const Text('This will remove all quotes from your favorites.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[700])),
          ),
          TextButton(
            onPressed: () {
              ref.read(quoteListProvider.notifier).clearAllFavorites();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('All favorites cleared'),
                  backgroundColor: Colors.pinkAccent,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
            },
            child: const Text('Clear All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _shareAllFavorites(BuildContext context, WidgetRef ref) async {
    final favorites = ref.read(favoriteQuotesProvider);
    if (favorites.isEmpty) return;

    // Create a text with all favorite quotes
    final buffer = StringBuffer();
    buffer.writeln('⭐ My Favorite Quotes ⭐\n');

    for (var i = 0; i < favorites.length; i++) {
      final quote = favorites[i];
      buffer.writeln('${i + 1}. "${quote.text}"');
      buffer.writeln('   — ${quote.author}');
      if (quote.category != null) {
        buffer.writeln('   #${quote.category}');
      }
      buffer.writeln(); // Empty line between quotes
    }

    buffer.writeln('\nShared from QuoteVault 📚');

    // Show share dialog
    // You can use the share package: https://pub.dev/packages/share
    // await Share.share(buffer.toString());

    // For now, show a dialog with the text
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share All Favorites'),
        content: SingleChildScrollView(
          child: Text(
            buffer.toString(),
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              // Copy to clipboard
              // Clipboard.setData(ClipboardData(text: buffer.toString()));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Copied to clipboard'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Copy'),
          ),
        ],
      ),
    );
  }
}
