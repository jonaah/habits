import 'package:flutter/material.dart';
import '../models/habit.dart';
import '../services/habit_database.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_icon_picker.dart';

class HabitFormScreen extends StatefulWidget {
  final Habit? habit;
  
  const HabitFormScreen({Key? key, this.habit}) : super(key: key);

  @override
  _HabitFormScreenState createState() => _HabitFormScreenState();
}

class _HabitFormScreenState extends State<HabitFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _customDaysController = TextEditingController();
  final _dayOfMonthController = TextEditingController();
  final _categoryController = TextEditingController();
  
  IconData? _selectedIcon;
  FrequencyType _frequencyType = FrequencyType.daily;
  final List<int> _selectedDays = [];
  int _customDays = 1;
  int _dayOfMonth = 1;

  late HabitDatabase _database;
  
  @override
  void initState() {
    super.initState();
    _database = HabitDatabase();
    
    // If editing an existing habit, populate the form with its values
    if (widget.habit != null) {
      final habit = widget.habit!;
      _titleController.text = habit.title;
      _descriptionController.text = habit.description;
      _selectedIcon = habit.icon;
      _frequencyType = habit.frequency.type;
      
      if (habit.category != null) {
        _categoryController.text = habit.category!;
      }
      
      switch (_frequencyType) {
        case FrequencyType.daily:
          break;
        case FrequencyType.weekly:
          _selectedDays.addAll(habit.frequency.daysOfWeek);
          break;
        case FrequencyType.monthly:
          _dayOfMonth = habit.frequency.dayOfMonth;
          _dayOfMonthController.text = _dayOfMonth.toString();
          break;
        case FrequencyType.custom:
          _customDays = habit.frequency.customDays;
          _customDaysController.text = _customDays.toString();
          break;
      }
    }
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _customDaysController.dispose();
    _dayOfMonthController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _pickIcon() async {
    final IconData? result = await CustomIconPicker.showIconPicker(context, currentIcon: _selectedIcon);
    
    if (result != null) {
      setState(() {
        _selectedIcon = result;
      });
    }
  }

  void _toggleDaySelection(int day) {
    setState(() {
      if (_selectedDays.contains(day)) {
        _selectedDays.remove(day);
      } else {
        _selectedDays.add(day);
      }
    });
  }
  
  Future<void> _saveHabit() async {
    if (!_formKey.currentState!.validate()) return;
    
    HabitFrequency frequency;
    
    switch (_frequencyType) {
      case FrequencyType.daily:
        frequency = HabitFrequency.daily();
        break;
      case FrequencyType.weekly:
        if (_selectedDays.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bitte wähle mindestens einen Tag aus')),
          );
          return;
        }
        frequency = HabitFrequency.weekly(days: _selectedDays);
        break;
      case FrequencyType.monthly:
        final day = int.tryParse(_dayOfMonthController.text) ?? 1;
        if (day < 1 || day > 31) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bitte gib einen gültigen Tag des Monats ein (1-31)'),
            ),
          );
          return;
        }
        frequency = HabitFrequency.monthly(day: day);
        break;
      case FrequencyType.custom:
        final days = int.tryParse(_customDaysController.text) ?? 1;
        if (days < 1) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bitte gib eine positive Zahl ein'),
            ),
          );
          return;
        }
        frequency = HabitFrequency.custom(days: days);
        break;
    }
    
    if (widget.habit != null) {
      // Update existing habit
      final habit = Habit(
        widget.habit!.id,
        _titleController.text,
        _descriptionController.text,
        frequency,
        _selectedIcon,
        _categoryController.text.isNotEmpty ? _categoryController.text : null,
        widget.habit!.streak,
        widget.habit!.lastCompleted,
        List.from(widget.habit!.completedDates),
      );
      
      await _database.updateHabit(habit);
    } else {
      // Create new habit
      final habit = Habit.create(
        title: _titleController.text,
        description: _descriptionController.text,
        frequency: frequency,
        icon: _selectedIcon,
        category: _categoryController.text.isNotEmpty ? _categoryController.text : null,
      );
      
      await _database.addHabit(habit);
    }
    
    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.habit == null ? 'Neue Gewohnheit' : 'Gewohnheit bearbeiten'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveHabit,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Titel*',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Bitte gib einen Titel ein';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Beschreibung',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              
              // Icon Picker
              Row(
                children: [
                  const Text('Icon (optional):', style: AppTheme.titleStyle),
                  const SizedBox(width: 16),
                  InkWell(
                    onTap: _pickIcon,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _selectedIcon != null
                          ? Icon(_selectedIcon, size: 32)
                          : const Icon(Icons.add, size: 32),
                    ),
                  ),
                  if (_selectedIcon != null)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _selectedIcon = null),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Category
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(
                  labelText: 'Kategorie (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              
              // Frequency Type
              const Text('Häufigkeit:', style: AppTheme.titleStyle),
              const SizedBox(height: 8),
              _buildFrequencyTypeSelector(),
              const SizedBox(height: 16),
              
              // Frequency details based on selected type
              _buildFrequencyDetails(),
              const SizedBox(height: 24),
              
              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveHabit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Speichern'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildFrequencyTypeSelector() {
    return SegmentedButton<FrequencyType>(
      segments: const [
        ButtonSegment(
          value: FrequencyType.daily,
          label: Text('Täglich'),
          icon: Icon(Icons.calendar_today),
        ),
        ButtonSegment(
          value: FrequencyType.weekly,
          label: Text('Wöchentlich'),
          icon: Icon(Icons.view_week),
        ),
        ButtonSegment(
          value: FrequencyType.monthly,
          label: Text('Monatlich'),
          icon: Icon(Icons.calendar_month),
        ),
        ButtonSegment(
          value: FrequencyType.custom,
          label: Text('Benutzerdefiniert'),
          icon: Icon(Icons.tune),
        ),
      ],
      selected: {_frequencyType},
      onSelectionChanged: (Set<FrequencyType> selection) {
        setState(() {
          _frequencyType = selection.first;
        });
      },
    );
  }
  
  Widget _buildFrequencyDetails() {
    switch (_frequencyType) {
      case FrequencyType.daily:
        return const Text('Diese Gewohnheit wird täglich angezeigt.');
        
      case FrequencyType.weekly:
        return _buildWeekDaySelector();
        
      case FrequencyType.monthly:
        return _buildMonthlySelector();
        
      case FrequencyType.custom:
        return _buildCustomDaysSelector();
    }
  }
  
  Widget _buildWeekDaySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('An welchen Tagen?'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            _buildDayChip(1, 'Mo'),
            _buildDayChip(2, 'Di'),
            _buildDayChip(3, 'Mi'),
            _buildDayChip(4, 'Do'),
            _buildDayChip(5, 'Fr'),
            _buildDayChip(6, 'Sa'),
            _buildDayChip(7, 'So'),
          ],
        ),
      ],
    );
  }
  
  Widget _buildDayChip(int day, String label) {
    final isSelected = _selectedDays.contains(day);
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => _toggleDaySelection(day),
      backgroundColor: Colors.grey[200],
      selectedColor: AppTheme.primaryColor.withOpacity(0.7),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
  
  Widget _buildMonthlySelector() {
    return TextFormField(
      controller: _dayOfMonthController,
      decoration: const InputDecoration(
        labelText: 'Tag des Monats (1-31)',
        border: OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Bitte gib einen Tag ein';
        }
        final day = int.tryParse(value);
        if (day == null || day < 1 || day > 31) {
          return 'Gib eine Zahl zwischen 1 und 31 ein';
        }
        return null;
      },
    );
  }
  
  Widget _buildCustomDaysSelector() {
    return TextFormField(
      controller: _customDaysController,
      decoration: const InputDecoration(
        labelText: 'Alle X Tage',
        border: OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Bitte gib einen Wert ein';
        }
        final days = int.tryParse(value);
        if (days == null || days < 1) {
          return 'Gib eine positive Zahl ein';
        }
        return null;
      },
    );
  }
}