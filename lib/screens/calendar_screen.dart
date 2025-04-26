import 'package:flutter/material.dart';
import '../models/habit.dart';
import '../services/habit_database.dart';
import '../services/event_bus.dart';
import '../widgets/calendar/calendar_constants.dart';
import '../widgets/calendar/calendar_view_model.dart';
import '../widgets/calendar/calendar_day_cell.dart';
import '../widgets/calendar/calendar_month_view.dart';
import '../widgets/calendar/calendar_year_view.dart';
import '../widgets/calendar/day_habits_dialog.dart';
import '../widgets/calendar/calendar_filter_dialog.dart';

/// Hauptkalender-Screen
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({Key? key}) : super(key: key);

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late final HabitDatabase _database;
  late final EventBus _eventBus;
  final CalendarViewModel _viewModel = CalendarViewModel();

  @override
  void initState() {
    super.initState();
    _database = HabitDatabase();
    _eventBus = EventBus();
    _loadHabits();

    // Listen for habit changes
    _eventBus.habitEvents.listen((_) => _loadHabits());
  }

  Future<void> _loadHabits() async {
    _viewModel.setLoading(true);
    final habits = _database.getAllHabits();
    _viewModel.updateHabits(habits);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _viewModel.isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              _buildViewTypeSelector(),
              _buildDateNavigator(),
              Expanded(
                child: _buildCalendarGrid(),
              ),
              if (_viewModel.hasActiveFilters)
                _buildActiveFiltersChips(),
            ],
          ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Center(child: Text('Kalender')),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: () => _showFilterDialog(context),
        ),
      ],
    );
  }

  Widget _buildViewTypeSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: SegmentedButton<CalendarViewType>(
        segments: CalendarConstants.viewTypeSegments,
        selected: {_viewModel.viewType},
        onSelectionChanged: (Set<CalendarViewType> newSelection) {
          _viewModel.viewType = newSelection.first;
          setState(() {});
        },
      ),
    );
  }

  Widget _buildDateNavigator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              _viewModel.navigateDate(false);
              setState(() {});
            },
          ),
          Text(
            _viewModel.dateNavigatorTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              _viewModel.navigateDate(true);
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    if (_viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return _viewModel.viewType == CalendarViewType.month
        ? _buildMonthCalendar()
        : _buildYearCalendar();
  }

  Widget _buildMonthCalendar() {
    return CalendarMonthView(
      focusDate: _viewModel.focusDate, 
      cellBuilder: (date) => CalendarDayCell(
        date: date,
        calendarViewModel: _viewModel,
        onTap: (date, habits) => _showDayHabitsDialog(context, date, habits),
      ),
    );
  }

  Widget _buildYearCalendar() {
    return CalendarYearView(
      focusDate: _viewModel.focusDate,
      cellBuilder: (date) => CalendarDayCell(
        date: date,
        calendarViewModel: _viewModel,
        mini: true,
        onTap: (date, habits) => _showDayHabitsDialog(context, date, habits),
      ),
    );
  }

  void _showDayHabitsDialog(BuildContext context, DateTime date, List<Habit> habits) {
    showDialog(
      context: context,
      builder: (context) => DayHabitsDialog(date: date, habits: habits),
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => CalendarFilterDialog(
        habits: _viewModel.habits,
        selectedHabit: _viewModel.selectedHabit,
        selectedIcon: _viewModel.selectedIcon,
        selectedColor: _viewModel.selectedColor,
        onHabitSelected: (habit) {
          _viewModel.selectedHabit = habit;
          _viewModel.applyFilters();
          setState(() {});
        },
        onIconSelected: (icon) {
          _viewModel.selectedIcon = icon;
          _viewModel.applyFilters();
          setState(() {});
        },
        onColorSelected: (color) {
          _viewModel.selectedColor = color;
          _viewModel.applyFilters();
          setState(() {});
        },
        onResetFilters: () {
          _viewModel.resetFilters();
          setState(() {});
        },
      ),
    );
  }

  Widget _buildActiveFiltersChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Wrap(
        spacing: 8.0,
        runSpacing: 4.0,
        children: [
          if (_viewModel.selectedHabit != null)
            _buildFilterChip(
              label: _viewModel.selectedHabit!.title,
              onDeleted: () {
                _viewModel.selectedHabit = null;
                _viewModel.applyFilters();
                setState(() {});
              },
            ),
          if (_viewModel.selectedIcon != null)
            _buildFilterChip(
              label: 'Icon',
              avatar: Icon(_viewModel.selectedIcon, size: 18),
              onDeleted: () {
                _viewModel.selectedIcon = null;
                _viewModel.applyFilters();
                setState(() {});
              },
            ),
          if (_viewModel.selectedColor != null)
            _buildFilterChip(
              label: 'Farbe',
              avatar: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: _viewModel.selectedColor,
                  shape: BoxShape.circle,
                ),
              ),
              onDeleted: () {
                _viewModel.selectedColor = null;
                _viewModel.applyFilters();
                setState(() {});
              },
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    Widget? avatar,
    required VoidCallback onDeleted,
  }) {
    return Chip(
      label: Text(label),
      avatar: avatar,
      onDeleted: onDeleted,
      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
    );
  }
}