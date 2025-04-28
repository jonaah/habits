import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/habit.dart';
import 'calendar_constants.dart';
import '../../theme/app_theme.dart';

/// Calendar view model für State Management
class CalendarViewModel {
  bool isLoading = true;
  CalendarViewType viewType = CalendarViewType.month;
  DateTime focusDate = DateTime.now();
  
  // Filter options
  Habit? selectedHabit;
  IconData? selectedIcon;
  Color? selectedColor;
  
  List<Habit> habits = [];
  List<Habit> filteredHabits = [];
  Map<DateTime, List<Habit>> completedHabitsByDate = {};

  void setLoading(bool loading) {
    isLoading = loading;
  }

  void updateHabits(List<Habit> newHabits) {
    habits = newHabits;
    filteredHabits = newHabits;
    completedHabitsByDate = _buildCompletedHabitsMap(newHabits);
    isLoading = false;
  }

  Map<DateTime, List<Habit>> _buildCompletedHabitsMap(List<Habit> habits) {
    final Map<DateTime, List<Habit>> completedMap = {};

    for (final habit in habits) {
      for (final date in habit.completedDates) {
        final dateWithoutTime = DateTime(date.year, date.month, date.day);
        completedMap.putIfAbsent(dateWithoutTime, () => []);
        completedMap[dateWithoutTime]!.add(habit);
      }
    }

    return completedMap;
  }

  void applyFilters() {
    filteredHabits = habits.where(_habitMatchesFilters).toList();
  }

  bool _habitMatchesFilters(Habit habit) {
    final matchesHabit = selectedHabit == null || habit.id == selectedHabit!.id;
    final matchesIcon = selectedIcon == null || habit.icon == selectedIcon;
    final matchesColor = selectedColor == null || habit.color?.value == selectedColor?.value;
    return matchesHabit && matchesIcon && matchesColor;
  }

  void resetFilters() {
    selectedHabit = null;
    selectedIcon = null;
    selectedColor = null;
    filteredHabits = habits;
  }

  void navigateDate(bool forward) {
    switch (viewType) {
      case CalendarViewType.month:
        focusDate = DateTime(
          focusDate.year, 
          focusDate.month + (forward ? 1 : -1), 
          1
        );
        break;
      case CalendarViewType.year:
        focusDate = DateTime(
          focusDate.year + (forward ? 1 : -1), 
          focusDate.month, 
          1
        );
        break;
    }
  }

  String get dateNavigatorTitle {
    switch (viewType) {
      case CalendarViewType.month:
        return DateFormat('MMMM yyyy').format(focusDate);
      case CalendarViewType.year:
        return focusDate.year.toString();
    }
  }

  List<Habit> getFilteredHabitsForDate(DateTime date) {
    final completedHabits = completedHabitsByDate[date] ?? [];
    return completedHabits.where((habit) => 
      filteredHabits.any((filteredHabit) => filteredHabit.id == habit.id)
    ).toList();
  }

  double getHabitIntensity(List<Habit> completedHabits) {
    return completedHabits.isEmpty 
      ? 0.0 
      : (completedHabits.length / filteredHabits.length.clamp(1, double.infinity));
  }
  
  Color getCellColor(List<Habit> completedHabits, double intensity) {
    if (completedHabits.isEmpty) {
      return Colors.grey[300]!;
    }
    
    if (selectedHabit != null && 
        completedHabits.any((h) => h.id == selectedHabit!.id)) {
      return selectedHabit!.color ?? AppTheme.primaryColor;
    } 
    
    if (selectedColor != null && 
        completedHabits.any((h) => h.color?.value == selectedColor?.value)) {
      return selectedColor!;
    }
    
    return AppTheme.primaryColor.withOpacity(0.2 + (intensity * 0.8));
  }

  bool get hasActiveFilters => 
    selectedHabit != null || selectedIcon != null || selectedColor != null;

  List<IconData> getUniqueIcons() {
    return habits
      .where((habit) => habit.icon != null)
      .map((habit) => habit.icon!)
      .toSet()
      .toList();
  }

  List<Color> getUniqueColors() {
    return habits
      .where((habit) => habit.color != null)
      .map((habit) => habit.color!)
      .toSet()
      .toList();
  }
}