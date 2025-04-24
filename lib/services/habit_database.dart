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