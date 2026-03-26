// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyATKUoiVdv9W50rXobgh5qFhsCehmff1Yg",
      authDomain: "a7-cricket.firebaseapp.com",
      databaseURL: "https://a7-cricket-default-rtdb.firebaseio.com",
      projectId: "a7-cricket",
      storageBucket: "a7-cricket.firebasestorage.app",
      messagingSenderId: "127154040305",
      appId: "1:127154040305:web:4c72b512da3910e771e850",
      measurementId: "G-WSZZJ8T2YX",
    ),
  );

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppColors.bgDark,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(const ProviderScope(child: CricketA7App()));
}

class CricketA7App extends ConsumerWidget {
  const CricketA7App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Cricket A7',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}
