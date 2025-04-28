import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../models/habit.dart';
import '../services/habit_database.dart';
import '../services/event_bus.dart';
import '../services/category_service.dart';
import '../theme/app_theme.dart';
import '../widgets/habit_card.dart';
import '../widgets/category_order_dialog.dart';
import 'habit_form_screen.dart';

class AllHabitsScreen extends StatefulWidget {
  const AllHabitsScreen({Key? key}) : super(key: key);

  @override
  _AllHabitsScreenState createState() => _AllHabitsScreenState();
}

class _AllHabitsScreenState extends State<AllHabitsScreen> {
  late HabitDatabase _database;
  late EventBus _eventBus;
  late CategoryService _categoryService;
  List<Habit> _habits = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _database = HabitDatabase();
    _eventBus = EventBus();
    _categoryService = CategoryService();
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
        title: const Text('Alle Gewohnheiten'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            tooltip: 'Kategorien sortieren',
            onPressed: () {
              showCategoryOrderDialog(context, _categoryService);
            },
          ),
        ],
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

    // Hole die sortierte Liste von Kategorien
    final orderedCategories = _categoryService.getOrderedCategories();
    
    // Gruppiere Habits nach Kategorien
    Map<String?, List<Habit>> groupedHabits = {};
    
    // Füge eine Kategorie für Habits ohne Kategorie hinzu (erscheint am Ende)
    groupedHabits[null] = [];
    
    // Gruppiere alle Habits nach Kategorien
    for (var habit in _habits) {
      if (groupedHabits.containsKey(habit.category)) {
        groupedHabits[habit.category]!.add(habit);
      } else {
        groupedHabits[habit.category!] = [habit];
      }
    }
    
    // Sortiere alle Habits innerhalb jeder Kategorie alphabetisch nach Titel
    groupedHabits.forEach((category, habits) {
      habits.sort((a, b) => a.title.compareTo(b.title));
    });
    
    // Erstelle Liste von Widgets mit Kategorie-Überschriften und Habits
    List<Widget> allWidgets = [];
    
    // Füge erst alle Habits nach Kategorie hinzu (entsprechend der definierten Reihenfolge)
    for (var category in orderedCategories) {
      if (groupedHabits.containsKey(category) && groupedHabits[category]!.isNotEmpty) {
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
        for (var habit in groupedHabits[category]!) {
          allWidgets.add(_buildHabitItem(habit));
        }
        
        // Entferne die verarbeitete Kategorie
        groupedHabits.remove(category);
      }
    }
    
    // Füge alle Habits ohne Kategorie hinzu (wenn vorhanden)
    if (groupedHabits[null]!.isNotEmpty) {
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
      
      for (var habit in groupedHabits[null]!) {
        allWidgets.add(_buildHabitItem(habit));
      }
      
      groupedHabits.remove(null);
    }
    
    // Füge alle übrigen Kategorien hinzu, die nicht in der Sortierreihenfolge definiert waren
    for (var category in groupedHabits.keys) {
      if (category != null && groupedHabits[category]!.isNotEmpty) {
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
        for (var habit in groupedHabits[category]!) {
          allWidgets.add(_buildHabitItem(habit));
        }
      }
    }
    
    return ListView(
      children: allWidgets,
    );
  }
  
  Widget _buildHabitItem(Habit habit) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Slidable(
        key: Key(habit.id),
        endActionPane: ActionPane(
          motion: const BehindMotion(),
          extentRatio: 0.4, 
          dismissible: DismissiblePane(
            onDismissed: () => _deleteHabit(habit.id),
            confirmDismiss: () async {
              final confirmDelete = await showDialog(
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
              return confirmDelete == true;
            },
          ),
          children: [
            CustomSlidableAction(
              onPressed: (BuildContext context) async {
                final confirmDelete = await showDialog(
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

                if (confirmDelete == true) {
                  _deleteHabit(habit.id);
                }
              },
              padding: EdgeInsets.zero,
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              autoClose: true,
              borderRadius: const BorderRadius.all(Radius.circular(12)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.delete, size: 20, color: Colors.white),
                  SizedBox(height: 4),
                  Text(
                    'Löschen',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        child: HabitCard(
          habit: habit,
          onToggle: (_) {}, // In der All Habits Screen ist die Toggle-Funktion nicht relevant
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
          isEditable: true, 
          isToday: false, // Keine Checkbox anzeigen in der All Habits Ansicht
        ),
      ),
    );
  }
}