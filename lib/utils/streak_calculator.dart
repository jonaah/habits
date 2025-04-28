import '../models/habit.dart';
import 'date_utils.dart';

/// Klasse zur Berechnung von Streaks für verschiedene Arten von Gewohnheiten
class StreakCalculator {

  /// Berechnet den Streak für eine Gewohnheit basierend auf ihrem Frequenztyp
  static int calculateStreak(Habit habit, DateTime today) {
    if (habit.completedDates.isEmpty) {
      return 0;
    }
    
    // Sortiere die Daten absteigend (neuestes zuerst)
    final completedDates = List<DateTime>.from(habit.completedDates)
      ..sort((a, b) => b.compareTo(a));
      
    final todayWithoutTime = DateUtils.dateOnly(today);
    
    // Wähle die entsprechende Streak-Berechnungsmethode basierend auf dem Frequenztyp
    switch (habit.frequency.type) {
      case FrequencyType.daily:
        return _calculateDailyStreak(completedDates, todayWithoutTime);
      case FrequencyType.weekly:
        return habit.frequency.daysOfWeek.length == 7 
            ? _calculateDailyStreak(completedDates, todayWithoutTime)
            : _calculateWeeklyStreak(habit.frequency.daysOfWeek, completedDates, todayWithoutTime);
      case FrequencyType.monthly:
        return _calculateMonthlyStreak(habit.frequency.dayOfMonth, completedDates, todayWithoutTime);
      case FrequencyType.custom:
        switch (habit.frequency.customType) {
          case CustomFrequencyType.everyXDays:
            return _calculateEveryXDaysStreak(habit.frequency.customDays, completedDates, todayWithoutTime);
          case CustomFrequencyType.timesPerWeek:
            return _calculateTimesPerWeekStreak(habit.frequency.timesPerWeek, completedDates, todayWithoutTime);
        }
    }
    
    return 0;
  }
  
  /// Hilfsmethode zur Berechnung des Streaks für tägliche Gewohnheiten
  static int _calculateDailyStreak(List<DateTime> completedDates, DateTime today) {
    if (completedDates.isEmpty) return 0;
    
    // Normalisiere die Daten um nur das Datum ohne Zeit zu haben
    final normalizedDates = completedDates
        .map((date) => DateUtils.dateOnly(date))
        .toList();
    
    // Das aktuelle Datum (letzte Vervollständigung)
    final lastCompletedDate = normalizedDates.first;
    
    // Prüfen, ob der letzte Abschluss heute oder gestern war
    final yesterday = today.subtract(const Duration(days: 1));
    
    if (!DateUtils.isSameDay(lastCompletedDate, today) && 
        !DateUtils.isSameDay(lastCompletedDate, yesterday)) {
      // Wenn der letzte Abschluss nicht heute oder gestern war, Streak auf 0 setzen
      return 0;
    }
    
    // Zähle konsekutive Tage
    int tempStreak = 1;
    DateTime currentDate = normalizedDates.first;
    
    for (int i = 1; i < normalizedDates.length; i++) {
      // Prüfen, ob die Daten aufeinanderfolgende Tage sind
      final difference = DateUtils.daysBetween(normalizedDates[i], currentDate);
      
      if (difference == 1) {
        tempStreak++;
        currentDate = normalizedDates[i];
      } else {
        break;
      }
    }
    
    return tempStreak;
  }

  /// Hilfsmethode zur Berechnung des Streaks für wöchentliche Gewohnheiten
  static int _calculateWeeklyStreak(List<int> daysOfWeek, List<DateTime> completedDates, DateTime today) {
    if (completedDates.isEmpty) return 0;
    
    // Normalisiere die Daten um nur das Datum ohne Zeit zu haben
    final normalizedDates = completedDates
        .map((date) => DateUtils.dateOnly(date))
        .toList();
    
    // Das aktuelle Datum (letzte Vervollständigung)
    final lastCompletedDate = normalizedDates.first;
    
    // Prüfen, ob die letzte Erledigung innerhalb der letzten 7 Tage liegt
    if (DateUtils.daysBetween(lastCompletedDate, today) > 7) {
      return 0;
    }
    
    int streakCount = 0;
    Set<int> requiredDays = daysOfWeek.toSet();
    
    // Beginne mit der aktuellen Woche
    DateTime currentWeekStart = DateUtils.getStartOfWeek(today);
    bool continueStreak = true;
    
    while (continueStreak && normalizedDates.isNotEmpty) {
      DateTime weekEnd = DateUtils.getEndOfWeek(currentWeekStart);
      
      // Sammle alle erledigten Tage dieser Woche
      Set<int> completedDaysThisWeek = {};
      for (DateTime date in normalizedDates.where(
        (date) => DateUtils.isInCurrentWeek(date, currentWeekStart)
      )) {
        completedDaysThisWeek.add(date.weekday);
      }
      
      // Prüfe, ob diese Woche die aktuelle Woche ist
      bool isCurrentWeek = DateUtils.isInCurrentWeek(today, currentWeekStart);
                          
      if (isCurrentWeek) {
        // Für die aktuelle Woche: Prüfen, ob alle bereits vergangenen Tage erledigt wurden
        Set<int> requiredDaysUntilToday = requiredDays
          .where((day) => day <= today.weekday)
          .toSet();
          
        if (requiredDaysUntilToday.every((day) => completedDaysThisWeek.contains(day))) {
          streakCount++;
        } else {
          break;
        }
      } else {
        // Für vergangene Wochen: Alle erforderlichen Tage müssen erledigt sein
        if (requiredDays.every((day) => completedDaysThisWeek.contains(day))) {
          streakCount++;
        } else {
          break;
        }
      }
      
      // Zur vorherigen Woche wechseln
      final previousWeekEnd = currentWeekStart.subtract(const Duration(days: 1));
      currentWeekStart = DateUtils.getStartOfWeek(previousWeekEnd);
      
      // Prüfen, ob noch Daten für frühere Wochen vorhanden sind
      if (!normalizedDates.any((date) => date.isBefore(previousWeekEnd))) {
        continueStreak = false;
      }
    }
    
    return streakCount;
  }
  
