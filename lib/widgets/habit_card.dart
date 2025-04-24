import 'package:flutter/material.dart';
import '../models/habit.dart';
import '../theme/app_theme.dart';
import '../services/habit_database.dart';

class HabitCard extends StatelessWidget {
  final Habit habit;
  final bool isToday;  // Gibt an, ob Checkboxen erlaubt sind (für Vergangenheit und heute)
  final Function(bool) onToggle;
  final VoidCallback? onEdit; // Optional, kann null sein wenn nicht bearbeitbar
  final DateTime? date;  // Optionales Datum für die Anzeige
  final bool isEditable; // Gibt an, ob die Karte bearbeitbar ist

  const HabitCard({
    Key? key,
    required this.habit,
    this.isToday = false,
    required this.onToggle,
    this.onEdit,
    this.date,
    this.isEditable = true,
  }) : super(key: key);

  bool _isCompletedOnDate() {
    if (habit.completedDates.isEmpty) return false;
    
    final checkDate = date ?? DateTime.now();
    final dateWithoutTime = DateTime(checkDate.year, checkDate.month, checkDate.day);
    
    return habit.completedDates.any((date) {
      final completionDateWithoutTime = DateTime(date.year, date.month, date.day);
      return completionDateWithoutTime.isAtSameMomentAs(dateWithoutTime);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = _isCompletedOnDate();
    final habitColor = habit.color ?? AppTheme.primaryColor;
    
    return Card(
      shape: habit.color != null
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: habitColor.withOpacity(0.8),
                width: 2,
              ),
            )
          : null,
      child: InkWell(
        onTap: isToday 
            ? () => onToggle(!isCompleted) // Ganzen Card klickbar für Toggle
            : onEdit, // Nur bearbeitbar, wenn nicht heute oder nicht isEditable=false
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Icon oder Checkbox-Anzeige (keine interaktive Checkbox mehr)
              Container(
                decoration: BoxDecoration(
                  color: isToday && isCompleted 
                      ? habitColor.withOpacity(0.2) 
                      : (habit.icon != null ? habitColor.withOpacity(0.1) : null),
                  borderRadius: BorderRadius.circular(8),
                  border: isToday 
                      ? Border.all(
                          color: habitColor,
                          width: 2,
                        ) 
                      : null,
                ),
                padding: const EdgeInsets.all(8),
                child: isToday && isCompleted
                    ? Icon(
                        Icons.check,
                        color: habitColor,
                        size: 24,
                      )
                    : (habit.icon != null
                        ? Icon(
                            habit.icon,
                            color: habitColor,
                            size: 24,
                          )
                        : null),
              ),
              const SizedBox(width: 16),
              
              // Habit details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.title,
                      style: AppTheme.titleStyle.copyWith(
                        decoration: isToday && isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      habit.frequency.getDisplayText(),
                      style: AppTheme.subtitleStyle,
                    ),
                    if (habit.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        habit.description,
                        style: AppTheme.bodyStyle.copyWith(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              
              // Streak indicator
              if (habit.streak > 0)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: habit.color != null 
                        ? habitColor.withOpacity(0.1)
                        : AppTheme.streakColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.local_fire_department,
                        color: habit.color != null ? habitColor : AppTheme.streakColor,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${habit.streak}',
                        style: TextStyle(
                          color: habit.color != null ? habitColor : AppTheme.streakColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                
              // Bearbeitungs-Icon nur anzeigen, wenn bearbeitbar und onEdit vorhanden
              if (isEditable && onEdit != null)
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  color: AppTheme.subtitleColor,
                  onPressed: onEdit,
                ),
            ],
          ),
        ),
      ),
    );
  }
}