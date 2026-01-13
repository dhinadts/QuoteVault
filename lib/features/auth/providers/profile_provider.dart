import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quotevault/core/providers/theme_provider.dart';
import '../../../core/providers/supabase_provider.dart';

class ProfileSyncService {
  final Ref ref;

  ProfileSyncService(this.ref);

  Future<void> syncThemeSettingsToProfile() async {
    try {
      final settings = ref.read(themeSettingsProvider);
      final supabase = ref.read(supabaseProvider);
      final user = supabase.auth.currentUser;

      if (user == null || !settings.syncWithProfile) return;

      await supabase.from('profiles').upsert({
        'id': user.id,
        'theme_settings': settings.toJson(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      print('✅ Theme settings synced to profile');
    } catch (e) {
      print('❌ Error syncing theme settings: $e');
    }
  }

  Future<void> loadThemeSettingsFromProfile() async {
    try {
      final settings = ref.read(themeSettingsProvider);
      final supabase = ref.read(supabaseProvider);
      final user = supabase.auth.currentUser;

      if (user == null || !settings.syncWithProfile) return;

      final response = await supabase
          .from('profiles')
          .select('theme_settings')
          .eq('id', user.id)
          .single()
          .onError((error, stackTrace) => {});

      if (response != null && response['theme_settings'] != null) {
        final themeSettingsJson =
            response['theme_settings'] as Map<String, dynamic>;
        final loadedSettings = ThemeSettings.fromJson(themeSettingsJson);

        ref.read(themeSettingsProvider.notifier)
          ..setThemeMode(loadedSettings.themeMode)
          ..setThemeColor(loadedSettings.themeColor)
          ..setFontSize(loadedSettings.fontSize)
          ..setSyncWithProfile(loadedSettings.syncWithProfile);

        print('✅ Theme settings loaded from profile');
      }
    } catch (e) {
      print('❌ Error loading theme settings: $e');
    }
  }
}

final profileSyncServiceProvider = Provider((ref) => ProfileSyncService(ref));

final profileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final supabase = ref.read(supabaseProvider);
  final user = supabase.auth.currentUser;

  if (user == null) return null;

  try {
    return await supabase
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();
  } catch (_) {
    return null;
  }
});



/* final profileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final supabase = ref.read(supabaseProvider);
  final user = supabase.auth.currentUser;

  if (user == null) return null;

  final res = await supabase
      .from('profiles')
      .select()
      .eq('id', user.id)
      .maybeSingle();

  return res;
});
 */