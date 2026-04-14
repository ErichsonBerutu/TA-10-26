import 'package:flutter/material.dart';
import 'pages/beranda_page.dart';
import 'pages/surat_page.dart';
import 'services/pengajuan_service.dart';
import 'models/pengajuan_model.dart';
import 'pages/pdf_preview_page.dart';
import 'pages/pengaduan_page.dart';
import 'package:flutter/services.dart';
import 'pages/splash_page.dart';
import 'pages/pengumuman_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hutabulu Mejan',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563eb)),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const SplashPage(),
    );
  }
}
