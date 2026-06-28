import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'pages/splash_page.dart';
import 'services/fcm_service.dart';

// TODO: Setelah menjalankan `flutterfire configure`, uncomment baris ini:
// import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Firebase
  // Di Web, Firebase memerlukan FirebaseOptions eksplisit.
  // Jalankan `flutterfire configure` untuk menghasilkan firebase_options.dart
  // lalu ganti baris di bawah dengan:
  //   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (!kIsWeb) {
    await Firebase.initializeApp();
    // Background message handler hanya untuk mobile (tidak didukung di Web)
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }
  // else: skip Firebase di Web sampai firebase_options.dart tersedia

  if (!kIsWeb) {
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
  }

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
