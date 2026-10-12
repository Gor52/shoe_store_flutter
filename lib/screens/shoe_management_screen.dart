import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pocketbase/pocketbase.dart'; 
import '../models/shoe.dart';
import '../models/brand.dart';
import '../models/category.dart';
import '../repositories/shoe_repository.dart';

class ShoeManagementScreen extends StatefulWidget {
  const ShoeManagementScreen({super.key});

  @override
  State<ShoeManagementScreen> createState() => _ShoeManagementScreenState();
}

class _ShoeManagementScreenState extends State<ShoeManagementScreen> {
  List<Shoe> _shoes = [];
  List<Brand> _brands = [];
  List<Category> _categories = [];
  bool _isLoading = true;
  bool _showDeleted = false; 
  final ImagePicker _picker = ImagePicker();

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
      final repo = context.read<ShoeRepository>();
      final shoes = await repo.getAllShoesAdmin();
      final brands = await repo.getBrands();
      final categories = await repo.getCategories();
      if (mounted) {
        setState(() {
          _shoes = shoes;
          _brands = brands;
          _categories = categories;
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _bulkDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Архивация'),
        content: Text('Перенести выбранные товары (${_selectedIds.length}) в архив?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('В архив'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await context.read<ShoeRepository>().deleteMultipleShoes(_selectedIds.toList());
        _loadData();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      }
    }
  }

  Future<void> _bulkHardDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Физическое удаление'),
        content: Text('ВНИМАНИЕ: Выбранные товары (${_selectedIds.length}) будут удалены навсегда без возможности восстановления!'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade900),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить навсегда'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await context.read<ShoeRepository>().hardDeleteMultipleShoes(_selectedIds.toList());
        _loadData();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      }
    }
  }

  Future<void> _bulkRestore() async {
    try {
      await context.read<ShoeRepository>().restoreMultipleShoes(_selectedIds.toList());
      _loadData();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    }
  }

  Future<void> _hardDeleteSingle(Shoe shoe) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить навсегда?'),
        content: Text('Товар "${shoe.name}" будет полностью стерт из базы данных.'),
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
        await context.read<ShoeRepository>().hardDeleteShoe(shoe.id);
        _loadData();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      }
    }
  }

  Future<void> _showShoeDialog({Shoe? shoe}) async {
    final nameController = TextEditingController(text: shoe?.name ?? '');
    final priceController = TextEditingController(text: shoe?.price.toString() ?? '');
    String? selectedBrandId = shoe?.brandId ?? (_brands.isNotEmpty ? _brands.first.id : null);
    
    List<String> selectedCategoryIds = List.from(shoe?.categoryIds ?? []);
    Uint8List? selectedImageBytes;
    String? selectedImageName;
    bool isSaving = false;

    String? nameError;
    String? priceError;
    
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text(shoe == null ? 'Новая обувь' : 'Редактировать товар'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        try {
                          final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
                          if (pickedFile != null) {
                            final bytes = await pickedFile.readAsBytes();
                            setStateDialog(() {
                              selectedImageBytes = bytes;
                              selectedImageName = pickedFile.name;
                            });
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка выбора фото: $e')));
                        }
                      },
                      child: Container(
                        height: 160,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade300),
                          image: selectedImageBytes != null
                              ? DecorationImage(image: MemoryImage(selectedImageBytes!), fit: BoxFit.cover)
                              : (shoe?.hasValidImage == true
                                  ? DecorationImage(image: NetworkImage(shoe!.imageUrl!), fit: BoxFit.cover)
                                  : null),
                        ),
                        child: (selectedImageBytes == null && shoe?.hasValidImage != true)
                            ? const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text('Добавить фото', style: TextStyle(color: Colors.grey)),
                                ],
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (selectedImageBytes != null || shoe?.hasValidImage == true)
                      TextButton.icon(
                        onPressed: () async {
                          final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
                          if (pickedFile != null) {
                            final bytes = await pickedFile.readAsBytes();
                            setStateDialog(() {
                              selectedImageBytes = bytes;
                              selectedImageName = pickedFile.name;
                            });
                          }
                        },
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Изменить фото'),
                      ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Название',
                        errorText: nameError, 
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Введите название' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: priceController,
                      decoration: InputDecoration(
                        labelText: 'Цена',
                        errorText: priceError, 
                      ),
                      keyboardType: TextInputType.number,
                      validator: (val) => val == null || double.tryParse(val.trim()) == null ? 'Введите корректную цену' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Бренд'),
                      value: selectedBrandId,
                      items: _brands.map((b) => DropdownMenuItem(value: b.id, child: Text(b.name))).toList(),
                      onChanged: (val) => setStateDialog(() => selectedBrandId = val),
                      validator: (val) => val == null ? 'Выберите бренд' : null,
                    ),
                    const SizedBox(height: 16),
                    const Text('Категории:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8.0,
                      children: _categories.map((cat) {
                        return FilterChip(
                          label: Text(cat.name),
                          selected: selectedCategoryIds.contains(cat.id),
                          onSelected: (bool selected) {
                            setStateDialog(() {
                              if (selected) {
                                selectedCategoryIds.add(cat.id);
                              } else {
                                selectedCategoryIds.remove(cat.id);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(context), 
                child: const Text('Отмена'),
              ),
              FilledButton(
                onPressed: isSaving ? null : () async {
                  setStateDialog(() {
                    nameError = null;
                    priceError = null;
                  });

                  if (!formKey.currentState!.validate()) return;
                  
                  setStateDialog(() => isSaving = true);
                  try {
                    final price = double.parse(priceController.text.trim());
                    if (shoe == null) {
                      await context.read<ShoeRepository>().createShoe(
                        nameController.text.trim(), 
                        price, 
                        selectedBrandId!,
                        selectedCategoryIds,
                        imageBytes: selectedImageBytes,
                        imageName: selectedImageName,
                      );
                    } else {
                      await context.read<ShoeRepository>().updateShoe(
                        shoe.id, 
                        nameController.text.trim(), 
                        price, 
                        selectedBrandId!,
                        selectedCategoryIds,
                        imageBytes: selectedImageBytes,
                        imageName: selectedImageName,
                      );
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
                          priceError = errors['price']?['message'];
                        });
                      }
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
                      }
                    }
                  } finally {
                    setStateDialog(() => isSaving = false);
                  }
                },
                child: isSaving 
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Сохранить'),
              ),
            ],
          );
        }
      ),
    );
  }

  Future<void> _toggleDeleteStatus(Shoe shoe) async {
    try {
      final repo = context.read<ShoeRepository>();
      if (shoe.isDeleted) {
        await repo.restoreShoe(shoe.id); 
      } else {
        await repo.deleteShoe(shoe.id); 
      }
      _loadData();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayedShoes = _shoes.where((s) => _showDeleted ? s.isDeleted : !s.isDeleted).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedIds.isNotEmpty ? 'Выбрано: ${_selectedIds.length}' : 'Управление обувью'),
        actions: [
          IconButton(
            icon: Icon(_showDeleted ? Icons.visibility : Icons.visibility_off),
            tooltip: _showDeleted ? 'Скрыть удаленные' : 'Показать удаленные',
            onPressed: () => setState(() {
              _showDeleted = !_showDeleted;
              _selectedIds.clear();
            }),
          ),
          if (_selectedIds.isNotEmpty) ...[
            if (_showDeleted) ...[
              IconButton(
                icon: const Icon(Icons.restore, color: Colors.green),
                tooltip: 'Восстановить выбранные',
                onPressed: _bulkRestore,
              ),
              IconButton(
                icon: const Icon(Icons.delete_forever, color: Colors.red),
                tooltip: 'Удалить навсегда',
                onPressed: _bulkHardDelete,
              ),
            ] else ...[
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.orange),
                tooltip: 'В архив (мягкое удаление)',
                onPressed: _bulkDelete,
              ),
            ],
          ],
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showShoeDialog(),
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : displayedShoes.isEmpty
              ? Center(child: Text(_showDeleted ? 'Корзина пуста' : 'Нет товаров'))
              : ListView.builder(
                  itemCount: displayedShoes.length,
                  itemBuilder: (context, index) {
                    final shoe = displayedShoes[index];
                    final isSelected = _selectedIds.contains(shoe.id);

                    return Card(
                      color: shoe.isDeleted ? Colors.grey.shade200 : null, 
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Checkbox(
                              value: isSelected,
                              onChanged: (bool? value) {
                                setState(() {
                                  if (value == true) {
                                    _selectedIds.add(shoe.id);
                                  } else {
                                    _selectedIds.remove(shoe.id);
                                  }
                                });
                              },
                            ),
                            shoe.hasValidImage
                                ? Image.network(shoe.imageUrl!, width: 50, height: 50, fit: BoxFit.cover)
                                : Container(
                                    width: 50, height: 50,
                                    color: Colors.grey.shade300,
                                    child: const Icon(Icons.image_not_supported, color: Colors.grey),
                                  ),
                          ],
                        ),
                        title: Text(
                          shoe.name,
                          style: TextStyle(
                            decoration: shoe.isDeleted ? TextDecoration.lineThrough : null, 
                            color: shoe.isDeleted ? Colors.grey : Colors.black,
                          ),
                        ),
                        subtitle: Text('${shoe.price} руб. ${shoe.isDeleted ? '(В архиве)' : ''}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!shoe.isDeleted) 
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _showShoeDialog(shoe: shoe),
                              ),
                            IconButton(
                              icon: Icon(
                                shoe.isDeleted ? Icons.restore : Icons.delete,
                                color: shoe.isDeleted ? Colors.green : Colors.orange,
                              ),
                              tooltip: shoe.isDeleted ? 'Восстановить' : 'В архив',
                              onPressed: () => _toggleDeleteStatus(shoe),
                            ),
                            if (shoe.isDeleted)
                              IconButton(
                                icon: const Icon(Icons.delete_forever, color: Colors.red),
                                tooltip: 'Удалить навсегда',
                                onPressed: () => _hardDeleteSingle(shoe),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}