import 'package:flutter/material.dart';

/// Enum für verschiedene Kalenderansichtstypen
enum CalendarViewType {
  month,
  year
}

/// Kalender-Konstanten und gemeinsame Werte
class CalendarConstants {
  static const List<ButtonSegment<CalendarViewType>> viewTypeSegments = [
    ButtonSegment<CalendarViewType>(
      value: CalendarViewType.month,
      label: Text('Monat'),
    ),
    ButtonSegment<CalendarViewType>(
      value: CalendarViewType.year,
      label: Text('Jahr'),
    ),
  ];

  static const List<String> weekdaysFull = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
  static const List<String> weekdaysShort = ['M', 'D', 'M', 'D', 'F', 'S', 'S'];
}