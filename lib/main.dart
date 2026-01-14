import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:quotevault/features/quotes/providers/notification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize notifications
  // await NotificationService().initialize();

  // await FlutterLocalNotificationsPlugin().initialize(initializationSettings);

  await Supabase.initialize(
    url: 'https://goadwbzougvmnizjywhq.supabase.co',
    anonKey: 'sb_publishable_25g48adJfc3y9GxD72gyqg_8_2uLLiC',
  );
  runApp(const ProviderScope(child: MyApp()));
}
