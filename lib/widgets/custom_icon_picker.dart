import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CustomIconPicker {
  static final List<IconData> _commonIcons = [
    Icons.fitness_center,
    Icons.directions_run,
    Icons.local_drink,
    Icons.restaurant,
    Icons.book,
    Icons.bedtime,
    Icons.water_drop,
    Icons.coffee,
    Icons.computer,
    Icons.language,
    Icons.music_note,
    Icons.brush,
    Icons.sports,
    Icons.self_improvement,
    Icons.spa,
    Icons.smoke_free,
    Icons.sports_basketball,
    Icons.monitor_heart,
    Icons.psychology,
    Icons.savings,
    Icons.payments,
    Icons.luggage,
    Icons.home,
    Icons.gamepad,
    Icons.school,
    Icons.timer,
    Icons.pets,
    Icons.hiking,
    Icons.medication,
    Icons.auto_stories,
    Icons.eco,
    Icons.emoji_emotions,
  ];

  static Future<IconData?> showIconPicker(BuildContext context, {IconData? currentIcon}) async {
    IconData? selectedIcon = currentIcon;
    
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Icon auswählen'),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 12.0,
                    runSpacing: 12.0,
                    children: _commonIcons.map((iconData) {
                      final bool isSelected = selectedIcon == iconData;
                      
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedIcon = iconData;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10.0),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.primaryColor : AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Icon(
                            iconData,
                            size: 32.0,
                            color: isSelected ? Colors.white : AppTheme.primaryColor,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Abbrechen'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, selectedIcon),
                  child: const Text('Auswählen'),
                ),
              ],
            );
          }
        );
      },
    );
    
    return selectedIcon;
  }
}