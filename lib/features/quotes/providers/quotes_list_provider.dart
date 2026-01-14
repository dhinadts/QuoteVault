import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:quotevault/features/quotes/data/quote_model.dart';

// Providers for quotes management
// ================================

// Main quotes provider - replace with your actual quotes provider
// This should be your main source of quotes (could be from API, local DB, etc.)
final quotesProvider = StateProvider<List<Quote>>((ref) => []);

// Provider for managing quotes list with Hive persistence
final quoteListProvider = StateNotifierProvider<QuoteListNotifier, List<Quote>>(
  (ref) => QuoteListNotifier(),
);

// Provider for search query
final searchQueryProvider = StateProvider<String>((ref) => '');

// Provider for selected category filter
final selectedCategoryProvider = StateProvider<String?>((ref) => null);

// Provider for getting all unique categories with "Uncategorized" option
final categoriesProvider = Provider<List<String>>((ref) {
  final quotes = ref.watch(quoteListProvider);

  // Create a set for unique categories
  final categorySet = <String>{'All'}; // Always include 'All'

  for (final quote in quotes) {
    if (quote.category != null && quote.category!.trim().isNotEmpty) {
      categorySet.add(quote.category!);
    } else {
      categorySet.add('Uncategorized');
    }
  }

  // Convert to list and sort
  final categories = categorySet.toList();
  categories.sort((a, b) {
    if (a == 'All') return -1;
    if (b == 'All') return 1;
    return a.compareTo(b);
  });

  return categories;
});

// Combined provider for filtered quotes based on search and category
final filteredQuotesProvider = Provider<List<Quote>>((ref) {
  final quotes = ref.watch(quoteListProvider);
  final searchQuery = ref.watch(searchQueryProvider);
  final selectedCategory = ref.watch(selectedCategoryProvider);

  List<Quote> filtered = quotes;

  // Apply category filter
  if (selectedCategory != null && selectedCategory != 'All') {
    if (selectedCategory == 'Uncategorized') {
      filtered = filtered
          .where((quote) => quote.category == null || quote.category!.isEmpty)
          .toList();
    } else {
      filtered = filtered
          .where((quote) => quote.category == selectedCategory)
          .toList();
    }
  }

  // Apply search filter
  if (searchQuery.isNotEmpty) {
    final query = searchQuery.toLowerCase();
    filtered = filtered.where((quote) {
      final matchesText = quote.text.toLowerCase().contains(query);
      final matchesAuthor = quote.author.toLowerCase().contains(query);
      final matchesCategory =
          quote.category?.toLowerCase().contains(query) ?? false;
      final matchesTags = quote.tags.any(
        (tag) => tag.toLowerCase().contains(query),
      );
      final matchesNotes = quote.notes?.toLowerCase().contains(query) ?? false;
      final matchesSource =
          quote.source?.toLowerCase().contains(query) ?? false;

      return matchesText ||
          matchesAuthor ||
          matchesCategory ||
          matchesTags ||
          matchesNotes ||
          matchesSource;
    }).toList();
  }

  return filtered;
});

// Provider for favorites only
final favoriteQuotesProvider = Provider<List<Quote>>((ref) {
  final allQuotes = ref.watch(quoteListProvider);
  return allQuotes.where((quote) => quote.isFavorite).toList();
});

// Provider for favorites count
final favoritesCountProvider = Provider<int>((ref) {
  return ref.watch(favoriteQuotesProvider).length;
});

// Provider for checking if a specific quote is favorite
final isFavoriteProvider = Provider.family<bool, String>((ref, quoteId) {
  final allQuotes = ref.watch(quoteListProvider);
  final quote = allQuotes.firstWhere(
    (q) => q.id == quoteId,
    orElse: () => Quote.empty(),
  );
  return quote.isFavorite;
});

// Provider for quote statistics
final quoteStatsProvider = Provider<QuoteStats>((ref) {
  final allQuotes = ref.watch(quoteListProvider);
  final filteredQuotes = ref.watch(filteredQuotesProvider);
  final categories = ref.watch(categoriesProvider);

  // Calculate category counts
  final categoryCounts = <String, int>{'All': allQuotes.length};

  for (final quote in allQuotes) {
    final category = quote.category?.trim().isNotEmpty == true
        ? quote.category!
        : 'Uncategorized';
    categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
  }

  return QuoteStats(
    totalQuotes: allQuotes.length,
    filteredCount: filteredQuotes.length,
    categoryCounts: categoryCounts,
    totalCategories: categories.length - 1, // Exclude "All"
    favoriteCount: allQuotes.where((q) => q.isFavorite).length,
    uncategorizedCount: allQuotes
        .where((q) => q.category == null || q.category!.isEmpty)
        .length,
  );
});

