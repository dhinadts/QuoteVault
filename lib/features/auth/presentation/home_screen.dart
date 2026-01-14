import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quotevault/core/providers/theme_provider.dart';
import 'package:quotevault/features/quotes/data/quote_model.dart';
import 'package:quotevault/features/quotes/providers/quotes_list_provider.dart';
import 'package:quotevault/routes/app_router.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with RouteAware {
  Quote? _randomQuote;
  bool _isRefreshing = false;
  final List<String> _greetings = [
    'Inspire your day',
    'Wisdom awaits',
    'Find your quote',
    'Daily inspiration',
    'Mindful moments',
    'Thought for today',
  ];
  late String _currentGreeting;

  @override
  void initState() {
    super.initState();
    _currentGreeting = _greetings[DateTime.now().second % _greetings.length];

    // Load initial quote after first frame so provider is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final quotes = ref.read(quoteListProvider);
      if (quotes.isNotEmpty) {
        _setRandomQuote(quotes);
      }
    });
  }

  void _setRandomQuote(List<Quote> quotes) {
    final randomIndex = DateTime.now().millisecondsSinceEpoch % quotes.length;
    setState(() {
      _randomQuote = quotes[randomIndex];
      _isRefreshing = false;
    });
  }

  Future<void> _loadRandomQuote() async {
    setState(() => _isRefreshing = true);
    await Future.delayed(const Duration(milliseconds: 300));
    final quotes = ref.read(quoteListProvider);
    if (quotes.isNotEmpty) {
      _setRandomQuote(quotes);
    } else {
      setState(() => _isRefreshing = false);
    }
  }

  void _changeGreeting() {
    final currentIndex = _greetings.indexOf(_currentGreeting);
    final nextIndex = (currentIndex + 1) % _greetings.length;
    setState(() => _currentGreeting = _greetings[nextIndex]);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void didPopNext() {
    // Called when returning to this screen
    _loadRandomQuote();
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref; // Get the ref from ConsumerState

    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final quotes = ref.watch(quoteListProvider);
    // Always try to load a random quote when quotes are available
    if (quotes.isNotEmpty && _randomQuote == null && !_isRefreshing) {
      Future.microtask(() => _setRandomQuote(quotes));
    }

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            pinned: true,
            expandedHeight: 160.0,
            backgroundColor: colorScheme.primary,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              title: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'QuoteVault',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _currentGreeting,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
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
                child: Stack(
                  children: [
                    Positioned(
                      top: 20,
                      right: 20,
                      child: Icon(
                        Icons.format_quote_rounded,
                        size: 60,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    Positioned(
                      bottom: 20,
                      left: 20,
                      child: Icon(
                        Icons.format_quote_rounded,
                        size: 40,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.collections_bookmark_rounded),
                onPressed: () => context.push('/quotes'),
                tooltip: 'All Quotes',
              ),
              IconButton(
                icon: const Icon(Icons.favorite_border_rounded),
                onPressed: () => context.push('/favorites'),
                tooltip: 'Favorites',
              ),
              const SizedBox(width: 8),
            ],
          ),

          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (quotes.isNotEmpty)
                    _buildStatsCards(context, quotes, colorScheme, isDarkMode),

                  const SizedBox(height: 40),

                  if (_randomQuote != null)
                    _buildQuoteCard(
                      context,
                      _randomQuote!,
                      colorScheme,
                      isDarkMode,
                    )
                  else if (quotes.isEmpty)
                    _buildEmptyState(context, colorScheme, isDarkMode)
                  else
                    _buildLoadingQuoteCard(isDarkMode),

                  const SizedBox(height: 40),

                  _buildActionButtons(context, ref, colorScheme),

                  const SizedBox(height: 20),

                  Text(
                    'Tap refresh for new inspiration',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Keep your helper methods (_buildStatsCards, _buildStatCard, _buildQuoteCard,
  // _buildEmptyState, _buildLoadingQuoteCard, _buildActionButtons, _showQuoteDetails)
  // exactly as you already have them.

  // --- keep your _buildStatsCards, _buildStatCard, _buildQuoteCard,
  // _buildEmptyState, _buildLoadingQuoteCard, _buildActionButtons,
  // and _showQuoteDetails methods exactly as you had them ---

  Widget _buildStatsCards(
    BuildContext context,
    List<Quote> quotes,
    ColorScheme colorScheme,
    bool isDarkMode,
  ) {
    final favoriteCount = quotes.where((q) => q.isFavorite).length;
    final categoryCount = quotes
        .map((q) => q.category)
        .whereType<String>()
        .toSet()
        .length;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.format_quote_rounded,
            value: quotes.length.toString(),
            label: 'Total Quotes',
            color: colorScheme.primary,
            isDarkMode: isDarkMode,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.favorite_rounded,
            value: favoriteCount.toString(),
            label: 'Favorites',
            color: Colors.pink,
            isDarkMode: isDarkMode,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.category_rounded,
            value: categoryCount.toString(),
            label: 'Categories',
            color: Colors.deepPurple,
            isDarkMode: isDarkMode,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required bool isDarkMode,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
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
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const Spacer(),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuoteCard(
    BuildContext context,
    Quote quote,
    ColorScheme colorScheme,
    bool isDarkMode,
  ) {
    final fontSize = ref.watch(themeSettingsProvider.select((s) => s.fontSize));

    return GestureDetector(
      onTap: () => _showQuoteDetails(context, quote),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDarkMode
                  ? [Colors.grey[850]!, Colors.grey[900]!]
                  : [Colors.white, Colors.grey[50]!],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
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
              if (quote.category != null && quote.category!.isNotEmpty)
                const SizedBox(height: 20),

              // Quote text
              Text(
                '"${quote.text}"',
                style: TextStyle(
                  fontSize: fontSize.value + 2,
                  height: 1.6,
                  fontStyle: FontStyle.italic,
                  color: isDarkMode ? Colors.grey[200] : Colors.grey[800],
                ),
              ),
              const SizedBox(height: 24),

              // Author section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '— ${quote.author}',
                    style: TextStyle(
                      fontSize: fontSize.value,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      quote.isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: quote.isFavorite ? Colors.red : Colors.grey[500],
                    ),
                    onPressed: () {
                      ref
                          .read(quoteListProvider.notifier)
                          .toggleFavorite(quote.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            quote.isFavorite
                                ? 'Removed from favorites'
                                : 'Added to favorites',
                          ),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    ColorScheme colorScheme,
    bool isDarkMode,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
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
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(Icons.format_quote_rounded, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 20),
            Text(
              'No quotes yet',
              style: TextStyle(
                fontSize: 20,
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Add your first quote to get started',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            FilledButton.icon(
              onPressed: () => context.push('/add-quote'),
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                child: Text('Add First Quote'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingQuoteCard(bool isDarkMode) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
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
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Loading shimmer for category
            Container(
              width: 80,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 20),

            // Loading shimmer for quote text
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity * 0.8,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity * 0.6,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Loading shimmer for author
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 120,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    WidgetRef ref,
    ColorScheme colorScheme,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Refresh Button
        ElevatedButton.icon(
          onPressed: _isRefreshing ? null : _loadRandomQuote,
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
          icon: _isRefreshing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.refresh_rounded, size: 20),
          label: Text(
            _isRefreshing ? 'Loading...' : 'New Quote',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 16),

        // All Quotes Button
        OutlinedButton.icon(
          onPressed: () => context.push('/quotes'),
          style: OutlinedButton.styleFrom(
            foregroundColor: colorScheme.primary,
            side: BorderSide(color: colorScheme.primary),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
          icon: const Icon(Icons.collections_bookmark_rounded, size: 20),
          label: const Text(
            'All Quotes',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  void _showQuoteDetails(BuildContext context, Quote quote) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => QuoteDetailsBottomSheet(quote: quote),
    );
  }
}

class QuoteDetailsBottomSheet extends ConsumerWidget {
  final Quote quote;

  const QuoteDetailsBottomSheet({super.key, required this.quote});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final fontSize = ref.watch(themeSettingsProvider.select((s) => s.fontSize));

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

          // Category
          if (quote.category != null && quote.category!.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
          if (quote.category != null && quote.category!.isNotEmpty)
            const SizedBox(height: 16),

          // Quote Text
          Text(
            '"${quote.text}"',
            style: TextStyle(
              fontSize: fontSize.value + 4,
              height: 1.6,
              fontStyle: FontStyle.italic,
              color: isDarkMode ? Colors.grey[200] : Colors.grey[800],
            ),
          ),
          const SizedBox(height: 24),

          // Author
          Text(
            '— ${quote.author}',
            style: TextStyle(
              fontSize: fontSize.value + 2,
              fontWeight: FontWeight.w600,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),

          // Additional Info
          if (quote.source != null && quote.source!.isNotEmpty) ...[
            _buildDetailRow(
              icon: Icons.source_rounded,
              label: 'Source',
              value: quote.source!,
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 12),
          ],
          if (quote.notes != null && quote.notes!.isNotEmpty) ...[
            _buildDetailRow(
              icon: Icons.note_rounded,
              label: 'Notes',
              value: quote.notes!,
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 12),
          ],

          // Tags
          if (quote.tags.isNotEmpty) ...[
            Text(
              'Tags',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: quote.tags.map((tag) {
                return Chip(
                  label: Text(tag),
                  backgroundColor: colorScheme.primary.withOpacity(0.1),
                  labelStyle: TextStyle(
                    color: colorScheme.primary,
                    fontSize: 12,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],

          // Created Date
          _buildDetailRow(
            icon: Icons.calendar_today_rounded,
            label: 'Added',
            value: quote.createdAt.toString().split(' ')[0],
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 24),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Close'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Implement share functionality
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: const Icon(Icons.share_rounded, size: 20),
                  label: const Text('Share'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required ColorScheme colorScheme,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
