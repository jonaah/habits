import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/habit.dart';
import '../services/habit_database.dart';
import '../services/event_bus.dart';
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

    // Habits nach Erledigungsstatus sortieren (unerledigte zuerst, erledigte am Ende)
    habits.sort((a, b) {
      // Überprüfen, ob der Habit am selektierten Datum erledigt wurde
      bool isACompleted = _database.isHabitCompletedOnDate(a, date);
      bool isBCompleted = _database.isHabitCompletedOnDate(b, date);

      // Wenn einer erledigt und der andere nicht erledigt ist, sortiere entsprechend
      if (isACompleted && !isBCompleted) {
        return 1; // A nach B sortieren (erledigte nach unten)
      } else if (!isACompleted && isBCompleted) {
        return -1; // A vor B sortieren (unerledigte nach oben)
      }
      
      // Wenn beide den gleichen Status haben, sortiere alphabetisch nach Titel
      return a.title.compareTo(b.title);
    });

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

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _habits.length,
      itemBuilder: (context, index) {
        final habit = _habits[index];
        final isCompleted = _database.isHabitCompletedOnDate(habit, _selectedDate);
        
        return HabitCard(
          habit: habit,
          isToday: !_isFutureDate(_selectedDate), // Checkbox nur für Vergangenheit und Heute anzeigen
          onToggle: (completed) => _toggleHabit(habit, completed),
          date: _selectedDate, // Übergebe das ausgewählte Datum
          onEdit: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => HabitFormScreen(habit: habit),
              ),
            );

            if (result == true) {
              _loadHabitsForDate(_selectedDate);
            }
          },
        );
      },
    );
  }
}