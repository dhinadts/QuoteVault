import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:quotevault/features/quotes/data/quote_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
// import 'package:supabase_flutter/supabase_flutter.dart';

// import 'package:supabase_flutter/supabase_flutter.dart';

class QuoteListNotifier extends StateNotifier<List<Quote>> {
  final SupabaseClient _supabase;

  QuoteListNotifier() : _supabase = Supabase.instance.client, super([]) {
    _loadQuotesFromSupabase();
  }

  Future<void> _loadQuotesFromSupabase() async {
    try {
      debugPrint('Loading quotes from Supabase...');

      final response = await _supabase
          .from('quotes')
          .select()
          .order('created_at', ascending: false);

      debugPrint('Supabase response count: ${response.length}');

      if (response != null && response is List) {
        final quotes = response
            .map((json) => Quote.fromSupabaseJson(json))
            .where((quote) => quote.id.isNotEmpty)
            .toList();

        debugPrint('Successfully loaded ${quotes.length} quotes');
        state = quotes;

        // Debug print first few quotes
        if (quotes.isNotEmpty) {
          for (var i = 0; i < min(3, quotes.length); i++) {
            debugPrint(
              'Quote $i: ${quotes[i].text} | Favorite: ${quotes[i].isFavorite}',
            );
          }
        }
      } else {
        debugPrint('No quotes found in Supabase');
        state = [];
      }
    } catch (e, stackTrace) {
      debugPrint('Error loading quotes from Supabase: $e');
      debugPrint('Stack trace: $stackTrace');
      state = [];
    }
  }

  // Add a quote to Supabase
  Future<void> addQuote(Quote quote) async {
    try {
      final newQuote = quote.copyWith(
        id: quote.id.isEmpty
            ? DateTime.now().microsecondsSinceEpoch.toString()
            : quote.id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        userId: _supabase.auth.currentUser?.id,
      );

      await _supabase.from('quotes').insert(newQuote.toSupabaseJson());

      await _loadQuotesFromSupabase();
      debugPrint('Quote added: ${newQuote.text}');
    } catch (e) {
      debugPrint('Error adding quote: $e');
      rethrow;
    }
  }

  // Update a quote in Supabase
  Future<void> updateQuote(Quote updatedQuote) async {
    try {
      final quoteToUpdate = updatedQuote.copyWith(updatedAt: DateTime.now());

      await _supabase
          .from('quotes')
          .update(quoteToUpdate.toSupabaseJson())
          .eq('id', quoteToUpdate.id);

      await _loadQuotesFromSupabase();
      debugPrint('Quote updated: ${quoteToUpdate.text}');
    } catch (e) {
      debugPrint('Error updating quote: $e');
      rethrow;
    }
  }

  // Delete a quote from Supabase
  Future<void> deleteQuote(String quoteId) async {
    try {
      await _supabase.from('quotes').delete().eq('id', quoteId);

      await _loadQuotesFromSupabase();
      debugPrint('Quote deleted: $quoteId');
    } catch (e) {
      debugPrint('Error deleting quote: $e');
      rethrow;
    }
  }

  // FAVORITES MANAGEMENT
  // ====================

  // Toggle favorite status
  Future<void> toggleFavorite(String quoteId) async {
    try {
      final quote = getQuoteById(quoteId);
      if (quote == null) return;

      final newFavoriteStatus = !quote.isFavorite;
      final now = DateTime.now();

      // Update only favorite-related fields
      await _supabase
          .from('quotes')
          .update({
            'is_favorite': newFavoriteStatus,
            'favorite_date': newFavoriteStatus
                ? now.toUtc().toIso8601String()
                : null,
            'updated_at': now.toUtc().toIso8601String(),
          })
          .eq('id', quoteId);

      // Update local state
      final updatedQuote = quote.copyWith(
        isFavorite: newFavoriteStatus,
        favoriteDate: newFavoriteStatus ? now : null,
        updatedAt: now,
      );

      final newState = state
          .map((q) => q.id == quoteId ? updatedQuote : q)
          .toList();
      state = newState;

      debugPrint(
        newFavoriteStatus
            ? 'Added to favorites: ${quote.text}'
            : 'Removed from favorites: ${quote.text}',
      );
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
      rethrow;
    }
  }

  // Add to favorites
  Future<void> addToFavorites(String quoteId) async {
    try {
      final quote = getQuoteById(quoteId);
      if (quote == null || quote.isFavorite) return;

      final now = DateTime.now();

      await _supabase
          .from('quotes')
          .update({
            'is_favorite': true,
            'favorite_date': now.toUtc().toIso8601String(),
            'updated_at': now.toUtc().toIso8601String(),
          })
          .eq('id', quoteId);

      final updatedQuote = quote.copyWith(
        isFavorite: true,
        favoriteDate: now,
        updatedAt: now,
      );

      final newState = state
          .map((q) => q.id == quoteId ? updatedQuote : q)
          .toList();
      state = newState;

      debugPrint('Added to favorites: ${quote.text}');
    } catch (e) {
      debugPrint('Error adding to favorites: $e');
      rethrow;
    }
  }

