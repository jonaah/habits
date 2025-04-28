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
  List<String> _filteredCategories = [];
  String? _selectedCategory;
  final TextEditingController _newCategoryController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  int _selectedTabIndex = 0;

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
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final categories = _categoryService.getAllCategories();
    setState(() {
      _categories = categories;
      _filteredCategories = List.from(categories);
    });
  }

  void _filterCategories(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCategories = List.from(_categories);
      } else {
        _filteredCategories = _categories
            .where((category) => 
                category.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  Color _getCategoryColor(String category) {
    int hash = 0;
    for (var i = 0; i < category.length; i++) {
      hash = category.codeUnitAt(i) + ((hash << 5) - hash);
    }
    return HSLColor.fromAHSL(
      1.0, 
      (hash % 360).abs().toDouble(),
      0.6, 
      0.8, 
    ).toColor();
  }

  void _showCategoryDialog() {
    _selectedTabIndex = 0;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Kategorie auswählen',
                      style: AppTheme.headingStyle.copyWith(fontSize: 20),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTabButton(
                            'Vorhandene Kategorien',
                            index: 0,
                            selectedIndex: _selectedTabIndex,
                            onTap: () => setState(() => _selectedTabIndex = 0),
                          ),
                        ),
                        Expanded(
                          child: _buildTabButton(
                            'Neue Kategorie',
                            index: 1,
                            selectedIndex: _selectedTabIndex,
                            onTap: () => setState(() => _selectedTabIndex = 1),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_selectedTabIndex == 0) ...[
                      if (_categories.isNotEmpty) ...[
                        TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Kategorie suchen',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 0,
                              horizontal: 16,
                            ),
                          ),
                          onChanged: _filterCategories,
                        ),
                        const SizedBox(height: 16),
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: MediaQuery.of(context).size.height * 0.4,
                          ),
                          child: _filteredCategories.isEmpty 
                              ? const Center(
                                  child: Text('Keine Kategorien gefunden'),
                                )
                              : Scrollbar(
                                  child: GridView.builder(
                                    shrinkWrap: true,
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      childAspectRatio: 2.5,
                                      crossAxisSpacing: 10,
                                      mainAxisSpacing: 10,
                                    ),
                                    itemCount: _filteredCategories.length,
                                    itemBuilder: (context, index) {
                                      final category = _filteredCategories[index];
                                      final isSelected = _selectedCategory == category;
                                      final categoryColor = _getCategoryColor(category);
                                      
                                      return InkWell(
                                        onTap: () {
                                          setState(() {
                                            _selectedCategory = category;
                                          });
                                          widget.onCategorySelected(category);
                                          Navigator.of(context).pop();
                                        },
                                        borderRadius: BorderRadius.circular(12),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12, 
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isSelected 
                                                ? categoryColor 
                                                : categoryColor.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: categoryColor,
                                              width: isSelected ? 2 : 1,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  category,
                                                  style: TextStyle(
                                                    color: isSelected ? Colors.white : Colors.black87,
                                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              if (isSelected)
                                                const Icon(Icons.check, color: Colors.white, size: 20),
                                              IconButton(
                                                padding: const EdgeInsets.only(left: 32), 
                                                icon: Icon(
                                                  Icons.delete_outline,
                                                  size: 18,
                                                  color: isSelected ? Colors.white : Colors.black54,
                                                ),
                                                constraints: const BoxConstraints(),
                                                onPressed: () async {
                                                  await _categoryService.deleteCategory(category);
                                                  final updatedCategories = _categoryService.getAllCategories();
                                                  setState(() {
                                                    _categories = updatedCategories;
                                                    _filteredCategories = List.from(updatedCategories);
                                                  });
                                                  
                                                  if (_selectedCategory == category) {
                                                    _selectedCategory = null;
                                                    widget.onCategorySelected(null);
                                                  }
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                        ),
                      ] else
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 20.0),
                            child: Text('Keine Kategorien verfügbar.\nErstelle eine neue Kategorie.'),
                          ),
                        ),
                    ] else ...[
                      TextField(
                        controller: _newCategoryController,
                        decoration: const InputDecoration(
                          labelText: 'Kategorie Name',
                          hintText: 'z.B. Morgens, Arbeit, Sport',
                          border: OutlineInputBorder(),
                        ),
                        autofocus: true,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final newCategory = _newCategoryController.text.trim();
                            if (newCategory.isNotEmpty) {
                              await _categoryService.addCategory(newCategory);
                              _newCategoryController.clear();
                              
                              final updatedCategories = _categoryService.getAllCategories();
                              setState(() {
                                _categories = updatedCategories;
                                _filteredCategories = List.from(updatedCategories);
                                _selectedCategory = newCategory;
                              });
                              widget.onCategorySelected(newCategory);
                              Navigator.of(context).pop();
                            }
                          },
                          icon: const Icon(Icons.add_circle_outline),
                          label: const Text('Kategorie hinzufügen'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Tipp: Mit Kategorien kannst du ähnliche Gewohnheiten gruppieren.',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _selectedCategory = null;
                            });
                            widget.onCategorySelected(null);
                            Navigator.of(context).pop();
                          },
                          icon: const Icon(Icons.remove_circle_outline, size: 18),
                          label: const Text('Keine Kategorie'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Abbrechen'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
  
  Widget _buildTabButton(String text, {
    required int index, 
    required int selectedIndex,
    required VoidCallback onTap,
  }) {
    final isSelected = index == selectedIndex;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? AppTheme.primaryColor : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? AppTheme.primaryColor : Colors.black54,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = _selectedCategory != null 
        ? _getCategoryColor(_selectedCategory!)
        : Colors.grey;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Kategorie (optional):', style: AppTheme.titleStyle),
        const SizedBox(height: 8),
        InkWell(
          onTap: _showCategoryDialog,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(
                color: _selectedCategory != null 
                    ? categoryColor 
                    : Colors.grey,
                width: _selectedCategory != null ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(8),
              color: _selectedCategory != null 
                  ? categoryColor.withOpacity(0.1) 
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    if (_selectedCategory != null) ...[
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: categoryColor.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.folder,
                          color: categoryColor,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      _selectedCategory ?? 'Keine Kategorie ausgewählt',
                      style: TextStyle(
                        color: _selectedCategory != null 
                            ? Colors.black 
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
                Icon(
                  Icons.arrow_drop_down,
                  color: _selectedCategory != null 
                      ? categoryColor 
                      : Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}