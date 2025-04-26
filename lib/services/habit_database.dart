import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/habit.dart';
import '../utils/icon_data_adapter.dart';
import '../utils/date_utils.dart' as app_date_utils;
import '../utils/streak_calculator.dart';
import 'event_bus.dart';

class HabitDatabase {
  // Box names
  static const String _habitBoxName = 'habits';
  static const String _versionBoxName = 'app_version';
  static const int _currentVersion = 2; // Increase this when model changes
  
  // EventBus für State-Updates
  final _eventBus = EventBus();
  
  // Singleton pattern
  static final HabitDatabase _instance = HabitDatabase._internal();
  
  factory HabitDatabase() {
    return _instance;
  }
  
  HabitDatabase._internal();
  
  // Initialize the database
  Future<void> init() async {
    await Hive.initFlutter();
    
    // Register adapters
    Hive.registerAdapter(HabitAdapter());
    Hive.registerAdapter(HabitFrequencyAdapter());
    Hive.registerAdapter(FrequencyTypeAdapter());
    Hive.registerAdapter(CustomFrequencyTypeAdapter());
    Hive.registerAdapter(IconDataAdapter());
    Hive.registerAdapter(ColorAdapter());
    
    // Check version and handle migrations
    await _handleMigrations();
    
    // Open boxes
    await Hive.openBox<Habit>(_habitBoxName);
  }
  
  // Handle database migrations
  Future<void> _handleMigrations() async {
    // Open version box
    final versionBox = await Hive.openBox<int>(_versionBoxName);
    final currentDbVersion = versionBox.get('version') ?? 1;
    
    // If the stored version is less than the current version, we need to migrate
    if (currentDbVersion < _currentVersion) {
      // Delete and recreate the habits box to avoid compatibility issues
      if (await Hive.boxExists(_habitBoxName)) {
        await Hive.deleteBoxFromDisk(_habitBoxName);
      }
      
      // Update version
      await versionBox.put('version', _currentVersion);
    }
  }
  
  // Reset the database (for migration/debugging purposes)
  Future<void> resetDatabase() async {
    if (await Hive.boxExists(_habitBoxName)) {
      await Hive.deleteBoxFromDisk(_habitBoxName);
    }
    
    final versionBox = await Hive.openBox<int>(_versionBoxName);
    await versionBox.put('version', _currentVersion);
    
    // Reopen the habits box
    await Hive.openBox<Habit>(_habitBoxName);
  }
  
  // Get all habits
  List<Habit> getAllHabits() {
    final box = Hive.box<Habit>(_habitBoxName);
    return box.values.toList();
  }
  
  // Get habits scheduled for today
  List<Habit> getTodayHabits() {
    return getHabitsForDate(DateTime.now());
  }
  
  // Get habits scheduled for a specific date
  List<Habit> getHabitsForDate(DateTime date) {
    final box = Hive.box<Habit>(_habitBoxName);
    final dateWithoutTime = app_date_utils.DateUtils.dateOnly(date);
    
    // Aktuelles Datum zum Vergleich
    final today = app_date_utils.DateUtils.dateOnly(DateTime.now());
    
    // Habits filtern basierend auf dem angegebenen Datum
    final allHabits = box.values.toList();
    
    // Filtern der Habits basierend auf dem angegebenen Datum
    return allHabits.where((habit) {
      // Für vergangene oder heutige Tage müssen wir nur schauen, ob er zugewiesen war
      if (dateWithoutTime.compareTo(today) <= 0) { // isBefore oder isAtSameMoment
        return _wasHabitScheduledForDate(habit, dateWithoutTime);
      }
      // Für zukünftige Tage nutzen wir die isScheduledForDate-Methode
      else {
        return _isHabitScheduledForDate(habit, dateWithoutTime);
      }
    }).toList();
  }
  
