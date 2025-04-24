import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/habit.dart';
import '../utils/icon_data_adapter.dart';

class HabitDatabase {
  // Box names
  static const String _habitBoxName = 'habits';
  
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
    Hive.registerAdapter(IconDataAdapter());
    
    // Open boxes
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
  }
  
  // Update an existing habit
  Future<void> updateHabit(Habit habit) async {
    final box = Hive.box<Habit>(_habitBoxName);
    await box.put(habit.id, habit);
  }
  
  // Delete a habit
  Future<void> deleteHabit(String id) async {
    final box = Hive.box<Habit>(_habitBoxName);
    await box.delete(id);
  }
  
  // Mark a habit as completed for today
  Future<void> markHabitAsCompleted(String id) async {
    final box = Hive.box<Habit>(_habitBoxName);
    final habit = box.get(id);
    
    if (habit != null) {
      habit.markAsCompleted();
      await box.put(id, habit);
    }
  }
  
  // Unmark a habit as completed for today
  Future<void> unmarkHabitCompletion(String id) async {
    final box = Hive.box<Habit>(_habitBoxName);
    final habit = box.get(id);
    
    if (habit != null) {
      habit.unmarkCompletion();
      await box.put(id, habit);
    }
  }
}