import 'package:flutter/material.dart';
import 'package:habits/screens/calendar_screen.dart';
import 'package:habits/services/habit_database.dart';
import 'package:habits/screens/all_habits_screen.dart';
import 'package:habits/screens/today_screen.dart';
import 'package:habits/theme/app_theme.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart' as path;
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialisiere Lokalisierungsdaten für Datumsformatierungen
  await initializeDateFormatting('de_DE');
  
  // Initialisiere Hive
  await Hive.initFlutter();
  
  // Lösche alle vorhandenen Boxen, da wir Schemaänderungen vorgenommen haben
  try {
    final dir = await path.getApplicationDocumentsDirectory();
    final hivePath = Directory('${dir.path}/hive');
    if (await hivePath.exists()) {
      await hivePath.delete(recursive: true);
      print('Datenbank erfolgreich gelöscht');
    }
  } catch (e) {
    print('Fehler beim Löschen der Datenbank: $e');
  }
  
  // Initialize the database
  final habitDatabase = HabitDatabase();
  await habitDatabase.init();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Habit Tracker',
      theme: AppTheme.lightTheme,
      home: const HabitTrackerApp(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HabitTrackerApp extends StatefulWidget {
  const HabitTrackerApp({super.key});

  @override
  State<HabitTrackerApp> createState() => _HabitTrackerAppState();
}

class _HabitTrackerAppState extends State<HabitTrackerApp> {
  int _selectedIndex = 0;
  
  final List<Widget> _pages = [
    const TodayScreen(),
    const AllHabitsScreen(),
    const CalendarScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.today),
            label: 'Heute',
          ),
          NavigationDestination(
            icon: Icon(Icons.list),
            label: 'Alle',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month),
            label: 'Kalender',
          ),
        ],
      ),
    );
  }
}
