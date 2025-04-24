import 'dart:async';

enum HabitEvent {
  habitAdded,
  habitUpdated,
  habitDeleted,
  habitCompleted,
  habitUncompleted,
}

// Eine einfache Event-Bus-Implementierung
class EventBus {
  // Singleton-Pattern
  static final EventBus _instance = EventBus._internal();
  
  factory EventBus() {
    return _instance;
  }
  
  EventBus._internal();
  
  // Stream-Controller für Habit-Events
  final _habitEventController = StreamController<HabitEvent>.broadcast();
  
  // Stream zum Abonnieren
  Stream<HabitEvent> get habitEvents => _habitEventController.stream;
  
  // Methode zum Senden von Events
  void fireHabitEvent(HabitEvent event) {
    _habitEventController.add(event);
  }
  
  // Methode zum Schließen des Controllers, wenn er nicht mehr benötigt wird
  void dispose() {
    _habitEventController.close();
  }
}