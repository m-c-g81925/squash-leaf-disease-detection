import 'package:flutter/material.dart';

// Screens
import '../features/home/home_screen.dart';
import '../features/disease/disease_library_screen.dart';
import '../features/calendar/calendar_screen.dart';
import '../features/scan/scan_screen.dart';
import '../features/scan/scan_history_screen.dart';

class AppRoutes {
  static const String home = '/';
  static const String scan = '/scan';
  static const String calendar = '/calendar';
  static const String diseases = '/diseases';
  static const String scanHistory = '/scan-history';

  static final Map<String, WidgetBuilder> routes = {
    home: (context) => HomeScreen(
          onTabChange: (_) {},
        ),
    scan: (context) => const ScanScreen(),
    calendar: (context) => const CalendarScreen(),
    diseases: (context) => const DiseaseLibraryScreen(),
    scanHistory: (context) => const ScanHistoryScreen(),
  };
}