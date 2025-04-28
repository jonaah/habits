import 'package:hive_flutter/hive_flutter.dart';
import '../models/habit.dart';

/// Service to manage categories for habits
class CategoryService {
  static const String _categoryBoxName = 'categories';
  static const String _habitBoxName = 'habits';
  
  // Singleton pattern
  static final CategoryService _instance = CategoryService._internal();
  
  factory CategoryService() {
    return _instance;
  }
  
  CategoryService._internal();
  
  /// Initialize the category service
  Future<void> init() async {
    await Hive.openBox<String>(_categoryBoxName);
    // Import existing categories from habits after both boxes are opened
    await importCategoriesFromHabits();
  }
  
  /// Import all categories from existing habits
  Future<void> importCategoriesFromHabits() async {
    try {
      final habitBox = Hive.box<Habit>(_habitBoxName);
      
      // Get all habits
      final habits = habitBox.values.toList();
      
      // Extract all unique categories
      for (var habit in habits) {
        if (habit.category != null && habit.category!.isNotEmpty) {
          await addCategory(habit.category!);
        }
      }
    } catch (e) {
      // Handle error if the habit box isn't opened yet or other issues
      print('Error importing categories: $e');
    }
  }
  
  /// Get all categories
  List<String> getAllCategories() {
    final box = Hive.box<String>(_categoryBoxName);
    return box.values.toList();
  }
  
  /// Add a new category if it doesn't exist
  Future<void> addCategory(String category) async {
    final box = Hive.box<String>(_categoryBoxName);
    final categories = getAllCategories();
    
    // Only add if the category doesn't exist yet
    if (!categories.contains(category)) {
      await box.add(category);
    }
  }
  
  /// Delete a category
  Future<void> deleteCategory(String category) async {
    final box = Hive.box<String>(_categoryBoxName);
    final List<dynamic> keys = box.keys.toList();
    
    for (var i = 0; i < box.length; i++) {
      if (box.get(keys[i]) == category) {
        await box.delete(keys[i]);
        break;
      }
    }
  }
}