// Quote statistics model
class QuoteStats {
  final int totalQuotes;
  final int filteredCount;
  final Map<String, int> categoryCounts;
  final int totalCategories;
  final int favoriteCount;
  final int uncategorizedCount;

  QuoteStats({
    required this.totalQuotes,
    required this.filteredCount,
    required this.categoryCounts,
    required this.totalCategories,
    required this.favoriteCount,
    required this.uncategorizedCount,
  });

  factory QuoteStats.initial() => QuoteStats(
    totalQuotes: 0,
    filteredCount: 0,
    categoryCounts: {},
    totalCategories: 0,
    favoriteCount: 0,
    uncategorizedCount: 0,
  );

  // Get percentage of filtered quotes
  double get filteredPercentage =>
      totalQuotes > 0 ? (filteredCount / totalQuotes * 100) : 0;

  // Get percentage of favorites
  double get favoritePercentage =>
      totalQuotes > 0 ? (favoriteCount / totalQuotes * 100) : 0;

  @override
  String toString() {
    return 'QuoteStats(total: $totalQuotes, filtered: $filteredCount, favorites: $favoriteCount, categories: $totalCategories)';
  }
}

// Notifier class for managing quotes
class QuoteListNotifier extends StateNotifier<List<Quote>> {
  // For simplicity, we'll use a simple list instead of Hive
  // Replace with your actual storage solution (SharedPreferences, SQLite, etc.)
  final List<Quote> _initialQuotes = [];

  QuoteListNotifier() : super([]) {
    _loadInitialQuotes();
  }

  Future<void> _loadInitialQuotes() async {
    // Load initial quotes from your storage
    // This could be from SharedPreferences, SQLite, or an API
    // For now, we'll use an empty list
    state = _initialQuotes;
  }

  // Add a quote
  Future<void> addQuote(Quote quote) async {
    final newQuote = quote.copyWith(
      id: quote.id.isEmpty
          ? DateTime.now().microsecondsSinceEpoch.toString()
          : quote.id,
      createdAt: DateTime.now(),
    );

    // Save to your storage here
    state = [...state, newQuote];

    debugPrint('Quote added: ${newQuote.text}');
  }

  // Update a quote
  Future<void> updateQuote(Quote updatedQuote) async {
    final index = state.indexWhere((q) => q.id == updatedQuote.id);
    if (index != -1) {
      // Update in your storage here
      final newState = List<Quote>.from(state);
      newState[index] = updatedQuote;
      state = newState;

      debugPrint('Quote updated: ${updatedQuote.text}');
    }
  }

  // Delete a quote
  Future<void> deleteQuote(String quoteId) async {
    // Delete from your storage here
    state = state.where((quote) => quote.id != quoteId).toList();

    debugPrint('Quote deleted: $quoteId');
  }

  // Toggle favorite status
  Future<void> toggleFavorite(String quoteId) async {
    final index = state.indexWhere((q) => q.id == quoteId);
    if (index != -1) {
      final quote = state[index];
      final updatedQuote = quote.copyWith(
        isFavorite: !quote.isFavorite,
        favoriteDate: !quote.isFavorite ? DateTime.now() : null,
      );

      // Update in your storage here
      final newState = List<Quote>.from(state);
      newState[index] = updatedQuote;
      state = newState;

      debugPrint(
        updatedQuote.isFavorite
            ? 'Added to favorites: ${quote.text}'
            : 'Removed from favorites: ${quote.text}',
      );
    }
  }

  // Add to favorites
  Future<void> addToFavorites(String quoteId) async {
    final index = state.indexWhere((q) => q.id == quoteId);
    if (index != -1 && !state[index].isFavorite) {
      final quote = state[index];
      final updatedQuote = quote.copyWith(
        isFavorite: true,
        favoriteDate: DateTime.now(),
      );

      final newState = List<Quote>.from(state);
      newState[index] = updatedQuote;
      state = newState;
    }
  }

  // Remove from favorites
  Future<void> removeFromFavorites(String quoteId) async {
    final index = state.indexWhere((q) => q.id == quoteId);
    if (index != -1 && state[index].isFavorite) {
      final quote = state[index];
      final updatedQuote = quote.copyWith(
        isFavorite: false,
        favoriteDate: null,
      );

      final newState = List<Quote>.from(state);
      newState[index] = updatedQuote;
      state = newState;
    }
  }

  // Get favorite quotes sorted by favorite date
  List<Quote> getFavoritesSorted() {
    return state.where((quote) => quote.isFavorite).toList()..sort((a, b) {
      if (a.favoriteDate == null || b.favoriteDate == null) return 0;
      return b.favoriteDate!.compareTo(a.favoriteDate!);
    });
  }

