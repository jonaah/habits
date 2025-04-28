import 'package:flutter/material.dart';
import '../services/category_service.dart';
import '../theme/app_theme.dart';

class CategorySelector extends StatefulWidget {
  final String? selectedCategory;
  final Function(String?) onCategorySelected;

  const CategorySelector({
    Key? key,
    this.selectedCategory,
    required this.onCategorySelected,
  }) : super(key: key);

  @override
  State<CategorySelector> createState() => _CategorySelectorState();
}

class _CategorySelectorState extends State<CategorySelector> {
  late CategoryService _categoryService;
  List<String> _categories = [];
  String? _selectedCategory;
  final TextEditingController _newCategoryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _categoryService = CategoryService();
    _selectedCategory = widget.selectedCategory;
    _loadCategories();
  }

  @override
  void dispose() {
    _newCategoryController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final categories = _categoryService.getAllCategories();
    setState(() {
      _categories = categories;
    });
  }

  void _showCategoryDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Kategorie auswählen'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // List of existing categories
                    if (_categories.isNotEmpty) ...[
                      const Text('Vorhandene Kategorien:'),
                      const SizedBox(height: 8),
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _categories.length,
                          itemBuilder: (context, index) {
                            final category = _categories[index];
                            return ListTile(
                              title: Text(category),
                              leading: Icon(
                                Icons.folder,
                                color: AppTheme.primaryColor,
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, size: 20),
                                onPressed: () async {
                                  await _categoryService.deleteCategory(category);
                                  final updatedCategories = _categoryService.getAllCategories();
                                  setState(() {
                                    _categories = updatedCategories;
                                  });
                                  
                                  // If the deleted category was selected, clear selection
                                  if (_selectedCategory == category) {
                                    _selectedCategory = null;
                                    widget.onCategorySelected(null);
                                  }
                                },
                              ),
                              onTap: () {
                                _selectedCategory = category;
                                widget.onCategorySelected(category);
                                Navigator.of(context).pop();
                              },
                            );
                          },
                        ),
                      ),
                      const Divider(),
                    ],
                    
                    // Add new category
                    const Text('Neue Kategorie:'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _newCategoryController,
                            decoration: const InputDecoration(
                              hintText: 'Kategorie Name',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () async {
                            final newCategory = _newCategoryController.text.trim();
                            if (newCategory.isNotEmpty) {
                              await _categoryService.addCategory(newCategory);
                              _newCategoryController.clear();
                              
                              final updatedCategories = _categoryService.getAllCategories();
                              setState(() {
                                _categories = updatedCategories;
                              });
                            }
                          },
                          child: const Text('Hinzufügen'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Abbrechen'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedCategory = null;
                    });
                    widget.onCategorySelected(null);
                    Navigator.of(context).pop();
                  },
                  child: const Text('Keine Kategorie'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Kategorie (optional):', style: AppTheme.titleStyle),
        const SizedBox(height: 8),
        InkWell(
          onTap: _showCategoryDialog,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedCategory ?? 'Keine Kategorie ausgewählt',
                  style: TextStyle(
                    color: _selectedCategory != null ? Colors.black : Colors.grey,
                  ),
                ),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
      ],
    );
  }
}