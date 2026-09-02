import 'package:cloudinary_flutter/cloudinary_context.dart';
import 'package:cloudinary_flutter/cloudinary_object.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'app/router.dart';
import 'app/theme.dart';
import 'firebase_options.dart';
import 'shared/config/cloudinary_config.dart';
import 'shared/providers/theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initializeFirebase();
  _initializeCloudinary();
  await initializeDateFormatting('tr');
  Intl.defaultLocale = 'tr';
  runApp(const ProviderScope(child: AkdenizCepApp()));
}

/// `CldImage` widget'i acikca bir Cloudinary nesnesi verilmediginde bu global
/// yapilandirmaya duser. Paket `CloudinaryContext`'i deprecated isaretlemis
/// olsa da Cloudinary'nin onerdigi kurulum yolu hala bu.
/// Yukleme bu nesne uzerinden yapilmaz — bkz. `CloudinaryService`.
void _initializeCloudinary() {
  // ignore: deprecated_member_use
  CloudinaryContext.cloudinary = CloudinaryObject.fromCloudName(
    cloudName: CloudinaryConfig.cloudName,
  );
}

Future<void> _initializeFirebase() async {
  if (Firebase.apps.isNotEmpty) return;

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on FirebaseException catch (e) {
    if (e.code != 'duplicate-app') rethrow;
  }
}

class AkdenizCepApp extends ConsumerWidget {
  const AkdenizCepApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Akdeniz Cep',
      debugShowCheckedModeBanner: false,
      // Tarih/saat seçicileri ve Material metinleri Türkçe olsun.
      locale: const Locale('tr'),
      supportedLocales: const [Locale('tr'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
