import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:quotevault/core/providers/theme_provider.dart';
import 'package:quotevault/features/quotes/data/quote_model.dart';
import 'package:quotevault/features/quotes/providers/quotes_list_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isRefreshing = false;
  Quote? _currentQuote;

  final List<String> _greetings = [
    'Daily Inspiration',
    'Wisdom Awaits',
    'Mindful Moment',
    'Thought for Today',
    'Inspire Your Day',
  ];
  late String _currentGreeting;

  @override
  void initState() {
    super.initState();
    _currentGreeting = _greetings[DateTime.now().second % _greetings.length];

    // Load initial quote after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final quotes = ref.read(quoteListProvider);
      if (quotes.isNotEmpty) {
        _setRandomQuote(quotes);
      }
    });
  }

  void _setRandomQuote(List<Quote> quotes) {
    if (quotes.isEmpty) return;

    final random = Random();
    final randomIndex = random.nextInt(quotes.length);
    setState(() {
      _currentQuote = quotes[randomIndex];
      _isRefreshing = false;
    });

    debugPrint(
      '📝 New quote set: "${_currentQuote!.text.substring(0, min(30, _currentQuote!.text.length))}..."',
    );
  }

  Future<void> _loadNewQuote() async {
    debugPrint('🔄 Loading new quote...');
    setState(() => _isRefreshing = true);
    await Future.delayed(const Duration(milliseconds: 300));
    final quotes = ref.read(quoteListProvider);
    if (quotes.isNotEmpty) {
      _setRandomQuote(quotes);
    } else {
      setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isSmallScreen = mediaQuery.size.width < 600;
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final quotes = ref.watch(quoteListProvider);

    // Initialize random quote if not set
    if (quotes.isNotEmpty && _currentQuote == null && !_isRefreshing) {
      Future.microtask(() => _setRandomQuote(quotes));
    }

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            pinned: true,
            expandedHeight: isSmallScreen ? 140.0 : 180.0,
            backgroundColor: colorScheme.primary,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              title: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'QuoteVault',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 20 : 24,
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
                      fontSize: isSmallScreen ? 12 : 14,
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
                        size: isSmallScreen ? 50 : 60,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  Icons.collections_bookmark_rounded,
                  size: isSmallScreen ? 20 : 24,
                ),
                onPressed: () => context.push('/quotes'),
                tooltip: 'All Quotes',
              ),
              IconButton(
                icon: Icon(
                  Icons.settings_rounded,
                  size: isSmallScreen ? 20 : 24,
                ),
                onPressed: () => context.push('/settings'),
                tooltip: 'Settings',
              ),
            ],
          ),
          SliverPadding(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 12 : 20,
              vertical: isSmallScreen ? 16 : 20,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Stats Cards
                if (quotes.isNotEmpty)
                  _buildStatsCards(
                    context,
                    quotes,
                    colorScheme,
                    isDarkMode,
                    isSmallScreen,
                  ),
                SizedBox(height: isSmallScreen ? 20 : 40),
                // Quote Card Section
                _buildQuoteCardSection(
                  context,
                  _currentQuote,
                  colorScheme,
                  isDarkMode,
                  isSmallScreen,
                ),
                SizedBox(height: isSmallScreen ? 20 : 40),
                // All Quotes Button
                _buildAllQuotesButton(
                  context,
                  colorScheme,
                  isSmallScreen,
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllQuotesButton(
    BuildContext context,
    ColorScheme colorScheme,
    bool isSmallScreen,
  ) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => context.push('/quotes'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.secondary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 16 : 20),
            ),
            icon: Icon(
              Icons.library_books_rounded,
              size: isSmallScreen ? 20 : 24,
            ),
            label: Text(
              'Browse All Quotes',
              style: TextStyle(
                fontSize: isSmallScreen ? 16 : 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        SizedBox(height: isSmallScreen ? 8 : 12),
        Text(
          'View and manage your entire collection of quotes',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isSmallScreen ? 12 : 14,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildQuoteCardSection(
    BuildContext context,
    Quote? currentQuote,
    ColorScheme colorScheme,
    bool isDarkMode,
    bool isSmallScreen,
  ) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Daily Quote',
              style: TextStyle(
                fontSize: isSmallScreen ? 18 : 20,
                fontWeight: FontWeight.w700,
                color: colorScheme.primary,
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 10 : 12,
                vertical: isSmallScreen ? 4 : 6,
              ),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Random',
                style: TextStyle(
                  fontSize: isSmallScreen ? 10 : 12,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: isSmallScreen ? 12 : 16),
        if (currentQuote != null)
          _buildQuoteCard(
            context,
            currentQuote,
            colorScheme,
            isDarkMode,
            isSmallScreen,
          )
        else
          _buildLoadingQuoteCard(isDarkMode, isSmallScreen),
        SizedBox(height: isSmallScreen ? 12 : 16),
        // Refresh Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isRefreshing ? null : _loadNewQuote,
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary.withOpacity(0.1),
              foregroundColor: colorScheme.primary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 12 : 16),
            ),
            icon: _isRefreshing
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.primary,
                    ),
                  )
                : Icon(Icons.refresh_rounded, size: isSmallScreen ? 18 : 20),
            label: Text(
              _isRefreshing ? 'Loading...' : 'Get New Quote',
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuoteCard(
    BuildContext context,
    Quote quote,
    ColorScheme colorScheme,
    bool isDarkMode,
    bool isSmallScreen,
  ) {
    final fontSize = ref.watch(themeSettingsProvider.select((s) => s.fontSize));

    return GestureDetector(
      onTap: () => _showQuoteDetails(context, quote),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(isSmallScreen ? 20 : 32),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDarkMode
                  ? [Colors.grey[850]!, Colors.grey[900]!]
                  : [Colors.white, colorScheme.primary.withOpacity(0.05)],
            ),
            border: Border.all(
              color: colorScheme.primary.withOpacity(0.2),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.format_quote_rounded,
                    size: isSmallScreen ? 24 : 32,
                    color: colorScheme.primary.withOpacity(0.3),
                  ),
                  SizedBox(width: isSmallScreen ? 8 : 12),
                  Expanded(
                    child: Text(
                      quote.text,
                      style: TextStyle(
                        fontSize: isSmallScreen
                            ? fontSize.value + 2
                            : fontSize.value + 4,
                        height: 1.6,
                        fontStyle: FontStyle.italic,
                        color: isDarkMode ? Colors.grey[200] : Colors.grey[800],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: isSmallScreen ? 16 : 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '— ${quote.author}',
                    style: TextStyle(
                      fontSize: isSmallScreen
                          ? fontSize.value
                          : fontSize.value + 2,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 4 : 8),
                  Text(
                    'Updated: ${DateFormat('MMMM d, yyyy - hh:mm a').format(DateTime.now())}',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 10 : 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingQuoteCard(bool isDarkMode, bool isSmallScreen) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(isSmallScreen ? 20 : 32),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode
                ? [Colors.grey[850]!, Colors.grey[900]!]
                : [Colors.white, Colors.grey[50]!],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: isSmallScreen ? 24 : 32,
                  height: isSmallScreen ? 24 : 32,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                SizedBox(width: isSmallScreen ? 8 : 12),
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 8 : 12),
                      Container(
                        width: double.infinity * 0.8,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: isSmallScreen ? 16 : 24),
            Container(
              width: isSmallScreen ? 100 : 120,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards(
    BuildContext context,
    List<Quote> quotes,
    ColorScheme colorScheme,
    bool isDarkMode,
    bool isSmallScreen,
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
            label: 'Quotes',
            color: colorScheme.primary,
            isDarkMode: isDarkMode,
            isSmallScreen: isSmallScreen,
          ),
        ),
        SizedBox(width: isSmallScreen ? 8 : 12),
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.favorite_rounded,
            value: favoriteCount.toString(),
            label: 'Favorites',
            color: Colors.pink,
            isDarkMode: isDarkMode,
            isSmallScreen: isSmallScreen,
          ),
        ),
        SizedBox(width: isSmallScreen ? 8 : 12),
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.category_rounded,
            value: categoryCount.toString(),
            label: 'Categories',
            color: Colors.deepPurple,
            isDarkMode: isDarkMode,
            isSmallScreen: isSmallScreen,
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
    required bool isSmallScreen,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode
                ? [Colors.grey[850]!, Colors.grey[900]!]
                : [Colors.white, Colors.grey[50]!],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: isSmallScreen ? 16 : 18,
                  ),
                ),
                const Spacer(),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 20 : 24,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
            SizedBox(height: isSmallScreen ? 4 : 8),
            Text(
              label,
              style: TextStyle(
                fontSize: isSmallScreen ? 10 : 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
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

  const QuoteDetailsBottomSheet({
    super.key,
    required this.quote,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaQuery = MediaQuery.of(context);
    final isSmallScreen = mediaQuery.size.width < 600;
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final fontSize = ref.watch(themeSettingsProvider.select((s) => s.fontSize));

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: mediaQuery.viewInsets.bottom + 20,
      ),
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
          SizedBox(height: isSmallScreen ? 16 : 20),
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 10 : 12,
                  vertical: isSmallScreen ? 4 : 6,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Daily Quote',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 10 : 12,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.share_rounded, size: isSmallScreen ? 20 : 24),
                onPressed: () {
                  // TODO: Implement share functionality
                },
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          // Quote Text
          Text(
            '"${quote.text}"',
            style: TextStyle(
              fontSize: isSmallScreen ? fontSize.value + 2 : fontSize.value + 4,
              height: 1.6,
              fontStyle: FontStyle.italic,
              color: isDarkMode ? Colors.grey[200] : Colors.grey[800],
            ),
          ),
          SizedBox(height: isSmallScreen ? 16 : 24),
          // Author
          Text(
            '— ${quote.author}',
            style: TextStyle(
              fontSize: isSmallScreen ? fontSize.value : fontSize.value + 2,
              fontWeight: FontWeight.w600,
              color: colorScheme.primary,
            ),
          ),
          SizedBox(height: isSmallScreen ? 16 : 24),
          // Additional Info
          if (quote.category != null && quote.category!.isNotEmpty) ...[
            _buildDetailRow(
              icon: Icons.category_rounded,
              label: 'Category',
              value: quote.category!,
              colorScheme: colorScheme,
              isSmallScreen: isSmallScreen,
            ),
            SizedBox(height: isSmallScreen ? 8 : 12),
          ],
          if (quote.source != null && quote.source!.isNotEmpty) ...[
            _buildDetailRow(
              icon: Icons.source_rounded,
              label: 'Source',
              value: quote.source!,
              colorScheme: colorScheme,
              isSmallScreen: isSmallScreen,
            ),
            SizedBox(height: isSmallScreen ? 8 : 12),
          ],
          // Tags
          if (quote.tags.isNotEmpty) ...[
            Text(
              'Tags',
              style: TextStyle(
                fontSize: isSmallScreen ? 12 : 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: isSmallScreen ? 6 : 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: quote.tags.map((tag) {
                return Chip(
                  label: Text(
                    tag,
                    style: TextStyle(fontSize: isSmallScreen ? 11 : 12),
                  ),
                  backgroundColor: colorScheme.primary.withOpacity(0.1),
                  labelStyle: TextStyle(
                    color: colorScheme.primary,
                    fontSize: isSmallScreen ? 11 : 12,
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: isSmallScreen ? 8 : 12),
          ],
          // Created Date
          _buildDetailRow(
            icon: Icons.calendar_today_rounded,
            label: 'Added',
            value: DateFormat('MMMM d, yyyy').format(quote.createdAt),
            colorScheme: colorScheme,
            isSmallScreen: isSmallScreen,
          ),
          SizedBox(height: isSmallScreen ? 16 : 24),
          // Close Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(
                  vertical: isSmallScreen ? 14 : 16,
                ),
              ),
              child: Text(
                'Close',
                style: TextStyle(fontSize: isSmallScreen ? 16 : 18),
              ),
            ),
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
    required bool isSmallScreen,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: isSmallScreen ? 16 : 18, color: colorScheme.primary),
        SizedBox(width: isSmallScreen ? 8 : 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: isSmallScreen ? 10 : 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: isSmallScreen ? 2 : 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: isSmallScreen ? 12 : 14,
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