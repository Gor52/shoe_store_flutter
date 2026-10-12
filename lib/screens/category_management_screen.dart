import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pocketbase/pocketbase.dart';
import '../models/category.dart';
import '../repositories/shoe_repository.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  List<Category> _categories = [];
  bool _isLoading = true;
  
  // Набор для множественного выбора
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _selectedIds.clear();
    });
    try {
      final categories = await context.read<ShoeRepository>().getCategories();
      if (mounted) setState(() => _categories = categories);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Массовое удаление категорий
  Future<void> _bulkDeleteCategories() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Множественное удаление'),
        content: Text('Точно удалить выбранные категории (${_selectedIds.length})?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await context.read<ShoeRepository>().deleteMultipleCategories(_selectedIds.toList());
        _loadData();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      }
    }
  }

  Future<void> _showDialog({Category? category}) async {
    final controller = TextEditingController(text: category?.name ?? '');

    String? nameError;
    
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text(
            category == null ? 'Новая категория' : 'Редактировать',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'Название категории', 
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.category),
                errorText: nameError,
              ),
              validator: (value) => value!.trim().isEmpty ? 'Введите название' : null,
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
            FilledButton(
              onPressed: () async {
                setStateDialog(() => nameError = null);

                if (!formKey.currentState!.validate()) return;
                
                try {
                  if (category == null) {
                    await context.read<ShoeRepository>().createCategory(controller.text.trim());
                  } else {
                    await context.read<ShoeRepository>().updateCategory(category.id, controller.text.trim());
                  }
                  if (context.mounted) Navigator.pop(context);
                  _loadData();
                } catch (e) {
                  if (e is ClientException) {
                    final responseData = e.response;
                    if (responseData.containsKey('data')) {
                      final errors = responseData['data'] as Map<String, dynamic>;
                      setStateDialog(() {
                        nameError = errors['name']?['message'];
                      });
                    }
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
                    }
                  }
                }
              },
              child: const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _delete(Category category) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удаление'),
        content: Text('Точно удалить категорию "${category.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Удалить')
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await context.read<ShoeRepository>().deleteCategory(category.id);
        _loadData();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedIds.isNotEmpty ? 'Выбрано: ${_selectedIds.length}' : 'Управление категориями'),
        actions: [
          if (_selectedIds.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              tooltip: 'Удалить выбранные',
              onPressed: _bulkDeleteCategories,
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Добавить'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 80, top: 8),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = _selectedIds.contains(cat.id);

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Checkbox(
                          value: isSelected,
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                _selectedIds.add(cat.id);
                              } else {
                                _selectedIds.remove(cat.id);
                              }
                            });
                          },
                        ),
                        CircleAvatar(
                          backgroundColor: Colors.green.shade50,
                          child: const Icon(Icons.category, color: Colors.green),
                        ),
                      ],
                    ),
                    title: Text(cat.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showDialog(category: cat)),
                        IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _delete(cat)),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}