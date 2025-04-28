import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/habit.dart';
import '../services/habit_database.dart';
import '../services/event_bus.dart';
import '../services/category_service.dart';
import '../theme/app_theme.dart';
import '../widgets/habit_card.dart';
import 'habit_form_screen.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({Key? key}) : super(key: key);

  @override
  _TodayScreenState createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  late HabitDatabase _database;
  late EventBus _eventBus;
  late CategoryService _categoryService;
  List<Habit> _habits = [];
  bool _isLoading = true;
  
  // Datum für die aktuell angezeigte Liste
  DateTime _selectedDate = DateTime.now();
  
  // Formatierung für das Datum in der AppBar
  final DateFormat _dateFormat = DateFormat('d. MMMM yyyy', 'de_DE');
  
  // Formatierung für Wochentag
  final DateFormat _weekdayFormat = DateFormat('EEEE', 'de_DE');

  @override
  void initState() {
    super.initState();
    _database = HabitDatabase();
    _eventBus = EventBus();
    _categoryService = CategoryService();
    _loadHabitsForDate(_selectedDate);

    // Listen for habit changes
    _eventBus.habitEvents.listen((event) {
      // Aktualisiere die Ansicht, wenn ein Habit-Event empfangen wird
      _loadHabitsForDate(_selectedDate);
    });
  }
  
  // Prüft, ob das angegebene Datum heute ist
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }
  
  // Prüft, ob das angegebene Datum in der Zukunft liegt
  bool _isFutureDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final compareDate = DateTime(date.year, date.month, date.day);
    return compareDate.isAfter(today);
  }
  
  // Navigiert zum nächsten Tag
  void _nextDay() {
    setState(() {
      _selectedDate = _selectedDate.add(const Duration(days: 1));
      _loadHabitsForDate(_selectedDate);
    });
  }
  
  // Navigiert zum vorherigen Tag
  void _previousDay() {
    setState(() {
      _selectedDate = _selectedDate.subtract(const Duration(days: 1));
      _loadHabitsForDate(_selectedDate);
    });
  }
  
  // Zurück zum heutigen Tag
  void _goToToday() {
    setState(() {
      _selectedDate = DateTime.now();
      _loadHabitsForDate(_selectedDate);
    });
  }

  Future<void> _loadHabitsForDate(DateTime date) async {
    setState(() {
      _isLoading = true;
    });

    final habits = _database.getHabitsForDate(date);

    setState(() {
      _habits = habits;
      _isLoading = false;
    });
  }

  Future<void> _toggleHabit(Habit habit, bool isCompleted) async {
    if (_isFutureDate(_selectedDate)) {
      // Keine Änderung erlauben für zukünftige Termine
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gewohnheiten können nicht für zukünftige Tage markiert werden.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
    if (isCompleted) {
      await _database.markHabitAsCompletedForDate(habit.id, _selectedDate);
    } else {
      await _database.unmarkHabitCompletionForDate(habit.id, _selectedDate);
    }
  }

  String _getAppBarTitle() {
    if (_isToday(_selectedDate)) {
      return 'Heute';
    } else {
      // Ersten Buchstaben des Wochentags groß schreiben
      String weekday = _weekdayFormat.format(_selectedDate);
      weekday = weekday[0].toUpperCase() + weekday.substring(1);
      
      return weekday;
    }
  }
  
  String _getDateString() {
    return _dateFormat.format(_selectedDate);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(_getAppBarTitle(), style: const TextStyle(fontSize: 20)),
            Text(_getDateString(), style: const TextStyle(fontSize: 14)),
          ],
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _previousDay,
          tooltip: 'Vorheriger Tag',
        ),
        actions: [
          if (!_isToday(_selectedDate))
            IconButton(
              icon: const Icon(Icons.today),
              onPressed: _goToToday,
              tooltip: 'Heute',
            ),
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: _nextDay,
            tooltip: 'Nächster Tag',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_habits.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_outline,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              _isToday(_selectedDate) 
                ? 'Keine Gewohnheiten für heute'
                : 'Keine Gewohnheiten für diesen Tag',
              style: AppTheme.titleStyle,
            ),
            const SizedBox(height: 8),
            Text(
              'Füge neue Gewohnheiten hinzu, um zu beginnen',
              style: AppTheme.subtitleStyle,
            ),
          ],
        ),
      );
    }

    // Hole die sortierte Liste von Kategorien
    final orderedCategories = _categoryService.getOrderedCategories();
    
    // Gruppiere Habits nach Kategorien und Erledigungsstatus
    Map<String?, List<Habit>> uncompletedHabits = {};
    List<Habit> completedHabits = [];
    
    // Füge eine Kategorie für Habits ohne Kategorie hinzu
    uncompletedHabits[null] = [];
    
    // Trenne erledigte und unerledigte Habits
    for (var habit in _habits) {
      final isCompleted = _database.isHabitCompletedOnDate(habit, _selectedDate);
      
      if (isCompleted) {
        // Alle erledigten Habits in eine separate Liste
        completedHabits.add(habit);
      } else {
        // Unerledigte Habits nach Kategorien gruppieren
        final category = habit.category;
        
        if (uncompletedHabits.containsKey(category)) {
          uncompletedHabits[category]!.add(habit);
        } else if (category != null) {
          uncompletedHabits[category] = [habit];
        } else {
          uncompletedHabits[null]!.add(habit);
        }
      }
    }
    
    // Sortiere alle Habits innerhalb jeder Kategorie alphabetisch nach Titel
    uncompletedHabits.forEach((category, habits) {
      habits.sort((a, b) => a.title.compareTo(b.title));
    });
    
    // Sortiere erledigte Habits alphabetisch
    completedHabits.sort((a, b) => a.title.compareTo(b.title));
    
    // Erstelle Liste von Widgets mit Kategorie-Überschriften und Habits
    List<Widget> allWidgets = [];
    
    // Füge erst alle unerledigten Habits nach Kategorie hinzu
    for (var category in orderedCategories) {
      if (uncompletedHabits.containsKey(category) && uncompletedHabits[category]!.isNotEmpty) {
        // Kategorie-Überschrift
        allWidgets.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
            child: Text(
              category,
              style: AppTheme.titleStyle.copyWith(
                color: AppTheme.primaryColor,
              ),
            ),
          ),
        );
        
        // Habits dieser Kategorie
        for (var habit in uncompletedHabits[category]!) {
          allWidgets.add(_buildHabitItem(habit));
        }
        
        // Entferne die verarbeitete Kategorie
        uncompletedHabits.remove(category);
      }
    }
    
    // Füge alle unerledigten Habits ohne Kategorie hinzu (wenn vorhanden)
    if (uncompletedHabits[null]!.isNotEmpty) {
      allWidgets.add(
        const Padding(
          padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
          child: Text(
            'Ohne Kategorie',
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
        ),
      );
      
      for (var habit in uncompletedHabits[null]!) {
        allWidgets.add(_buildHabitItem(habit));
      }
      
      uncompletedHabits.remove(null);
    }
    
    // Füge alle übrigen unerledigten Habits hinzu, die nicht in der Sortierreihenfolge definiert waren
    for (var category in uncompletedHabits.keys) {
      if (category != null && uncompletedHabits[category]!.isNotEmpty) {
        // Kategorie-Überschrift
        allWidgets.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
            child: Text(
              category,
              style: AppTheme.titleStyle.copyWith(
                color: AppTheme.primaryColor,
              ),
            ),
          ),
        );
        
        // Habits dieser Kategorie
        for (var habit in uncompletedHabits[category]!) {
          allWidgets.add(_buildHabitItem(habit));
        }
      }
    }
    
    // Füge erledigte Habits am Ende hinzu
    if (completedHabits.isNotEmpty) {
      allWidgets.add(
        const Padding(
          padding: EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 8.0),
          child: Text(
            'Erledigt',
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.w600,
              color: Colors.green,
            ),
          ),
        ),
      );
      
      for (var habit in completedHabits) {
        allWidgets.add(_buildHabitItem(habit));
      }
    }
    
    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: allWidgets,
    );
  }

  Widget _buildHabitItem(Habit habit) {
    final isCompleted = _database.isHabitCompletedOnDate(habit, _selectedDate);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: HabitCard(
        habit: habit,
        isToday: !_isFutureDate(_selectedDate), // Checkbox nur für Vergangenheit und Heute anzeigen
        onToggle: (completed) => _toggleHabit(habit, completed),
        date: _selectedDate,
        isEditable: false, // Karten sind nicht bearbeitbar auf der TodayScreen
      ),
    );
  }
}