import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'services/storage_service.dart';
import 'services/download_service.dart';
import 'providers/music_provider.dart';
import 'theme/app_theme.dart';
import 'pages/greeting_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0F0F13),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize Services
  final storageService = await StorageService.init();
  final downloadService = DownloadService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => MusicProvider(
            storageService: storageService,
            downloadService: downloadService,
          ),
        ),
      ],
      child: const EvinPlayerApp(),
    ),
  );
}

class EvinPlayerApp extends StatelessWidget {
  const EvinPlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final music = context.watch<MusicProvider>();

    return MaterialApp(
      title: 'Evin Agassi Music',
      debugShowCheckedModeBanner: false,
      themeMode: music.themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      locale: music.currentLocale,
      builder: (context, child) {
        return Directionality(
          textDirection: music.isRtl ? TextDirection.rtl : TextDirection.ltr,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const GreetingPage(),
    );
  }
}