  // Check if a quote is favorite
  bool isFavorite(String quoteId) {
    final quote = state.firstWhere(
      (q) => q.id == quoteId,
      orElse: () => Quote.empty(),
    );
    return quote.isFavorite;
  }

  // Clear all favorites
  Future<void> clearAllFavorites() async {
    final newState = state.map((quote) {
      if (quote.isFavorite) {
        return quote.copyWith(isFavorite: false, favoriteDate: null);
      }
      return quote;
    }).toList();

    state = newState;
    debugPrint('All favorites cleared');
  }

  // Search quotes
  List<Quote> searchQuotes(String query) {
    if (query.isEmpty) return state;

    final lowercaseQuery = query.toLowerCase();
    return state.where((quote) {
      return quote.text.toLowerCase().contains(lowercaseQuery) ||
          quote.author.toLowerCase().contains(lowercaseQuery) ||
          (quote.category?.toLowerCase().contains(lowercaseQuery) ?? false) ||
          quote.tags.any((tag) => tag.toLowerCase().contains(lowercaseQuery)) ||
          (quote.notes?.toLowerCase().contains(lowercaseQuery) ?? false) ||
          (quote.source?.toLowerCase().contains(lowercaseQuery) ?? false);
    }).toList();
  }

  // Get quotes by category
  List<Quote> getQuotesByCategory(String category) {
    if (category == 'Uncategorized') {
      return state
          .where((quote) => quote.category == null || quote.category!.isEmpty)
          .toList();
    }
    return state
        .where(
          (quote) => quote.category?.toLowerCase() == category.toLowerCase(),
        )
        .toList();
  }

  // Get quotes by tag
  List<Quote> getQuotesByTag(String tag) {
    return state.where((quote) => quote.tags.contains(tag)).toList();
  }

  // Import quotes from JSON
  Future<void> importQuotes(List<Map<String, dynamic>> jsonList) async {
    final importedQuotes = jsonList
        .map((json) => Quote.fromJson(json))
        .toList();
    state = [...state, ...importedQuotes];
    debugPrint('Imported ${importedQuotes.length} quotes');
  }

  // Export quotes to JSON
  List<Map<String, dynamic>> exportQuotes() {
    return state.map((quote) => quote.toJson()).toList();
  }

  // Clear all quotes
  Future<void> clearAllQuotes() async {
    state = [];
    debugPrint('All quotes cleared');
  }

  // Get quote by ID
  Quote? getQuoteById(String quoteId) {
    try {
      return state.firstWhere((q) => q.id == quoteId);
    } catch (e) {
      return null;
    }
  }

  // Get random quote
  Quote? getRandomQuote() {
    if (state.isEmpty) return null;
    final random = DateTime.now().microsecondsSinceEpoch % state.length;
    return state[random];
  }

  // Get quotes count by author
  Map<String, int> getAuthorStats() {
    final authorCounts = <String, int>{};
    for (final quote in state) {
      authorCounts[quote.author] = (authorCounts[quote.author] ?? 0) + 1;
    }
    return authorCounts;
  }

  // Get most common tags
  Map<String, int> getTagStats() {
    final tagCounts = <String, int>{};
    for (final quote in state) {
      for (final tag in quote.tags) {
        tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
      }
    }
    return tagCounts;
  }
}

// Extension methods for easier quote manipulation
extension QuoteListExtension on List<Quote> {
  // Sort quotes by date (newest first)
  List<Quote> sortByDate({bool ascending = false}) {
    return List.from(this)..sort((a, b) {
      final comparison = a.createdAt.compareTo(b.createdAt);
      return ascending ? comparison : -comparison;
    });
  }

  // Sort quotes by author
  List<Quote> sortByAuthor({bool ascending = true}) {
    return List.from(this)..sort((a, b) {
      final comparison = a.author.compareTo(b.author);
      return ascending ? comparison : -comparison;
    });
  }

  // Sort quotes by text
  List<Quote> sortByText({bool ascending = true}) {
    return List.from(this)..sort((a, b) {
      final comparison = a.text.compareTo(b.text);
      return ascending ? comparison : -comparison;
    });
  }

  // Get quotes by author
  List<Quote> getByAuthor(String author) {
    return where(
      (quote) => quote.author.toLowerCase().contains(author.toLowerCase()),
    ).toList();
  }

  // Get unique authors
  List<String> get uniqueAuthors {
    return map((quote) => quote.author).toSet().toList()..sort();
  }

  // Get all tags
  List<String> get allTags {
    final allTags = <String>{};
    for (final quote in this) {
      allTags.addAll(quote.tags);
    }
    return allTags.toList()..sort();
  }
}
