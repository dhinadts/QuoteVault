// favorites_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quotevault/features/quotes/presentation/quote_list_screen.dart';
import 'package:quotevault/features/quotes/providers/quotes_list_provider.dart';
// import 'quote_card.dart';
// import 'quote_list_provider.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoriteQuotesProvider);
    final favoritesCount = ref.watch(favoritesCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
        actions: [
          if (favorites.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _showClearAllDialog(context, ref),
            ),
        ],
      ),
      body: favorites.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border_rounded,
                    size: 64,
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No favorites yet',
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the heart icon on any quote',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                final quote = favorites[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: QuoteCard(quote: quote),
                );
              },
            ),
      floatingActionButton: favorites.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () {
                // Share all favorites
                _shareAllFavorites(context, ref);
              },
              icon: const Icon(Icons.share_rounded),
              label: const Text('Share All'),
            )
          : null,
    );
  }

  Future<void> _showClearAllDialog(BuildContext context, WidgetRef ref) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Favorites?'),
        content: const Text('This will remove all quotes from your favorites.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(quoteListProvider.notifier).clearAllFavorites();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All favorites cleared')),
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
    for (final quote in favorites) {
      buffer.writeln('"${quote.text}"');
      buffer.writeln('— ${quote.author}');
      if (quote.category != null) {
        buffer.writeln('#${quote.category}');
      }
      buffer.writeln(); // Empty line between quotes
    }

    // Share the text
    // You could also implement image sharing for all quotes
  }
}
