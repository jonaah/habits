import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/habit.dart';
import '../utils/icon_data_adapter.dart';
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
    Hive.registerAdapter(CustomFrequencyTypeAdapter()); // Register CustomFrequencyType adapter
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
    final box = Hive.box<Habit>(_habitBoxName);
    return box.values.where((habit) => habit.isScheduledForToday()).toList();
  }
  
  // Get habits scheduled for a specific date
  List<Habit> getHabitsForDate(DateTime date) {
    final box = Hive.box<Habit>(_habitBoxName);
    final dateWithoutTime = DateTime(date.year, date.month, date.day);
    
    // Aktuelles Datum zum Vergleich
    final today = DateTime.now();
    final todayWithoutTime = DateTime(today.year, today.month, today.day);
    
    // Alle Habits abrufen
    final allHabits = box.values.toList();
    
    // Filtern der Habits basierend auf dem angegebenen Datum
    return allHabits.where((habit) {
      // Für vergangene oder heutige Tage müssen wir nur schauen, ob er zugewiesen war
      if (dateWithoutTime.isBefore(todayWithoutTime) || dateWithoutTime.isAtSameMomentAs(todayWithoutTime)) {
        switch (habit.frequency.type) {
          case FrequencyType.daily:
            return true;
          case FrequencyType.weekly:
            return habit.frequency.daysOfWeek.contains(dateWithoutTime.weekday);
          case FrequencyType.monthly:
            return dateWithoutTime.day == habit.frequency.dayOfMonth;
          case FrequencyType.custom:
            if (habit.frequency.customType == CustomFrequencyType.everyXDays) {
              if (habit.frequency.customDays == 0) return false;
              if (habit.completedDates.isEmpty) return true;
              
              // Find nearest completion date before the given date
              final completionDatesBeforeDate = habit.completedDates
                  .where((d) => d.isBefore(dateWithoutTime))
                  .toList();
              
              if (completionDatesBeforeDate.isEmpty) return true;
              
              completionDatesBeforeDate.sort((a, b) => b.compareTo(a)); // Sort descending
              final lastCompletion = completionDatesBeforeDate.first;
              final lastCompletionWithoutTime = DateTime(
                  lastCompletion.year, lastCompletion.month, lastCompletion.day);
              
              final daysSinceCompletion = 
                  dateWithoutTime.difference(lastCompletionWithoutTime).inDays;
              return daysSinceCompletion % habit.frequency.customDays == 0;
            } 
            else if (habit.frequency.customType == CustomFrequencyType.timesPerWeek) {
              // For past dates, we need to reconstruct what was valid that day
              // Get the start of the week containing the date
              final startOfWeek = dateWithoutTime.subtract(Duration(days: dateWithoutTime.weekday - 1));
              final endOfWeek = startOfWeek.add(const Duration(days: 6));
              
              final completionsInWeek = habit.completedDates
                  .where((d) {
                    final dateOnly = DateTime(d.year, d.month, d.day);
                    return dateOnly.isAfter(startOfWeek.subtract(const Duration(days: 1))) && 
                           dateOnly.isBefore(endOfWeek.add(const Duration(days: 1)));
                  })
                  .length;
              
              return completionsInWeek < habit.frequency.timesPerWeek;
            }
            return false;
        }
      }
      // Für zukünftige Tage nutzen wir die isScheduledForDate-Methode
      else {
        return _isHabitScheduledForDate(habit, dateWithoutTime);
      }
    }).toList();
  }
  
  // Check if a habit is scheduled for a specific date
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
            if (habit.frequency.customDays == 0) return false;
            if (habit.completedDates.isEmpty) return true;
            
            // Find nearest completion date before the given date
            final completionDatesBeforeDate = habit.completedDates
                .where((d) => d.isBefore(date))
                .toList();
            
            if (completionDatesBeforeDate.isEmpty) return true;
            
            completionDatesBeforeDate.sort((a, b) => b.compareTo(a)); // Sort descending
            final lastCompletion = completionDatesBeforeDate.first;
            final lastCompletionWithoutTime = DateTime(
                lastCompletion.year, lastCompletion.month, lastCompletion.day);
            
            final daysSinceCompletion = 
                date.difference(lastCompletionWithoutTime).inDays;
            return daysSinceCompletion % habit.frequency.customDays == 0;
          case CustomFrequencyType.timesPerWeek:
            // Get the start of the week containing the given date
            final startOfWeek = date.subtract(Duration(days: date.weekday - 1));
            final endOfWeek = startOfWeek.add(const Duration(days: 6));
            
            // Count completions in this week up to (but not including) the given date
            final completionsInWeekUpToDate = habit.completedDates
                .where((d) {
                  final dateOnly = DateTime(d.year, d.month, d.day);
                  return dateOnly.isAfter(startOfWeek.subtract(const Duration(days: 1))) && 
                         dateOnly.isBefore(date);
                })
                .length;
            
            return completionsInWeekUpToDate < habit.frequency.timesPerWeek;
        }
        return false;
    }
  }
  
  // Check if a habit has been completed on a specific date
  bool isHabitCompletedOnDate(Habit habit, DateTime date) {
    final dateWithoutTime = DateTime(date.year, date.month, date.day);
    
    return habit.completedDates.any((completionDate) {
      final completionDateWithoutTime = DateTime(
          completionDate.year, completionDate.month, completionDate.day);
      return completionDateWithoutTime.isAtSameMomentAs(dateWithoutTime);
    });
  }
  
  // Mark a habit as completed for a specific date
  Future<void> markHabitAsCompletedForDate(String id, DateTime date) async {
    final box = Hive.box<Habit>(_habitBoxName);
    final habit = box.get(id);
    
    if (habit != null) {
      final today = DateTime.now();
      final todayWithoutTime = DateTime(today.year, today.month, today.day);
      final dateWithoutTime = DateTime(date.year, date.month, date.day);
      
      // Überprüfe, ob das Datum heute oder in der Vergangenheit ist
      if (dateWithoutTime.isBefore(todayWithoutTime) || dateWithoutTime.isAtSameMomentAs(todayWithoutTime)) {
        // Überprüfen, ob das Datum bereits in completedDates vorhanden ist
        bool alreadyCompleted = habit.completedDates.any((completionDate) {
          final completionDateWithoutTime = DateTime(
              completionDate.year, completionDate.month, completionDate.day);
          return completionDateWithoutTime.isAtSameMomentAs(dateWithoutTime);
        });
        
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
  
  // Unmark a habit as completed for a specific date
  Future<void> unmarkHabitCompletionForDate(String id, DateTime date) async {
    final box = Hive.box<Habit>(_habitBoxName);
    final habit = box.get(id);
    
    if (habit != null) {
      final dateWithoutTime = DateTime(date.year, date.month, date.day);
      
      // Entferne das angegebene Datum aus completedDates
      habit.completedDates.removeWhere((completionDate) {
        final completionDateWithoutTime = DateTime(
            completionDate.year, completionDate.month, completionDate.day);
        return completionDateWithoutTime.isAtSameMomentAs(dateWithoutTime);
      });
      
      // Streak und lastCompleted neu berechnen
      _recalculateStreak(habit);
      
      await box.put(id, habit);
      _eventBus.fireHabitEvent(HabitEvent.habitUncompleted);
    }
  }
  
  // Hilfsmethode zur Neuberechnung des Streaks und lastCompleted
  void _recalculateStreak(Habit habit) {
    if (habit.completedDates.isEmpty) {
      habit.streak = 0;
      habit.lastCompleted = DateTime(2000);
      return;
    }
    
    // Sortiere die Daten absteigend
    habit.completedDates.sort((a, b) => b.compareTo(a));
    habit.lastCompleted = habit.completedDates.first;
    
    // Aktuelle Streak berechnen
    int tempStreak = 1;
    DateTime currentDate = DateTime(
      habit.completedDates[0].year,
      habit.completedDates[0].month,
      habit.completedDates[0].day
    );
    
    // Prüfen, ob der letzte Abschluss heute oder gestern war
    final today = DateTime.now();
    final todayWithoutTime = DateTime(today.year, today.month, today.day);
    final yesterday = todayWithoutTime.subtract(const Duration(days: 1));
    
    if (!currentDate.isAtSameMomentAs(todayWithoutTime) && 
        !currentDate.isAtSameMomentAs(yesterday)) {
      // Wenn der letzte Abschluss nicht heute oder gestern war, Streak auf 0 setzen
      habit.streak = 0;
      return;
    }
    
    // Restliche Streak-Berechnung
    for (int i = 1; i < habit.completedDates.length; i++) {
      final nextDate = DateTime(
        habit.completedDates[i].year,
        habit.completedDates[i].month,
        habit.completedDates[i].day
      );
      
      // Prüfen, ob die Daten aufeinanderfolgende Tage sind
      final difference = currentDate.difference(nextDate).inDays;
      
      if (difference == 1) {
        tempStreak++;
        currentDate = nextDate;
      } else {
        break;
      }
    }
    
    habit.streak = tempStreak;
  }
  
  // Add a new habit
  Future<void> addHabit(Habit habit) async {
    final box = Hive.box<Habit>(_habitBoxName);
    await box.put(habit.id, habit);
    _eventBus.fireHabitEvent(HabitEvent.habitAdded);
  }
  
  // Update an existing habit
  Future<void> updateHabit(Habit habit) async {
    final box = Hive.box<Habit>(_habitBoxName);
    await box.put(habit.id, habit);
    _eventBus.fireHabitEvent(HabitEvent.habitUpdated);
  }
  
  // Delete a habit
  Future<void> deleteHabit(String id) async {
    final box = Hive.box<Habit>(_habitBoxName);
    await box.delete(id);
    _eventBus.fireHabitEvent(HabitEvent.habitDeleted);
  }
  
  // Mark a habit as completed for today
  Future<void> markHabitAsCompleted(String id) async {
    final box = Hive.box<Habit>(_habitBoxName);
    final habit = box.get(id);
    
    if (habit != null) {
      habit.markAsCompleted();
      await box.put(id, habit);
      _eventBus.fireHabitEvent(HabitEvent.habitCompleted);
    }
  }
  
  // Unmark a habit as completed for today
  Future<void> unmarkHabitCompletion(String id) async {
    final box = Hive.box<Habit>(_habitBoxName);
    final habit = box.get(id);
    
    if (habit != null) {
      habit.unmarkCompletion();
      await box.put(id, habit);
      _eventBus.fireHabitEvent(HabitEvent.habitUncompleted);
    }
  }
}