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
    // Zusätzliche Icons
    Icons.work,
    Icons.local_grocery_store,
    Icons.train,
    Icons.flight,
    Icons.directions_bike,
    Icons.pool,
    Icons.theaters,
    Icons.local_hospital,
    Icons.local_pharmacy,
    Icons.local_pizza,
    Icons.beach_access,
    Icons.casino,
    Icons.celebration,
    Icons.extension,
    Icons.memory,
    Icons.security,
    Icons.verified_user,
    Icons.vpn_key,
    Icons.fingerprint,
    Icons.headset,
    Icons.toys,
    Icons.construction,
    Icons.agriculture,
    Icons.stars,
    Icons.wb_sunny,
    Icons.wb_cloudy,
    Icons.wb_incandescent,
    Icons.wb_shade,
    Icons.ac_unit,
    Icons.air,
    // Neue Icons passend zu Gewohnheiten
    Icons.alarm,
    Icons.accessibility,
    Icons.rowing,
    Icons.directions_walk,
    Icons.nature,
    Icons.volunteer_activism,
    Icons.clean_hands,
    Icons.fastfood,
    Icons.cake,
    Icons.shopping_cart,
    Icons.attach_money,
    Icons.lightbulb,
    Icons.explore,
    Icons.group,
    Icons.share,
    Icons.thumb_up,
    Icons.question_mark,
    Icons.announcement,
    Icons.report,
    Icons.settings,
    Icons.help_outline,
    Icons.sync,
    Icons.replay,
    Icons.forward,
    Icons.reply,
    Icons.download,
    Icons.upload,
    Icons.storage,
    Icons.delete,
    Icons.archive,
    Icons.flag,
    Icons.visibility,
    Icons.visibility_off,
    Icons.location_on,
    Icons.notifications,
    Icons.comment,
    Icons.send,
    Icons.call,
    Icons.mail,
    Icons.contacts,
    Icons.camera_alt,
    Icons.videocam,
    Icons.mic,
    Icons.volume_up,
    Icons.volume_down,
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
                    spacing: 10.0,
                    runSpacing: 10.0,
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
                            size: 28.0,
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