  /// Hilfsmethode zur Berechnung des Streaks für monatliche Gewohnheiten
  static int _calculateMonthlyStreak(int dayOfMonth, List<DateTime> completedDates, DateTime today) {
    if (completedDates.isEmpty) return 0;
    
    // Normalisiere die Daten um nur das Datum ohne Zeit zu haben
    final normalizedDates = completedDates
        .map((date) => DateUtils.dateOnly(date))
        .toList();
    
    // Das aktuelle Datum (letzte Vervollständigung)
    final lastCompletedDate = normalizedDates.first;
    
    // Prüfen, ob es eine Vervollständigung im aktuellen Monat gibt
    bool hasCompletionInCurrentMonth = lastCompletedDate.year == today.year && 
                                      lastCompletedDate.month == today.month;
                                      
    // Prüfen, ob der Tag im aktuellen Monat bereits vorbei ist und nicht erledigt wurde
    bool dayPassedThisMonth = today.day > dayOfMonth;
    
    // Wenn der Tag diesen Monat vorbei ist und keine Erledigung vorliegt, Streak auf 0
    if (dayPassedThisMonth && !hasCompletionInCurrentMonth) {
      return 0;
    }
    
    int streakCount = 0;
    
    // Aktuellen Monat prüfen
    if (hasCompletionInCurrentMonth) {
      streakCount = 1;
      
      // Beginne mit dem vorherigen Monat
      DateTime currentMonthDate = DateUtils.getFirstDayOfMonth(today)
                                .subtract(const Duration(days: 1));
      DateTime currentMonth = DateUtils.getFirstDayOfMonth(currentMonthDate);
      
      // Für jeden vorherigen Monat prüfen
      while (true) {
        // Überprüfe, ob der Tag in diesem Monat existiert (28/29/30/31)
        int daysInMonth = DateUtils.getDaysInMonth(currentMonth.year, currentMonth.month);
        int actualDay = dayOfMonth > daysInMonth ? daysInMonth : dayOfMonth;
        
        // Datum für diesen Monat erstellen
        DateTime targetDate = DateTime(currentMonth.year, currentMonth.month, actualDay);
        
        // Prüfen, ob der Habit für dieses Datum erledigt wurde
        bool completedThisMonth = normalizedDates.any((date) => 
          DateUtils.isSameDay(date, targetDate)
        );
        
        if (completedThisMonth) {
          streakCount++;
          // Zum vorherigen Monat gehen
          currentMonthDate = currentMonth.subtract(const Duration(days: 1));
          currentMonth = DateUtils.getFirstDayOfMonth(currentMonthDate);
        } else {
          break;
        }
      }
    }
    
    return streakCount;
  }
  
  /// Hilfsmethode zur Berechnung des Streaks für "alle X Tage" Gewohnheiten
  static int _calculateEveryXDaysStreak(int xDays, List<DateTime> completedDates, DateTime today) {
    if (completedDates.isEmpty || xDays <= 0) return 0;
    
    // Normalisiere die Daten um nur das Datum ohne Zeit zu haben
    final normalizedDates = completedDates
        .map((date) => DateUtils.dateOnly(date))
        .toList();
    
    // Das aktuelle Datum (letzte Vervollständigung)
    final lastCompletedDate = normalizedDates.first;
    
    // Berechne wie viele Tage seit der letzten Erledigung vergangen sind
    int daysSinceLastCompletion = DateUtils.daysBetween(lastCompletedDate, today);
    
    // Wenn mehr als X Tage seit der letzten Erledigung vergangen sind, Streak auf 0
    if (daysSinceLastCompletion > xDays) {
      return 0;
    }
    
    int streakCount = 1; // Start mit der aktuellen Erledigung
    DateTime expectedDate = lastCompletedDate;
    
    // Gehe durch alle vergangenen Erledigungstermine
    for (int i = 1; i < normalizedDates.length; i++) {
      // Berechne das erwartete vorherige Datum (X Tage vor dem letzten erwarteten Datum)
      expectedDate = expectedDate.subtract(Duration(days: xDays));
      
      // Finde das tatsächliche Erledigung-Datum, das am nächsten am erwarteten Datum liegt
      DateTime? closestCompletionDate;
      int minDifference = xDays; // Maximaler Unterschied ist X Tage
      
      for (int j = i; j < normalizedDates.length; j++) {
        final diff = DateUtils.daysBetween(expectedDate, normalizedDates[j]);
        if (diff < minDifference) {
          minDifference = diff;
          closestCompletionDate = normalizedDates[j];
        }
      }
      
      // Wenn ein passendes Datum gefunden wurde und es ist nicht mehr als X/2 Tage vom erwarteten Datum entfernt
      if (closestCompletionDate != null && minDifference <= xDays / 2) {
        streakCount++;
        expectedDate = closestCompletionDate; // Verwende das tatsächliche Datum für die nächste Berechnung
      } else {
        break; // Keine passende Erledigung gefunden, Streak endet hier
      }
    }
    
    return streakCount;
  }
  
