import 'package:flutter/material.dart';

/// Hilfsklasse für Datumsoperationen in der Anwendung
class DateUtils {
  /// Erstellt ein DateTime-Objekt ohne Zeitanteil (setzt Uhr, Minute, Sekunde auf 0)
  static DateTime dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
  
  /// Prüft, ob zwei Daten am gleichen Tag sind (ohne Berücksichtigung der Zeit)
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && 
           date1.month == date2.month && 
           date1.day == date2.day;
  }
  
  /// Gibt den Wochenbeginn (Montag) für ein bestimmtes Datum zurück
  static DateTime getStartOfWeek(DateTime date) {
    // Montag = 1, ..., Sonntag = 7
    return date.subtract(Duration(days: date.weekday - 1));
  }
  
  /// Gibt das Ende der Woche (Sonntag) für ein bestimmtes Datum zurück
  static DateTime getEndOfWeek(DateTime date) {
    return getStartOfWeek(date).add(const Duration(days: 6));
  }
  
  /// Prüft, ob ein Datum in der aktuellen Woche liegt
  static bool isInCurrentWeek(DateTime date, DateTime referenceDate) {
    final startOfWeek = getStartOfWeek(referenceDate);
    final endOfWeek = getEndOfWeek(referenceDate);
    return date.isAfter(startOfWeek.subtract(const Duration(days: 1))) && 
           date.isBefore(endOfWeek.add(const Duration(days: 1)));
  }
  
  /// Gibt die Anzahl der verbleibenden Tage in der Woche zurück (inkl. heutiger Tag)
  static int getRemainingDaysInWeek(DateTime date) {
    return 7 - date.weekday + 1; // +1 weil der heutige Tag noch zählt
  }
  
  /// Berechnet die Anzahl der Tage zwischen zwei Daten
  static int daysBetween(DateTime from, DateTime to) {
    return dateOnly(to).difference(dateOnly(from)).inDays.abs();
  }
  
  /// Gibt den ersten Tag des Monats zurück
  static DateTime getFirstDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }
  
  /// Berechnet die Anzahl der Tage in einem Monat
  static int getDaysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }
}