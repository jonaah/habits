import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/habit.dart';
import '../services/habit_database.dart';
import '../services/event_bus.dart';
import '../theme/app_theme.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({Key? key}) : super(key: key);

  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late HabitDatabase _database;
  late EventBus _eventBus;
  List<Habit> _habits = [];
  bool _isLoading = true;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  Map<DateTime, List<Habit>> _completedHabits = {};

  @override
  void initState() {
    super.initState();
    _database = HabitDatabase();
    _eventBus = EventBus();
    _loadHabits();

    // Listen for habit changes
    _eventBus.habitEvents.listen((event) {
      _loadHabits();
    });
  }

  Future<void> _loadHabits() async {
    setState(() {
      _isLoading = true;
    });

    final habits = _database.getAllHabits();

    // Create a map of completed habits by date
    final Map<DateTime, List<Habit>> completedMap = {};

    for (final habit in habits) {
      for (final date in habit.completedDates) {
        final dateWithoutTime = DateTime(date.year, date.month, date.day);
        completedMap.putIfAbsent(dateWithoutTime, () => []);
        completedMap[dateWithoutTime]!.add(habit);
      }
    }

    setState(() {
      _habits = habits;
      _completedHabits = completedMap;
      _isLoading = false;
    });
  }

  List<Habit> _getHabitsForDay(DateTime day) {
    final date = DateTime(day.year, day.month, day.day);
    return _completedHabits[date] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text('Kalender')),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildCalendar(),
          const Divider(height: 1),
          Expanded(
            child: _buildHabitList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    return TableCalendar(
      firstDay: DateTime.now().subtract(const Duration(days: 365)),
      lastDay: DateTime.now().add(const Duration(days: 30)),
      focusedDay: _focusedDay,
      calendarFormat: CalendarFormat.month,
      startingDayOfWeek: StartingDayOfWeek.monday,
      selectedDayPredicate: (day) {
        return isSameDay(_selectedDay, day);
      },
      eventLoader: (day) {
        return _getHabitsForDay(day);
      },
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
        });
      },
      calendarStyle: CalendarStyle(
        markersMaxCount: 3,
        markerDecoration: const BoxDecoration(
          color: AppTheme.primaryColor,
          shape: BoxShape.circle,
        ),
        selectedDecoration: const BoxDecoration(
          color: AppTheme.accentColor,
          shape: BoxShape.circle,
        ),
        todayDecoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.5),
          shape: BoxShape.circle,
        ),
      ),
      calendarBuilders: CalendarBuilders(
        markerBuilder: (context, date, events) {
          if (events.isEmpty) return null;

          return Positioned(
            bottom: 1,
            child: Container(
              padding: const EdgeInsets.all(1),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  events.length > 3 ? 3 : events.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: index < 3
                          ? AppTheme.primaryColor
                          : AppTheme.accentColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHabitList() {
    final habitsForSelectedDay = _getHabitsForDay(_selectedDay);

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (habitsForSelectedDay.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.event_busy,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'Keine Gewohnheiten für ${DateFormat.yMMMd().format(_selectedDay)}',
              style: AppTheme.titleStyle,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: habitsForSelectedDay.length,
      itemBuilder: (context, index) {
        final habit = habitsForSelectedDay[index];
        return Card(
          child: ListTile(
            leading: habit.icon != null
                ? Icon(habit.icon, color: AppTheme.primaryColor)
                : const Icon(Icons.check_circle, color: AppTheme.accentColor),
            title: Text(habit.title),
            subtitle: habit.description.isNotEmpty
                ? Text(habit.description)
                : null,
          ),
        );
      },
    );
  }
}