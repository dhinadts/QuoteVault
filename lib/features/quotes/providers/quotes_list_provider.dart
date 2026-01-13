import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:quotevault/features/quotes/data/quote_model.dart';
import 'quote_provider.dart'; // Your original quotes provider

// Provider for search query - ONLY ONE DEFINITION
final searchQueryProvider = StateProvider<String>((ref) => '');

// Provider for selected category filter
final selectedCategoryProvider = StateProvider<String?>((ref) => null);

// Provider for getting all unique categories
// Provider for getting all unique categories with "Uncategorized" option
final categoriesProvider = Provider<List<String>>((ref) {
  final quotes = ref.watch(quotesProvider);

  return quotes.when(
    data: (quotes) {
      // Create a set for unique categories
      final categorySet = <String>{};

      for (final quote in quotes) {
        if (quote.category != null && quote.category!.trim().isNotEmpty) {
          categorySet.add(quote.category!);
        } else {
          categorySet.add('Uncategorized');
        }
      }

      // Convert to list and sort
      final categories = categorySet.toList();
      categories.sort();

      // Return with 'All' at the beginning
      return ['All', ...categories];
    },
    loading: () => ['All'],
    error: (_, __) => ['All'],
  );
});

// Combined provider for filtered quotes based on search and category
final filteredQuotesProvider = Provider<List<Quote>>((ref) {
  final quotes = ref.watch(quotesProvider);
  final searchQuery = ref.watch(searchQueryProvider);
  final selectedCategory = ref.watch(selectedCategoryProvider);

  return quotes.when(
    data: (allQuotes) {
      List<Quote> filtered = allQuotes;

      // Apply category filter
      if (selectedCategory != null && selectedCategory != 'All') {
        filtered = filtered
            .where((quote) => quote.category == selectedCategory)
            .toList();
      }

      // Apply search filter
      if (searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        filtered = filtered.where((quote) {
          final matchesText = quote.text.toLowerCase().contains(query);
          final matchesAuthor = quote.author.toLowerCase().contains(query);
          final matchesCategory =
              quote.category?.toLowerCase().contains(query) ?? false;
          return matchesText || matchesAuthor || matchesCategory;
        }).toList();
      }

      return filtered;
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

// Provider for quote statistics
final quoteStatsProvider = Provider<QuoteStats>((ref) {
  final allQuotes = ref.watch(quotesProvider);
  final filteredQuotes = ref.watch(filteredQuotesProvider);
  final categories = ref.watch(categoriesProvider);

  return allQuotes.when(
    data: (quotes) {
      // Calculate category counts
      final categoryCounts = <String, int>{};
      for (final quote in quotes) {
        final category = quote.category ?? 'Uncategorized';
        categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
      }

      return QuoteStats(
        totalQuotes: quotes.length,
        filteredCount: filteredQuotes.length,
        categoryCounts: categoryCounts,
        totalCategories: categories.length - 1, // Exclude "All"
      );
    },
    loading: () => QuoteStats.initial(),
    error: (_, __) => QuoteStats.initial(),
  );
});

// Stats model
class QuoteStats {
  final int totalQuotes;
  final int filteredCount;
  final Map<String, int> categoryCounts;
  final int totalCategories;

  QuoteStats({
    required this.totalQuotes,
    required this.filteredCount,
    required this.categoryCounts,
    required this.totalCategories,
  });

  factory QuoteStats.initial() => QuoteStats(
    totalQuotes: 0,
    filteredCount: 0,
    categoryCounts: {},
    totalCategories: 0,
  );
}