  // Remove from favorites
  Future<void> removeFromFavorites(String quoteId) async {
    try {
      final quote = getQuoteById(quoteId);
      if (quote == null || !quote.isFavorite) return;

      final now = DateTime.now();

      await _supabase
          .from('quotes')
          .update({
            'is_favorite': false,
            'favorite_date': null,
            'updated_at': now.toUtc().toIso8601String(),
          })
          .eq('id', quoteId);

      final updatedQuote = quote.copyWith(
        isFavorite: false,
        favoriteDate: null,
        updatedAt: now,
      );

      final newState = state
          .map((q) => q.id == quoteId ? updatedQuote : q)
          .toList();
      state = newState;

      debugPrint('Removed from favorites: ${quote.text}');
    } catch (e) {
      debugPrint('Error removing from favorites: $e');
      rethrow;
    }
  }

  // Clear all favorites
  Future<void> clearAllFavorites() async {
    try {
      final favoriteQuotes = state.where((q) => q.isFavorite).toList();
      if (favoriteQuotes.isEmpty) return;

      final now = DateTime.now();

      // Update all favorite quotes in Supabase
      for (final quote in favoriteQuotes) {
        await _supabase
            .from('quotes')
            .update({
              'is_favorite': false,
              'favorite_date': null,
              'updated_at': now.toUtc().toIso8601String(),
            })
            .eq('id', quote.id);
      }

      // Update local state
      final newState = state.map((quote) {
        if (quote.isFavorite) {
          return quote.copyWith(
            isFavorite: false,
            favoriteDate: null,
            updatedAt: now,
          );
        }
        return quote;
      }).toList();

      state = newState;
      debugPrint('Cleared all favorites (${favoriteQuotes.length} quotes)');
    } catch (e) {
      debugPrint('Error clearing all favorites: $e');
      rethrow;
    }
  }

  // Get favorite quotes
  List<Quote> getFavoritesSorted({bool newestFirst = true}) {
    return state.where((q) => q.isFavorite).toList()..sort((a, b) {
      final aDate = a.favoriteDate ?? DateTime(1970);
      final bDate = b.favoriteDate ?? DateTime(1970);
      return newestFirst ? bDate.compareTo(aDate) : aDate.compareTo(bDate);
    });
  }

  // Check if quote is favorite
  bool isFavorite(String quoteId) {
    return state.any((q) => q.id == quoteId && q.isFavorite);
  }

  // Get favorites count
  int get favoritesCount => state.where((q) => q.isFavorite).length;

  // Get quote by ID
  Quote? getQuoteById(String quoteId) {
    return state.firstWhereOrNull((q) => q.id == quoteId);
  }

  // Refresh quotes from Supabase
  Future<void> refreshQuotes() async {
    await _loadQuotesFromSupabase();
  }

  // Import multiple quotes
  Future<void> importQuotes(List<Quote> quotes) async {
    try {
      for (final quote in quotes) {
        final quoteToInsert = quote.copyWith(
          userId: _supabase.auth.currentUser?.id,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _supabase.from('quotes').insert(quoteToInsert.toSupabaseJson());
      }

      await _loadQuotesFromSupabase();
      debugPrint('Imported ${quotes.length} quotes');
    } catch (e) {
      debugPrint('Error importing quotes: $e');
      rethrow;
    }
  }

  // Clear all quotes
  Future<void> clearAllQuotes() async {
    try {
      final userId = _supabase.auth.currentUser?.id;

      if (userId != null) {
        // Delete only user's quotes
        await _supabase.from('quotes').delete().eq('user_id', userId);
      } else {
        // Delete all quotes (use with caution)
        await _supabase
            .from('quotes')
            .delete()
            .neq('id', ''); // Delete all rows
      }

      state = [];
      debugPrint('All quotes cleared');
    } catch (e) {
      debugPrint('Error clearing quotes: $e');
      rethrow;
    }
  }

  // Search quotes
  List<Quote> searchQuotes(String query) {
    if (query.isEmpty) return state;

    final lowercaseQuery = query.toLowerCase();
    return state.where((quote) {
      return quote.text.toLowerCase().contains(lowercaseQuery) ||
          quote.author.toLowerCase().contains(lowercaseQuery) ||
          (quote.category?.toLowerCase().contains(lowercaseQuery) ?? false);
    }).toList();
  }
}

// Helper extension for List
extension ListExtension<T> on List<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
} // Extension methods for easier quote manipulation

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

class QuoteRefreshBus {
  QuoteRefreshBus._();
  static final instance = QuoteRefreshBus._();

  final _controller = StreamController<void>.broadcast();
  Stream<void> get stream => _controller.stream;

  void trigger() => _controller.add(null);
}
