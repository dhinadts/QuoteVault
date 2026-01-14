import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:quotevault/features/quotes/data/quote_model.dart';
import 'package:quotevault/features/quotes/providers/quotes_list_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

final dailyQuoteProvider = NotifierProvider<DailyQuoteNotifier, Quote?>(
  DailyQuoteNotifier.new,
);

class DailyQuoteNotifier extends Notifier<Quote?> {
  static const _dateKey = 'daily_quote_date';
  static const _idKey = 'daily_quote_id';

  @override
  Quote? build() {
    _loadTodayQuote();
    return null;
  }

  Future<void> _loadTodayQuote() async {
    final quotes = ref.read(quoteListProvider);
    if (quotes.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final savedDate = prefs.getString(_dateKey);
    final savedId = prefs.getString(_idKey);

    if (savedDate == today && savedId != null) {
      state = quotes.firstWhere(
        (q) => q.id == savedId,
        orElse: () => quotes.first,
      );
      return;
    }

    // New day → new quote
    final newQuote = quotes[DateTime.now().day % quotes.length];
    await prefs.setString(_dateKey, today);
    await prefs.setString(_idKey, newQuote.id);
    state = newQuote;
  }

  Future<void> forceRefresh() async {
    final quotes = ref.read(quoteListProvider);
    if (quotes.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final newQuote = quotes[DateTime.now().millisecond % quotes.length];
    await prefs.setString(_dateKey, today);
    await prefs.setString(_idKey, newQuote.id);
    state = newQuote;
  }
}
