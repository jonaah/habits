import 'package:flutter/material.dart';
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
  List<Habit> _todayHabits = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _database = HabitDatabase();
    _eventBus = EventBus();
    _loadTodayHabits();

    // Listen for habit changes
    _eventBus.habitEvents.listen((event) {
      // Aktualisiere die Ansicht, wenn ein Habit-Event empfangen wird
      _loadTodayHabits();
    });
  }

  Future<void> _loadTodayHabits() async {
    setState(() {
      _isLoading = true;
    });

    final habits = _database.getTodayHabits();

    setState(() {
      _todayHabits = habits;
      _isLoading = false;
    });
  }

  Future<void> _toggleHabit(Habit habit, bool isCompleted) async {
    if (isCompleted) {
      await _database.markHabitAsCompleted(habit.id);
    } else {
      await _database.unmarkHabitCompletion(habit.id);
    }

    // Da der EventBus jetzt die _loadTodayHabits()-Methode auslöst, ist dieser Aufruf nicht mehr nötig
    // _loadTodayHabits();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text('Heute')),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_todayHabits.isEmpty) {
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
              'Keine Gewohnheiten für heute',
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
      itemCount: _todayHabits.length,
      itemBuilder: (context, index) {
        final habit = _todayHabits[index];
        return HabitCard(
          habit: habit,
          isToday: true,
          onToggle: (isCompleted) => _toggleHabit(habit, isCompleted),
          onEdit: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => HabitFormScreen(habit: habit),
              ),
            );

            if (result == true) {
              _loadTodayHabits();
            }
          },
        );
      },
    );
  }
}