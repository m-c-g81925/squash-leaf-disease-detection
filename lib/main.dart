import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz_location;

import 'core/services/notification_service.dart';
import 'firebase_options.dart';
import 'features/splash/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Supabase
  await Supabase.initialize(
    url: 'https://vitnxrbywjldwqeouhsy.supabase.co',
    publishableKey: 'sb_publishable_L99e6Njxfj2Xc_0eVYM1WA_ZIAeu1PG',
  );

  // Timezone
  tz.initializeTimeZones();

  tz_location.setLocalLocation(
    tz_location.getLocation('Asia/Manila'),
  );

  // Notifications
  await NotificationService.init();

  runApp(const SquashDiseaseApp());
}

class SquashDiseaseApp extends StatelessWidget {
  const SquashDiseaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Squash Leaf Disease Detection',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF179E43),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F7FB),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}