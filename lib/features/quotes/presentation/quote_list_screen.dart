import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quotevault/core/providers/theme_provider.dart';
import 'package:quotevault/features/quotes/data/quote_model.dart';
import 'package:quotevault/features/quotes/presentation/quote_shar_screen.dart';
import 'package:quotevault/features/quotes/providers/quote_card_template.dart';
import 'package:quotevault/features/quotes/providers/quote_provider.dart';
import 'package:quotevault/features/quotes/providers/quote_share_provider.dart';
import '../providers/quotes_list_provider.dart'; // Changed from quotes_list_provider

class QuoteListScreen extends ConsumerStatefulWidget {
  const QuoteListScreen({super.key});

  @override
  ConsumerState<QuoteListScreen> createState() => _QuoteListScreenState();
}

class _QuoteListScreenState extends ConsumerState<QuoteListScreen> {
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
        ref.read(searchQueryProvider.notifier).state = _searchController.text;
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _clearFilters() {
    _searchController.clear();
    ref.read(searchQueryProvider.notifier).state = '';
    ref.read(selectedCategoryProvider.notifier).state = null;
    setState(() => _showSearch = false);
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

  @override
  Widget build(BuildContext context) {
    final quotes = ref.watch(filteredQuotesProvider);
    final stats = ref.watch(quoteStatsProvider);
    final categories = ref.watch(categoriesProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

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
            expandedHeight: selectedCategory != null ? 180.0 : 150.0,
            backgroundColor: colorScheme.primary,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              title: AnimatedOpacity(
                opacity: _showSearch ? 0 : 1,
                duration: const Duration(milliseconds: 200),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'QuoteVault',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        color: Colors.white,
                      ),
                    ),
                    if (selectedCategory != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          '#${selectedCategory}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withOpacity(0.9),
                          ),
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
                            hintText: 'Search quotes...',
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
                              onPressed: () {
                                setState(() => _showSearch = false);
                                _searchController.clear();
                              },
                            ),
                          ),
                        ),
                      )
                    : Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.search),
                            onPressed: () => setState(() => _showSearch = true),
                            tooltip: 'Search',
                          ),
                          IconButton(
                            icon: const Icon(Icons.filter_alt_outlined),
                            onPressed: () => _showCategoryFilter(
                              context,
                              categories,
                              selectedCategory,
                            ),
                            tooltip: 'Filter by Category',
                          ),
                          IconButton(
                            icon: const Icon(Icons.favorite_border),
                            onPressed: () => context.push('/favorites'),
                            tooltip: 'Favorites',
                          ),
                          const SizedBox(width: 8),

                          IconButton(
                            icon: const Icon(Icons.settings_outlined),
                            onPressed: () => context.push('/settings'),
                            tooltip: 'Settings',
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
                        '${stats.filteredCount} ${stats.filteredCount == 1 ? 'quote' : 'quotes'}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (stats.filteredCount < stats.totalQuotes ||
                          selectedCategory != null)
                        TextButton(
                          onPressed: _clearFilters,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Clear filters',
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
                          '${stats.totalCategories} categories',
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
                              selectedCategory == category ||
                              (category == 'All' && selectedCategory == null);
                          final categoryCount = category == 'All'
                              ? stats.totalQuotes
                              : stats.categoryCounts[category] ?? 0;

                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: FilterChip(
                              label: Text('$category ($categoryCount)'),
                              selected: isSelected,
                              onSelected: (selected) {
                                ref
                                    .read(selectedCategoryProvider.notifier)
                                    .state = category == 'All'
                                    ? null
                                    : category;
                                _scrollToTop();
                              },
                              backgroundColor: isSelected
                                  ? colorScheme.primary.withOpacity(0.1)
                                  : Colors.transparent,
                              selectedColor: colorScheme.primary.withOpacity(
                                0.2,
                              ),
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? colorScheme.primary
                                    : Colors.grey[700],
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                              shape: StadiumBorder(
                                side: BorderSide(
                                  color: isSelected
                                      ? colorScheme.primary
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

          // --- Quotes List ---
          SliverPadding(
            padding: const EdgeInsets.only(top: 8.0),
            sliver: _buildQuotesList(quotes, isDarkMode, colorScheme),
          ),
        ],
      ),
      // In your QuoteListScreen, add a debug button
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            onPressed: () {
              // Debug: Print current quotes
              final quotes = ref.read(filteredQuotesProvider);
              debugPrint('Total quotes: ${quotes.length}');
              for (var quote in quotes.take(3)) {
                debugPrint(
                  'Quote: ${quote.text} | Author: ${quote.author} | Category: ${quote.category}',
                );
              }
            },
            backgroundColor: Colors.orange,
            child: const Icon(Icons.bug_report),
          ),
          const SizedBox(height: 16),
          // ... existing FAB
        ],
      ),
    );
  }

  Widget _buildQuotesList(
    List<Quote> quotes,
    bool isDarkMode,
    ColorScheme colorScheme,
  ) {
    if (quotes.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.format_quote_rounded,
                size: 80,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 20),
              Text(
                'No quotes found',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Try adjusting your filters',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
              const SizedBox(height: 30),
              FilledButton(
                onPressed: _clearFilters,
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Text('Clear All Filters'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final quote = quotes[index];
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            10,
            20,
            index == quotes.length - 1 ? 100 : 10,
          ),
          child: AnimatedScale(
            scale: 1,
            duration: Duration(milliseconds: 200 + (index * 50)),
            child: QuoteCard(quote: quote),
          ),
        );
      }, childCount: quotes.length),
    );
  }

  void _showCategoryFilter(
    BuildContext context,
    List<String> categories,
    String? selectedCategory,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filter by Category',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (selectedCategory != null)
                        TextButton(
                          onPressed: () {
                            ref.read(selectedCategoryProvider.notifier).state =
                                null;
                            Navigator.pop(context);
                          },
                          child: const Text('Clear'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 3,
                          ),
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        final isSelected =
                            selectedCategory == category ||
                            (category == 'All' && selectedCategory == null);

                        return GestureDetector(
                          onTap: () {
                            ref.read(selectedCategoryProvider.notifier).state =
                                category == 'All' ? null : category;
                            Navigator.pop(context);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Theme.of(
                                      context,
                                    ).colorScheme.primary.withOpacity(0.1)
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey[300]!,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  category,
                                  style: TextStyle(
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    color: isSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.grey[700],
                                  ),
                                ),
                                if (isSelected)
                                  Icon(
                                    Icons.check_rounded,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    size: 20,
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class QuoteCard extends ConsumerWidget {
  final Quote quote;

  const QuoteCard({required this.quote});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final fontSize = ref.watch(themeSettingsProvider.select((s) => s.fontSize));

    // Watch if this quote is favorite
    final isFavorite = ref.watch(
      quoteListProvider.select((quotes) {
        final q = quotes.firstWhere(
          (q) => q.id == quote.id,
          orElse: () => Quote.empty(),
        );
        return q.isFavorite;
      }),
    );

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _showShareOptions(context, ref),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDarkMode
                  ? [Colors.grey[850]!, Colors.grey[900]!]
                  : [Colors.white, Colors.grey[50]!],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category badge
                if (quote.category != null && quote.category!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '#${quote.category}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                // Quote text
                Text(
                  '"${quote.text}"',
                  style: TextStyle(
                    fontSize: fontSize.value,
                    height: 1.5,
                    fontStyle: FontStyle.italic,
                    color: isDarkMode ? Colors.grey[200] : Colors.grey[800],
                  ),
                ),

                const SizedBox(height: 20),

                // Author section with share buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '— ${quote.author}',
                            style: TextStyle(
                              fontSize: fontSize.value - 2,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.primary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // Action buttons
                    Row(
                      children: [
                        // Favorite button
                        IconButton(
                          icon: Icon(
                            isFavorite
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: isFavorite ? Colors.red : Colors.grey[500],
                            size: 20,
                          ),
                          onPressed: () {
                            ref
                                .read(quoteListProvider.notifier)
                                .toggleFavorite(quote.id);

                            // Show snackbar feedback
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isFavorite
                                      ? 'Removed from favorites'
                                      : 'Added to favorites',
                                ),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                        ),

                        // Share button
                        IconButton(
                          icon: Icon(
                            Icons.share_rounded,
                            color: colorScheme.primary,
                            size: 20,
                          ),
                          onPressed: () {
                            // Navigate to dedicated share screen
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    QuoteShareScreen(quote: quote),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showShareOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _ShareOptionsBottomSheet(quote: quote),
    );
  }
}

class _ShareOptionsBottomSheet extends ConsumerWidget {
  final Quote quote;

  const _ShareOptionsBottomSheet({required this.quote});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shareService = ref.read(quoteShareServiceProvider);
    final selectedTemplate = ref.watch(selectedTemplateProvider);

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'Share Quote',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),

            // Template Selection
            const Text(
              'Select Card Style:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),

            SizedBox(
              height: 80,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: QuoteCardTemplates.templates.map((template) {
                  final isSelected = selectedTemplate.id == template.id;
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: GestureDetector(
                      onTap: () {
                        ref.read(selectedTemplateProvider.notifier).state =
                            template;
                      },
                      child: Container(
                        width: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: template.backgroundColor,
                          border: Border.all(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Colors.transparent,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            template.name,
                            style: TextStyle(
                              color: template.textColor,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 24),

            // Share Options
            _ShareOptionTile(
              icon: Icons.text_fields_rounded,
              title: 'Share as Text',
              subtitle: 'Share via messaging apps',
              onTap: () async {
                Navigator.pop(context);
                await shareService.shareAsText(
                  text: quote.text,
                  author: quote.author,
                  category: quote.category,
                );
              },
            ),

            _ShareOptionTile(
              icon: Icons.image_rounded,
              title: 'Share as Image',
              subtitle: 'Share styled quote card',
              onTap: () async {
                Navigator.pop(context);
                await _shareAsImage(
                  context,
                  ref,
                  shareService,
                  selectedTemplate,
                );
              },
            ),

            _ShareOptionTile(
              icon: Icons.download_rounded,
              title: 'Save to Gallery',
              subtitle: 'Save quote card image',
              onTap: () async {
                Navigator.pop(context);
                await _saveToGallery(
                  context,
                  ref,
                  shareService,
                  selectedTemplate,
                );
              },
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _shareAsImage(
    BuildContext context,
    WidgetRef ref,
    QuoteShareService shareService,
    QuoteCardTemplate template,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final imageBytes = await shareService.generateQuoteCard(
        text: quote.text,
        author: quote.author,
        category: quote.category,
        template: template,
        size: const Size(1080, 1080),
      );

      if (imageBytes != null) {
        Navigator.pop(context); // Remove loading dialog
        await shareService.shareQuoteCard(imageBytes: imageBytes);
      } else {
        Navigator.pop(context);
        _showErrorSnackBar(context, 'Failed to generate image');
      }
    } catch (e) {
      Navigator.pop(context);
      _showErrorSnackBar(context, 'Error sharing image: $e');
    }
  }

  Future<void> _saveToGallery(
    BuildContext context,
    WidgetRef ref,
    QuoteShareService shareService,
    QuoteCardTemplate template,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final imageBytes = await shareService.generateQuoteCard(
        text: quote.text,
        author: quote.author,
        category: quote.category,
        template: template,
        size: const Size(1080, 1080),
      );

      if (imageBytes != null) {
        final saved = await shareService.saveQuoteCardLocally(
          imageBytes: imageBytes,
        );
        Navigator.pop(context); // Remove loading dialog

        if (saved != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Quote saved to gallery!'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (context.mounted) {
          _showErrorSnackBar(
            context,
            'Failed to save image. Check permissions.',
          );
        }
      } else {
        Navigator.pop(context);
        _showErrorSnackBar(context, 'Failed to generate image');
      }
    } catch (e) {
      Navigator.pop(context);
      _showErrorSnackBar(context, 'Error saving image: $e');
    }
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}

class _ShareOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ShareOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Theme.of(context).colorScheme.primary),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[600])),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
    );
  }
}
