import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import 'calendar_constants.dart';

/// Year calendar view widget
class CalendarYearView extends StatelessWidget {
  final DateTime focusDate;
  final Widget Function(DateTime date) cellBuilder;

  const CalendarYearView({
    Key? key,
    required this.focusDate,
    required this.cellBuilder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // Build 12 month grids (3x4 layout)
            for (int row = 0; row < 4; row++)
              Row(
                children: [
                  for (int col = 0; col < 3; col++)
                    Expanded(
                      child: _buildMonthInYearView(row * 3 + col + 1),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthInYearView(int month) {
    final year = focusDate.year;
    final daysInMonth = _getDaysInMonth(year, month);
    final firstDayOffset = DateTime(year, month, 1).weekday - 1;
    
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Column(
        children: [
          Text(
            DateFormat('MMM').format(DateTime(year, month)),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 2),
          _buildMiniWeekdayHeader(),
          const SizedBox(height: 2),
          _buildMonthMiniGrid(year, month, daysInMonth, firstDayOffset),
        ],
      ),
    );
  }

  Widget _buildMiniWeekdayHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: CalendarConstants.weekdaysShort.map((day) => 
        Text(
          day,
          style: const TextStyle(
            fontSize: 8,
            color: AppTheme.subtitleColor,
          ),
        ),
      ).toList(),
    );
  }

  Widget _buildMonthMiniGrid(int year, int month, int daysInMonth, int firstDayOffset) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1.0,
        crossAxisSpacing: 1,
        mainAxisSpacing: 1,
      ),
      itemCount: 42, // 6 Wochen max
      itemBuilder: (context, index) {
        if (index < firstDayOffset || index >= firstDayOffset + daysInMonth) {
          return const SizedBox.shrink(); // Leere Zelle
        }
        
        final day = index - firstDayOffset + 1;
        final date = DateTime(year, month, day);
        
        return cellBuilder(date);
      },
    );
  }

  int _getDaysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }
}