  // Prüft, ob ein Habit für ein vergangenes oder heutiges Datum geplant war
  bool _wasHabitScheduledForDate(Habit habit, DateTime date) {
    switch (habit.frequency.type) {
      case FrequencyType.daily:
        return true;
      case FrequencyType.weekly:
        return habit.frequency.daysOfWeek.contains(date.weekday);
      case FrequencyType.monthly:
        return date.day == habit.frequency.dayOfMonth;
      case FrequencyType.custom:
        switch (habit.frequency.customType) {
          case CustomFrequencyType.everyXDays:
            return _isEveryXDaysScheduledForDate(habit, date);
          case CustomFrequencyType.timesPerWeek:
            // X mal pro Woche: Immer anzeigen (wir haben diese Logik geändert)
            return true;
        }
    }
    return false;
  }
  
  // Prüfen, ob ein "alle X Tage" Habit für ein bestimmtes Datum geplant war
  bool _isEveryXDaysScheduledForDate(Habit habit, DateTime date) {
    if (habit.frequency.customDays == 0) return false;
    if (habit.completedDates.isEmpty) return true;
    
    // Suche die letzte Erledigung vor dem angegebenen Datum
    final completionDatesBeforeDate = habit.completedDates
        .where((d) => d.isBefore(date))
        .toList();
    
    if (completionDatesBeforeDate.isEmpty) return true;
    
    completionDatesBeforeDate.sort((a, b) => b.compareTo(a)); // Absteigend sortieren
    final lastCompletion = app_date_utils.DateUtils.dateOnly(completionDatesBeforeDate.first);
    
    final daysSinceCompletion = 
        app_date_utils.DateUtils.daysBetween(lastCompletion, date);
    return daysSinceCompletion % habit.frequency.customDays == 0;
  }
  
  // Check if a habit is scheduled for a future specific date
  bool _isHabitScheduledForDate(Habit habit, DateTime date) {
    final weekday = date.weekday;
    
    switch (habit.frequency.type) {
      case FrequencyType.daily:
        return true;
      case FrequencyType.weekly:
        return habit.frequency.daysOfWeek.contains(weekday);
      case FrequencyType.monthly:
        return date.day == habit.frequency.dayOfMonth;
      case FrequencyType.custom:
        switch (habit.frequency.customType) {
          case CustomFrequencyType.everyXDays:
            return _isEveryXDaysScheduledForDate(habit, date);
          case CustomFrequencyType.timesPerWeek:
            // Bei X mal pro Woche: Prüfen, ob das wöchentliche Ziel bereits erreicht wurde
            final startOfWeek = app_date_utils.DateUtils.getStartOfWeek(date);
            final completionsInWeekUpToDate = habit.completedDates
                .where((d) {
                  final dateOnly = app_date_utils.DateUtils.dateOnly(d);
                  return dateOnly.isAfter(startOfWeek.subtract(const Duration(days: 1))) && 
                         dateOnly.isBefore(date);
                })
                .length;
            
            return completionsInWeekUpToDate < habit.frequency.timesPerWeek;
        }
    }
    return false;
  }
  
  // Prüft, ob ein Habit an einem bestimmten Datum erledigt wurde
  bool isHabitCompletedOnDate(Habit habit, DateTime date) {
    final dateWithoutTime = app_date_utils.DateUtils.dateOnly(date);
    
    return habit.completedDates.any((completionDate) {
      final completionDateWithoutTime = app_date_utils.DateUtils.dateOnly(completionDate);
      return app_date_utils.DateUtils.isSameDay(completionDateWithoutTime, dateWithoutTime);
    });
  }
  
