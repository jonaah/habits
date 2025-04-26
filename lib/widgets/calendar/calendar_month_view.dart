import 'package:flutter/material.dart';
import 'calendar_constants.dart';

/// Month calendar view widget
class CalendarMonthView extends StatelessWidget {
  final DateTime focusDate;
  final Widget Function(DateTime date) cellBuilder;

  const CalendarMonthView({
    Key? key,
    required this.focusDate,
    required this.cellBuilder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final year = focusDate.year;
    final month = focusDate.month;
    final daysInMonth = _getDaysInMonth(year, month);
    final firstDayOffset = DateTime(year, month, 1).weekday - 1; // 0 = Montag

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildWeekdayHeader(),
          const SizedBox(height: 8),
          Expanded(
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1.0,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: 42, // 6 Wochen, 7 Tage pro Woche
              itemBuilder: (context, index) {
                if (index < firstDayOffset || index >= firstDayOffset + daysInMonth) {
                  return Container(); // Leere Zelle
                }
                
                final day = index - firstDayOffset + 1;
                final date = DateTime(year, month, day);
                
                return cellBuilder(date);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekdayHeader() {
    return Row(
      children: CalendarConstants.weekdaysFull.map((day) => 
        Expanded(
          child: Center(
            child: Text(
              day,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        )
      ).toList(),
    );
  }

  int _getDaysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }
}