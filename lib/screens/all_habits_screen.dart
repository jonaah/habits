import 'package:flutter/material.dart';
import '../models/habit.dart';
import '../services/habit_database.dart';
import '../services/event_bus.dart';
import '../theme/app_theme.dart';
import '../widgets/habit_card.dart';
import 'habit_form_screen.dart';

class AllHabitsScreen extends StatefulWidget {
  const AllHabitsScreen({Key? key}) : super(key: key);

  @override
  _AllHabitsScreenState createState() => _AllHabitsScreenState();
}

class _AllHabitsScreenState extends State<AllHabitsScreen> {
  late HabitDatabase _database;
  late EventBus _eventBus;
  List<Habit> _habits = [];
  bool _isLoading = true;

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

    setState(() {
      _habits = habits;
      _isLoading = false;
    });
  }

  Future<void> _deleteHabit(String id) async {
    await _database.deleteHabit(id);
    // _loadHabits() wird jetzt über den EventBus aufgerufen
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text('Alle Gewohnheiten')),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const HabitFormScreen(),
            ),
          );

          if (result == true) {
            _loadHabits();
          }
        },
        child: const Icon(Icons.add),
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
              Icons.sticky_note_2_outlined,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'Keine Gewohnheiten',
              style: AppTheme.titleStyle,
            ),
            const SizedBox(height: 8),
            Text(
              'Tippe auf + um eine neue Gewohnheit hinzuzufügen',
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
        return Dismissible(
          key: Key(habit.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20.0),
            color: Colors.red,
            child: const Icon(
              Icons.delete,
              color: Colors.white,
            ),
          ),
          confirmDismiss: (_) async {
            return await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Gewohnheit löschen'),
                content: Text(
                  'Möchtest du "${habit.title}" wirklich löschen?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Abbrechen'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text(
                      'Löschen',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            );
          },
          onDismissed: (_) => _deleteHabit(habit.id),
          child: HabitCard(
            habit: habit,
            onToggle: (_) {},
            onEdit: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HabitFormScreen(habit: habit),
                ),
              );

              if (result == true) {
                _loadHabits();
              }
            },
          ),
        );
      },
    );
  }
}