import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/habit.dart';
import '../../theme/app_theme.dart';

/// Dialog zur Anzeige von Habits eines bestimmten Tages
class DayHabitsDialog extends StatelessWidget {
  final DateTime date;
  final List<Habit> habits;

  const DayHabitsDialog({
    Key? key,
    required this.date,
    required this.habits,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(DateFormat('d. MMMM yyyy').format(date)),
      content: SizedBox(
        width: double.maxFinite,
        child: habits.isEmpty
          ? const Text('Keine Gewohnheiten an diesem Tag erledigt')
          : ListView.builder(
              shrinkWrap: true,
              itemCount: habits.length,
              itemBuilder: (context, index) => _buildHabitListItem(habits[index]),
            ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Schließen'),
        ),
      ],
    );
  }

  Widget _buildHabitListItem(Habit habit) {
    return ListTile(
      leading: _buildHabitIcon(habit),
      title: Text(habit.title),
      subtitle: habit.description.isNotEmpty 
        ? Text(habit.description) 
        : null,
    );
  }

  Widget _buildHabitIcon(Habit habit) {
    if (habit.icon != null) {
      return Icon(habit.icon, color: habit.color ?? AppTheme.primaryColor);
    }
    
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: habit.color ?? AppTheme.primaryColor,
      ),
    );
  }
}