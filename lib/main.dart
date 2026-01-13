import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quotevault/core/providers/theme_provider.dart';
import 'package:quotevault/features/quotes/presentation/quote_list_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';

void main() async {
  
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://goadwbzougvmnizjywhq.supabase.co',
    anonKey: 'sb_publishable_25g48adJfc3y9GxD72gyqg_8_2uLLiC',
  );
  runApp(const ProviderScope(child: MyApp()));
}