  /// Hilfsmethode zur Berechnung des Streaks für "X mal pro Woche" Gewohnheiten
  static int _calculateTimesPerWeekStreak(int timesPerWeek, List<DateTime> completedDates, DateTime today) {
    if (completedDates.isEmpty || timesPerWeek <= 0) return 0;
    
    // Normalisiere die Daten um nur das Datum ohne Zeit zu haben
    final normalizedDates = completedDates
        .map((date) => DateUtils.dateOnly(date))
        .toList();
    
    int streakCount = 0;
    
    // Beginne mit der aktuellen Woche
    DateTime currentWeekStart = DateUtils.getStartOfWeek(today);
    bool continueStreak = true;
    
    while (continueStreak) {
      // Ende der aktuellen Woche
      DateTime weekEnd = DateUtils.getEndOfWeek(currentWeekStart);
      
      // Sammle alle Erledigungen in dieser Woche
      List<DateTime> completionsThisWeek = normalizedDates.where(
        (date) => DateUtils.isInCurrentWeek(date, currentWeekStart)
      ).toList();
      
      int completionsCount = completionsThisWeek.length;
      
      // Ist dies die aktuelle Woche?
      bool isCurrentWeek = DateUtils.isInCurrentWeek(today, currentWeekStart);
                          
      if (isCurrentWeek) {
        // Für die aktuelle Woche: Prüfen, ob wir auf dem richtigen Weg sind
        // (genug Zeit, um die erforderlichen Erledigungen zu erreichen)
        int remainingDaysInWeek = DateUtils.getRemainingDaysInWeek(today);
        int needed = timesPerWeek - completionsCount;
        
        if (needed <= remainingDaysInWeek) {
          // Wir können es noch schaffen oder haben es bereits geschafft
          // Zähle bereits gemachte Erledigungen in dieser Woche
          streakCount += completionsCount;
        } else {
          // Nicht mehr genug Tage übrig, um das Ziel zu erreichen
          break;
        }
      } else {
        // Vergangene Woche: Wir müssen mindestens X Erledigungen haben
        if (completionsCount >= timesPerWeek) {
          // Erhöhe den Streak um die tatsächliche Anzahl der Erledigungen
          streakCount += completionsCount;
        } else {
          // Nicht genug Erledigungen in dieser Woche
          break;
        }
      }
      
      // Zur vorherigen Woche wechseln
      final previousWeekEnd = currentWeekStart.subtract(const Duration(days: 1));
      currentWeekStart = DateUtils.getStartOfWeek(previousWeekEnd);
      
      // Wenn keine Daten mehr für frühere Wochen vorhanden sind, Schleife beenden
      if (!normalizedDates.any((date) => date.isBefore(previousWeekEnd))) {
        continueStreak = false;
      }
    }
    
    return streakCount;
  }
  
  /// Berechnet, wie oft eine Gewohnheit in einer bestimmten Woche erledigt wurde
  static (int completed, int required) calculateWeeklyCompletionStatus(
    Habit habit, DateTime date
  ) {
    // Nur relevant für "X mal pro Woche" Gewohnheiten
    if (habit.frequency.type != FrequencyType.custom || 
        habit.frequency.customType != CustomFrequencyType.timesPerWeek) {
      return (0, 0);
    }
    
    int requiredCount = habit.frequency.timesPerWeek;
    final dateWithoutTime = DateUtils.dateOnly(date);
    
    // Start der Woche und Ende der Woche finden
    final startOfWeek = DateUtils.getStartOfWeek(dateWithoutTime);
    final endOfWeek = DateUtils.getEndOfWeek(dateWithoutTime);
    
    // Anzahl der Erledigungen in dieser Woche zählen
    int completionsInWeek = habit.completedDates
        .where((d) => DateUtils.isInCurrentWeek(d, dateWithoutTime))
        .length;
    
    return (completionsInWeek, requiredCount);
  }
}