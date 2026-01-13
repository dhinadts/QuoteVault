import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:quotevault/features/quotes/providers/quote_share_provider.dart';
import '../../../core/providers/supabase_provider.dart';
import '../data/quote_model.dart';
import 'quote_card_template.dart';

// Provider for selected template
final selectedTemplateProvider = StateProvider<QuoteCardTemplate>((ref) {
  return QuoteCardTemplates.templates.first;
});

// Provider for share service
final quoteShareServiceProvider = Provider((ref) => QuoteShareService());

// Provider for share settings
final shareSettingsProvider =
    StateNotifierProvider<ShareSettingsNotifier, ShareSettings>(
      (ref) => ShareSettingsNotifier(),
    );

class ShareSettings {
  final bool includeCategory;
  final bool includeAppBranding;
  final String customWatermark;
  final double imageQuality;

  ShareSettings({
    this.includeCategory = true,
    this.includeAppBranding = false,
    this.customWatermark = '',
    this.imageQuality = 1.0,
  });

  ShareSettings copyWith({
    bool? includeCategory,
    bool? includeAppBranding,
    String? customWatermark,
    double? imageQuality,
  }) {
    return ShareSettings(
      includeCategory: includeCategory ?? this.includeCategory,
      includeAppBranding: includeAppBranding ?? this.includeAppBranding,
      customWatermark: customWatermark ?? this.customWatermark,
      imageQuality: imageQuality ?? this.imageQuality,
    );
  }
}

class ShareSettingsNotifier extends StateNotifier<ShareSettings> {
  ShareSettingsNotifier() : super(ShareSettings());

  void toggleIncludeCategory() {
    state = state.copyWith(includeCategory: !state.includeCategory);
  }

  void toggleIncludeBranding() {
    state = state.copyWith(includeAppBranding: !state.includeAppBranding);
  }

  void setCustomWatermark(String watermark) {
    state = state.copyWith(customWatermark: watermark);
  }

  void setImageQuality(double quality) {
    state = state.copyWith(imageQuality: quality.clamp(0.1, 1.0));
  }
}

final quotesProvider = FutureProvider<List<Quote>>((ref) async {
  final client = ref.read(supabaseProvider);

  try {
    final response = await client
        .from('quotes')
        .select()
        .order('created_at', ascending: false);

    // Debug log
    debugPrint('Fetched ${response.length} quotes');

    if (response is List) {
      return response.map((e) => Quote.fromJson(e)).toList();
    }

    return [];
  } catch (e) {
    debugPrint('Error fetching quotes: $e');
    rethrow;
  }
});
