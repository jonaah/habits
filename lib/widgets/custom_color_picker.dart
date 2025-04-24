import 'package:flutter/material.dart';

class CustomColorPicker extends StatefulWidget {
  final Color? initialColor;
  final ValueChanged<Color> onColorSelected;
  
  const CustomColorPicker({
    Key? key,
    this.initialColor,
    required this.onColorSelected,
  }) : super(key: key);

  @override
  State<CustomColorPicker> createState() => _CustomColorPickerState();
  
  static Future<Color?> showColorPicker(
    BuildContext context, {
    Color? currentColor,
  }) async {
    return showDialog<Color?>(
      context: context,
      builder: (context) {
        Color? selectedColor = currentColor;
        
        return AlertDialog(
          title: const Text('Farbe wählen'),
          content: SingleChildScrollView(
            child: CustomColorPicker(
              initialColor: currentColor,
              onColorSelected: (color) {
                selectedColor = color;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(selectedColor),
              child: const Text('Auswählen'),
            ),
          ],
        );
      },
    );
  }
}

class _CustomColorPickerState extends State<CustomColorPicker> {
  late Color _selectedColor;
  
  // Predefined color palette
  final List<Color> _colorPalette = [
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.grey,
    Colors.blueGrey,
  ];
  
  @override
  void initState() {
    super.initState();
    _selectedColor = widget.initialColor ?? Colors.blue;
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Selected color preview
        Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            color: _selectedColor,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 16),
        
        // Color grid
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _colorPalette.map((color) {
            final isSelected = color.value == _selectedColor.value;
            
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedColor = color;
                  widget.onColorSelected(color);
                });
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.white : Colors.transparent,
                    width: 3,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 4,
                            spreadRadius: 1,
                          )
                        ]
                      : null,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}