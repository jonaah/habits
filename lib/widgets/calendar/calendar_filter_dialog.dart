import 'package:flutter/material.dart';
import '../../models/habit.dart';
import '../../theme/app_theme.dart';

/// Filter-Dialog für den Kalender
class CalendarFilterDialog extends StatelessWidget {
  final List<Habit> habits;
  final Habit? selectedHabit;
  final IconData? selectedIcon;
  final Color? selectedColor;
  final String? selectedCategory; // Added category parameter
  final Function(Habit?) onHabitSelected;
  final Function(IconData?) onIconSelected;
  final Function(Color?) onColorSelected;
  final Function(String?) onCategorySelected; // Added category callback
  final VoidCallback onResetFilters;

  const CalendarFilterDialog({
    Key? key,
    required this.habits,
    required this.selectedHabit,
    required this.selectedIcon,
    required this.selectedColor,
    required this.selectedCategory, // Added required parameter
    required this.onHabitSelected,
    required this.onIconSelected,
    required this.onColorSelected,
    required this.onCategorySelected, // Added required callback
    required this.onResetFilters,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filter'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHabitFilter(context),
            const SizedBox(height: 16),
            _buildCategoryFilter(context), // Added category filter
            const SizedBox(height: 16),
            _buildIconFilter(context),
            const SizedBox(height: 16),
            _buildColorFilter(context),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            onResetFilters();
          },
          child: const Text('Filter zurücksetzen'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Schließen'),
        ),
      ],
    );
  }

  Widget _buildHabitFilter(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Nach Gewohnheit filtern:'),
        const SizedBox(height: 8),
        DropdownButton<String>(
          isExpanded: true,
          hint: const Text('Gewohnheit auswählen'),
          value: selectedHabit?.id,
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text('Alle Gewohnheiten'),
            ),
            ...habits.map((habit) => DropdownMenuItem<String>(
              value: habit.id,
              child: Text(habit.title),
            )).toList(),
          ],
          onChanged: (String? habitId) {
            Navigator.pop(context);
            final selectedHabit = habitId != null 
              ? habits.firstWhere((h) => h.id == habitId)
              : null;
            onHabitSelected(selectedHabit);
          },
        ),
      ],
    );
  }

  Widget _buildCategoryFilter(BuildContext context) {
    final uniqueCategories = _getUniqueCategories(habits);
    
    if (uniqueCategories.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Nach Kategorie filtern:'),
        const SizedBox(height: 8),
        DropdownButton<String>(
          isExpanded: true,
          hint: const Text('Kategorie auswählen'),
          value: selectedCategory,
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text('Alle Kategorien'),
            ),
            ...uniqueCategories.map((category) => DropdownMenuItem<String>(
              value: category,
              child: Text(category),
            )).toList(),
          ],
          onChanged: (String? category) {
            Navigator.pop(context);
            onCategorySelected(category);
          },
        ),
      ],
    );
  }

  Widget _buildIconFilter(BuildContext context) {
    final uniqueIcons = _getUniqueIcons(habits);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Nach Icon filtern:'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: uniqueIcons.map((icon) => 
            IconButton(
              icon: Icon(icon),
              color: selectedIcon == icon ? AppTheme.accentColor : null,
              onPressed: () {
                Navigator.pop(context);
                onIconSelected(selectedIcon == icon ? null : icon);
              },
            )
          ).toList(),
        ),
      ],
    );
  }

  Widget _buildColorFilter(BuildContext context) {
    final uniqueColors = _getUniqueColors(habits);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Nach Farbe filtern:'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: uniqueColors.map((color) => 
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                onColorSelected(selectedColor == color ? null : color);
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selectedColor == color 
                      ? AppTheme.accentColor 
                      : Colors.grey,
                    width: selectedColor == color ? 2 : 1,
                  ),
                ),
              ),
            )
          ).toList(),
        ),
      ],
    );
  }

  List<IconData> _getUniqueIcons(List<Habit> habits) {
    return habits
      .where((habit) => habit.icon != null)
      .map((habit) => habit.icon!)
      .toSet()
      .toList();
  }

  List<Color> _getUniqueColors(List<Habit> habits) {
    return habits
      .where((habit) => habit.color != null)
      .map((habit) => habit.color!)
      .toSet()
      .toList();
  }

  List<String> _getUniqueCategories(List<Habit> habits) {
    return habits
      .where((habit) => habit.category != null && habit.category!.isNotEmpty)
      .map((habit) => habit.category!)
      .toSet()
      .toList();
  }
}