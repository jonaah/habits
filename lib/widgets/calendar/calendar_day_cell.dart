import 'package:flutter/material.dart';
import '../../models/habit.dart';
import '../../theme/app_theme.dart';
import 'calendar_view_model.dart';

/// Kalender-Tageszellen-Widget
class CalendarDayCell extends StatelessWidget {
  final DateTime date;
  final CalendarViewModel calendarViewModel;
  final bool mini;
  final Function(DateTime date, List<Habit> habits) onTap;

  const CalendarDayCell({
    Key? key,
    required this.date,
    required this.calendarViewModel,
    this.mini = false,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final completedHabits = calendarViewModel.getFilteredHabitsForDate(date);
    final intensity = calendarViewModel.getHabitIntensity(completedHabits);
    final isToday = _isDateToday(date);
    final cellColor = calendarViewModel.getCellColor(completedHabits, intensity);
    final size = mini ? 12.0 : 40.0;
    
    return GestureDetector(
      onTap: () => onTap(date, completedHabits),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: cellColor,
          border: isToday ? Border.all(
            color: AppTheme.accentColor,
            width: mini ? 1 : 2,
          ) : null,
          borderRadius: BorderRadius.circular(mini ? 2 : 6),
        ),
        child: mini ? null : Center(
          child: Text(
            date.day.toString(),
            style: TextStyle(
              fontSize: 12,
              color: completedHabits.isEmpty ? Colors.black54 : Colors.white,
              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  bool _isDateToday(DateTime date) {
    final now = DateTime.now();
    return now.year == date.year && 
           now.month == date.month &&
           now.day == date.day;
  }
}