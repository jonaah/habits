import 'package:flutter/material.dart';
import '../services/category_service.dart';
import '../theme/app_theme.dart';

class CategoryOrderDialog extends StatefulWidget {
  final List<String> categories;
  final Function(List<String>) onOrderChanged;

  const CategoryOrderDialog({
    Key? key,
    required this.categories,
    required this.onOrderChanged,
  }) : super(key: key);

  @override
  State<CategoryOrderDialog> createState() => _CategoryOrderDialogState();
}

class _CategoryOrderDialogState extends State<CategoryOrderDialog> {
  late List<String> _orderedCategories;

  @override
  void initState() {
    super.initState();
    _orderedCategories = List.from(widget.categories);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Kategorien sortieren',
              style: AppTheme.headingStyle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Ziehe die Kategorien, um ihre Anzeigereihenfolge zu ändern',
              style: AppTheme.subtitleStyle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              child: _orderedCategories.isEmpty
                  ? const Center(
                      child: Text(
                        'Keine Kategorien verfügbar',
                        style: AppTheme.subtitleStyle,
                      ),
                    )
                  : ReorderableListView.builder(
                      shrinkWrap: true,
                      itemCount: _orderedCategories.length,
                      onReorder: (oldIndex, newIndex) {
                        setState(() {
                          if (oldIndex < newIndex) {
                            newIndex -= 1;
                          }
                          final String item = _orderedCategories.removeAt(oldIndex);
                          _orderedCategories.insert(newIndex, item);
                        });
                      },
                      itemBuilder: (context, index) {
                        return Card(
                          key: ValueKey(_orderedCategories[index]),
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: const Icon(Icons.drag_handle),
                            title: Text(_orderedCategories[index]),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Abbrechen'),
                ),
                ElevatedButton(
                  onPressed: () {
                    widget.onOrderChanged(_orderedCategories);
                    Navigator.of(context).pop();
                  },
                  child: const Text('Speichern'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

void showCategoryOrderDialog(
  BuildContext context,
  CategoryService categoryService,
) {
  final categories = categoryService.getOrderedCategories();
  
  showDialog(
    context: context,
    builder: (context) => CategoryOrderDialog(
      categories: categories,
      onOrderChanged: (orderedCategories) async {
        await categoryService.saveCategoryOrder(orderedCategories);
      },
    ),
  );
}