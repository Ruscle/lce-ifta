import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/admin_entries_screen.dart';
import 'screens/admin_quarter_odometer_screen.dart';
import 'screens/fuel_entry_screen.dart';
import 'screens/login_screen.dart';
import 'screens/summary_screen.dart';
import 'screens/trip_entry_screen.dart';
import 'screens/user_management_screen.dart';
import 'screens/open_trip_entries_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const FuelIftaApp());
}

class FuelIftaApp extends StatelessWidget {
  const FuelIftaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IFTA Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/summary': (context) => const SummaryScreen(),
        '/fuel-entry': (context) => const FuelEntryScreen(),
        '/trip-entry': (context) => const TripEntryScreen(),
        '/user-management': (context) => const UserManagementScreen(),
        '/admin-quarter-odometer': (context) =>
            const AdminQuarterOdometerScreen(),
        '/admin-entries': (context) => const AdminEntriesScreen(),
        '/open-trip-entries': (context) => const OpenTripEntriesScreen(),
      },
    );
  }
}
