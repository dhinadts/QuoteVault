import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../core/providers/supabase_provider.dart';

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>(
      (ref) => AuthController(ref),
    );

class AuthController extends StateNotifier<AsyncValue<void>> {
  AuthController(this.ref) : super(const AsyncData(null));

  final Ref ref;

  // -----------------------
  // SIGN UP
  // -----------------------
  Future<void> signUp({required String email, required String password}) async {
    state = const AsyncLoading();
    try {
      final supabase = ref.read(supabaseProvider);

      final res = await supabase.auth.signUp(email: email, password: password);

      final user = res.user;
      if (user != null) {
        await supabase.from('profiles').insert({
          'id': user.id,
          'name': '',
          'avatar_url': '',
        });
      }

      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  // -----------------------
  // SIGN IN
  // -----------------------
  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncLoading();
    try {
      final supabase = ref.read(supabaseProvider);
      await supabase.auth.signInWithPassword(email: email, password: password);
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  // -----------------------
  // LOGOUT ✅
  // -----------------------
  Future<void> logout() async {
    state = const AsyncLoading();
    try {
      await ref.read(supabaseProvider).auth.signOut();
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> resetPassword(String email) async {
    await ref.read(supabaseProvider).auth.resetPasswordForEmail(email);
  }

  /* Future<void> logout() async {
  await ref.read(supabaseProvider).auth.signOut();
} */
}
