import 'package:flutter/material.dart';
import '../models/habit.dart';
import '../services/habit_database.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_icon_picker.dart';
import '../widgets/custom_color_picker.dart';
import '../widgets/category_selector.dart';

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
  final _timesPerWeekController = TextEditingController();
  
  IconData? _selectedIcon;
  Color? _selectedColor;
  String? _selectedCategory;
  FrequencyType _frequencyType = FrequencyType.daily;
  final List<int> _selectedDays = [];
  int _customDays = 1;
  int _dayOfMonth = 1;
  int _timesPerWeek = 1;
  CustomFrequencyType? _customFrequencyType;

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
      _selectedColor = habit.color;
      _frequencyType = habit.frequency.type;
      _selectedCategory = habit.category;
      
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
          _customFrequencyType = habit.frequency.customType;
          if (_customFrequencyType == CustomFrequencyType.everyXDays) {
            _customDays = habit.frequency.customDays;
            _customDaysController.text = _customDays.toString();
          } else if (_customFrequencyType == CustomFrequencyType.timesPerWeek) {
            _timesPerWeek = habit.frequency.timesPerWeek;
            _timesPerWeekController.text = _timesPerWeek.toString();
          }
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
    _timesPerWeekController.dispose();
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
  
  Future<void> _pickColor() async {
    final Color? result = await CustomColorPicker.showColorPicker(
      context,
      currentColor: _selectedColor,
    );
    
    if (result != null) {
      setState(() {
        _selectedColor = result;
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
        if (_customFrequencyType == CustomFrequencyType.everyXDays) {
          final days = int.tryParse(_customDaysController.text) ?? 1;
          if (days < 1) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Bitte gib eine positive Zahl ein'),
              ),
            );
            return;
          }
          frequency = HabitFrequency(
            FrequencyType.custom,
            [],
            0,
            days,
            0,
            CustomFrequencyType.everyXDays
          );
        } else {
          final times = int.tryParse(_timesPerWeekController.text) ?? 1;
          if (times < 1 || times > 7) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Bitte gib eine Zahl zwischen 1 und 7 ein'),
              ),
            );
            return;
          }
          frequency = HabitFrequency(
            FrequencyType.custom,
            [],
            0,
            0,
            times,
            CustomFrequencyType.timesPerWeek
          );
        }
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
        _selectedCategory,
        widget.habit!.streak,
        widget.habit!.lastCompleted,
        List.from(widget.habit!.completedDates),
        _selectedColor,
      );
      
      await _database.updateHabit(habit);
    } else {
      // Create new habit
      final habit = Habit.create(
        title: _titleController.text,
        description: _descriptionController.text,
        frequency: frequency,
        icon: _selectedIcon,
        category: _selectedCategory,
        color: _selectedColor,
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
              
              // Icon and Color Picker
              Row(
                children: [
                  // Icon picker
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Icon:', style: AppTheme.titleStyle),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _pickIcon,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _selectedColor?.withOpacity(0.1) ?? 
                                   AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: _selectedIcon != null
                              ? Icon(
                                  _selectedIcon, 
                                  size: 32, 
                                  color: _selectedColor,
                                )
                              : const Icon(Icons.add, size: 32),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 24),
                  
                  // Color picker
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Farbe:', style: AppTheme.titleStyle),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _pickColor,
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: _selectedColor ?? Colors.grey,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                          child: _selectedColor == null
                              ? const Icon(Icons.color_lens, color: Colors.white)
                              : null,
                        ),
                      ),
                    ],
                  ),
                  
                  if (_selectedIcon != null || _selectedColor != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 16.0),
                      child: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() {
                          if (_selectedIcon != null && _selectedColor != null) {
                            // Show dialog to ask what to clear
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Löschen'),
                                content: const Text('Was möchtest du zurücksetzen?'),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      setState(() => _selectedIcon = null);
                                      Navigator.pop(context);
                                    },
                                    child: const Text('Icon'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      setState(() => _selectedColor = null);
                                      Navigator.pop(context);
                                    },
                                    child: const Text('Farbe'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _selectedIcon = null;
                                        _selectedColor = null;
                                      });
                                      Navigator.pop(context);
                                    },
                                    child: const Text('Beides'),
                                  ),
                                ],
                              ),
                            );
                          } else if (_selectedIcon != null) {
                            _selectedIcon = null;
                          } else {
                            _selectedColor = null;
                          }
                        }),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Category Selector
              CategorySelector(
                selectedCategory: _selectedCategory,
                onCategorySelected: (category) {
                  setState(() {
                    _selectedCategory = category;
                  });
                },
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
          icon: Icon(Icons.calendar_today),
          label: Text('Täglich'),
        ),
        ButtonSegment(
          value: FrequencyType.weekly,
          icon: Icon(Icons.view_week),
          label: Text('Wöchentlich'),
        ),
        ButtonSegment(
          value: FrequencyType.monthly,
          icon: Icon(Icons.calendar_month),
          label: Text('Monatlich'),
        ),
        ButtonSegment(
          value: FrequencyType.custom,
          icon: Icon(Icons.settings),
          label: Text('Benutzerdefiniert'),
        ),
      ],
      selected: {_frequencyType},
      onSelectionChanged: (Set<FrequencyType> selection) {
        setState(() {
          _frequencyType = selection.first;
          if (_frequencyType == FrequencyType.custom && _customFrequencyType == null) {
            _customFrequencyType = CustomFrequencyType.everyXDays; // Default to "Every X days" when custom is first selected
          }
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
        return _buildCustomFrequencySelector();
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
  
  Widget _buildCustomFrequencySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Art der benutzerdefinierten Häufigkeit:'),
        const SizedBox(height: 8),
        SegmentedButton<CustomFrequencyType>(
          segments: const [
            ButtonSegment(
              value: CustomFrequencyType.everyXDays,
              icon: Icon(Icons.repeat),
              label: Text('Alle X Tage'),
            ),
            ButtonSegment(
              value: CustomFrequencyType.timesPerWeek,
              icon: Icon(Icons.view_week),
              label: Text('X mal pro Woche'),
            ),
          ],
          selected: {_customFrequencyType ?? CustomFrequencyType.everyXDays},
          onSelectionChanged: (Set<CustomFrequencyType> selection) {
            setState(() {
              _customFrequencyType = selection.first;
            });
          },
        ),
        const SizedBox(height: 16),
        if (_customFrequencyType == CustomFrequencyType.everyXDays)
          _buildCustomDaysSelector()
        else if (_customFrequencyType == CustomFrequencyType.timesPerWeek)
          _buildTimesPerWeekSelector(),
      ],
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
  
  Widget _buildTimesPerWeekSelector() {
    return TextFormField(
      controller: _timesPerWeekController,
      decoration: const InputDecoration(
        labelText: 'Wie oft pro Woche? (1-7)',
        border: OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Bitte gib einen Wert ein';
        }
        final times = int.tryParse(value);
        if (times == null || times < 1 || times > 7) {
          return 'Gib eine Zahl zwischen 1 und 7 ein';
        }
        return null;
      },
    );
  }
}