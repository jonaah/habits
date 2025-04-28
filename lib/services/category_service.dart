import 'package:hive_flutter/hive_flutter.dart';
import '../models/habit.dart';

/// Service to manage categories for habits
class CategoryService {
  static const String _categoryBoxName = 'categories';
  static const String _habitBoxName = 'habits';
  static const String _categoryOrderBoxName = 'category_order';
  
  // Singleton pattern
  static final CategoryService _instance = CategoryService._internal();
  
  factory CategoryService() {
    return _instance;
  }
  
  CategoryService._internal();
  
  /// Initialize the category service
  Future<void> init() async {
    await Hive.openBox<String>(_categoryBoxName);
    await Hive.openBox<String>(_categoryOrderBoxName);
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
  
  /// Get categories in their custom order
  List<String> getOrderedCategories() {
    final allCategories = getAllCategories();
    final orderBox = Hive.box<String>(_categoryOrderBoxName);
    final orderedCategories = orderBox.values.toList();
    
    // Create a combined list with ordered categories first
    final result = <String>[];
    
    // First, add all categories that are in the order box
    for (var category in orderedCategories) {
      if (allCategories.contains(category)) {
        result.add(category);
        // Remove from allCategories to avoid duplicates
        allCategories.remove(category);
      }
    }
    
    // Then add any remaining categories that aren't in the order
    result.addAll(allCategories);
    
    return result;
  }
  
  /// Save the custom order of categories
  Future<void> saveCategoryOrder(List<String> orderedCategories) async {
    final orderBox = Hive.box<String>(_categoryOrderBoxName);
    
    // Clear existing order
    await orderBox.clear();
    
    // Save new order
    for (var category in orderedCategories) {
      await orderBox.add(category);
    }
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
    final orderBox = Hive.box<String>(_categoryOrderBoxName);
    final List<dynamic> keys = box.keys.toList();
    
    // Remove from categories box
    for (var i = 0; i < box.length; i++) {
      if (box.get(keys[i]) == category) {
        await box.delete(keys[i]);
        break;
      }
    }
    
    // Also remove from order box
    final orderKeys = orderBox.keys.toList();
    for (var i = 0; i < orderBox.length; i++) {
      if (orderBox.get(orderKeys[i]) == category) {
        await orderBox.delete(orderKeys[i]);
        break;
      }
    }
  }
}