  // Markiert einen Habit als erledigt für ein bestimmtes Datum
  Future<void> markHabitAsCompletedForDate(String id, DateTime date) async {
    final box = Hive.box<Habit>(_habitBoxName);
    final habit = box.get(id);
    
    if (habit != null) {
      final today = app_date_utils.DateUtils.dateOnly(DateTime.now());
      final dateWithoutTime = app_date_utils.DateUtils.dateOnly(date);
      
      // Überprüfe, ob das Datum heute oder in der Vergangenheit ist
      if (dateWithoutTime.compareTo(today) <= 0) { // isBefore oder isAtSameMoment
        // Überprüfen, ob das Datum bereits in completedDates vorhanden ist
        bool alreadyCompleted = isHabitCompletedOnDate(habit, dateWithoutTime);
        
        if (!alreadyCompleted) {
          // Datum zur completedDates-Liste hinzufügen
          habit.completedDates.add(date);
          
          // Streak und lastCompleted neu berechnen
          _recalculateStreak(habit);
          
          await box.put(id, habit);
          _eventBus.fireHabitEvent(HabitEvent.habitCompleted);
        }
      }
    }
  }
  
  // Entfernt die Markierung eines Habits als erledigt für ein bestimmtes Datum
  Future<void> unmarkHabitCompletionForDate(String id, DateTime date) async {
    final box = Hive.box<Habit>(_habitBoxName);
    final habit = box.get(id);
    
    if (habit != null) {
      final dateWithoutTime = app_date_utils.DateUtils.dateOnly(date);
      
      // Entferne das angegebene Datum aus completedDates
      habit.completedDates.removeWhere((completionDate) {
        final completionDateWithoutTime = app_date_utils.DateUtils.dateOnly(completionDate);
        return app_date_utils.DateUtils.isSameDay(completionDateWithoutTime, dateWithoutTime);
      });
      
      // Streak und lastCompleted neu berechnen
      _recalculateStreak(habit);
      
      await box.put(id, habit);
      _eventBus.fireHabitEvent(HabitEvent.habitUncompleted);
    }
  }
  
  // Berechnet den Streak und das letzte Erledigungsdatum neu
  void _recalculateStreak(Habit habit) {
    if (habit.completedDates.isEmpty) {
      habit.streak = 0;
      habit.lastCompleted = DateTime(2000); // Ein sehr altes Datum als "nie erledigt" Marker
      return;
    }
    
    // Sortiere die Daten absteigend (neuestes zuerst)
    habit.completedDates.sort((a, b) => b.compareTo(a));
    
    // Setze das letzte Erledigungsdatum
    habit.lastCompleted = habit.completedDates.first;
    
    // Berechne den Streak mit dem StreakCalculator
    final today = DateTime.now();
    habit.streak = StreakCalculator.calculateStreak(habit, today);
  }
  
  // Gibt den Fortschritt einer "X mal pro Woche" Gewohnheit zurück
  (int completed, int required) getWeeklyCompletionStatus(Habit habit, DateTime date) {
    return StreakCalculator.calculateWeeklyCompletionStatus(habit, date);
  }
  
  // Fügt eine neue Gewohnheit hinzu
  Future<void> addHabit(Habit habit) async {
    final box = Hive.box<Habit>(_habitBoxName);
    await box.put(habit.id, habit);
    _eventBus.fireHabitEvent(HabitEvent.habitAdded);
  }
  
  // Aktualisiert eine bestehende Gewohnheit
  Future<void> updateHabit(Habit habit) async {
    final box = Hive.box<Habit>(_habitBoxName);
    await box.put(habit.id, habit);
    _eventBus.fireHabitEvent(HabitEvent.habitUpdated);
  }
  
  // Löscht eine Gewohnheit
  Future<void> deleteHabit(String id) async {
    final box = Hive.box<Habit>(_habitBoxName);
    await box.delete(id);
    _eventBus.fireHabitEvent(HabitEvent.habitDeleted);
  }
  
  // Markiert eine Gewohnheit als erledigt für heute
  Future<void> markHabitAsCompleted(String id) async {
    await markHabitAsCompletedForDate(id, DateTime.now());
  }
  
  // Entfernt die Markierung einer Gewohnheit als erledigt für heute
  Future<void> unmarkHabitCompletion(String id) async {
    await unmarkHabitCompletionForDate(id, DateTime.now());
  }
}