import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pocketbase/pocketbase.dart'; 
import '../models/brand.dart';
import '../repositories/shoe_repository.dart';

class BrandManagementScreen extends StatefulWidget {
  const BrandManagementScreen({super.key});

  @override
  State<BrandManagementScreen> createState() => _BrandManagementScreenState();
}

class _BrandManagementScreenState extends State<BrandManagementScreen> {
  List<Brand> _brands = [];
  bool _isLoading = true;
  final ImagePicker _picker = ImagePicker();

  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _loadBrands();
  }

  Future<void> _loadBrands() async {
    setState(() {
      _isLoading = true;
      _selectedIds.clear();
    });
    try {
      final brands = await context.read<ShoeRepository>().getBrands();
      if (mounted) setState(() => _brands = brands);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _bulkDeleteBrands() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Множественное удаление'),
        content: Text('Точно удалить выбранные бренды (${_selectedIds.length})?'),
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
        await context.read<ShoeRepository>().deleteMultipleBrands(_selectedIds.toList());
        _loadBrands();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка удаления: $e')));
      }
    }
  }

  Future<void> _showBrandDialog({Brand? brand}) async {
    final nameController = TextEditingController(text: brand?.name ?? '');
    final countryController = TextEditingController(text: brand?.country ?? '');
    final isEditing = brand != null;
    final formKey = GlobalKey<FormState>();

    Uint8List? selectedImageBytes;
    String? selectedImageName;
    bool isSaving = false;

    String? nameError;
    String? countryError;

    final hasExistingLogo = brand?.hasValidLogo == true;
    final existingLogoUrl = brand?.logoUrl;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text(isEditing ? 'Редактировать бренд' : 'Новый бренд'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade300),
                        image: selectedImageBytes != null
                            ? DecorationImage(image: MemoryImage(selectedImageBytes!), fit: BoxFit.contain)
                            : (hasExistingLogo && existingLogoUrl != null
                                ? DecorationImage(image: NetworkImage(existingLogoUrl), fit: BoxFit.contain)
                                : null),
                      ),
                      child: (selectedImageBytes == null && !hasExistingLogo)
                          ? const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate, size: 40, color: Colors.grey),
                                SizedBox(height: 8),
                                Text('Логотип бренда', style: TextStyle(color: Colors.grey)),
                              ],
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Название бренда', 
                      border: const OutlineInputBorder(),
                      errorText: nameError,
                    ),
                    validator: (value) => value!.trim().isEmpty ? 'Введите название' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: countryController,
                    decoration: InputDecoration(
                      labelText: 'Страна', 
                      border: const OutlineInputBorder(),
                      errorText: countryError, 
                    ),
                    validator: (value) => value!.trim().isEmpty ? 'Введите страну' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(context), 
              child: const Text('Отмена')
            ),
            FilledButton(
              onPressed: isSaving ? null : () async {
                setStateDialog(() {
                  nameError = null;
                  countryError = null;
                });

                if (!formKey.currentState!.validate()) return;
                
                setStateDialog(() => isSaving = true);
                try {
                  if (isEditing) {
                    await context.read<ShoeRepository>().updateBrand(
                      brand.id, 
                      nameController.text.trim(),
                      countryController.text.trim(),
                      imageBytes: selectedImageBytes,
                      imageName: selectedImageName,
                    );
                  } else {
                    await context.read<ShoeRepository>().createBrand(
                      nameController.text.trim(),
                      countryController.text.trim(),
                      imageBytes: selectedImageBytes,
                      imageName: selectedImageName,
                    );
                  }
                  if (context.mounted) Navigator.pop(context);
                  _loadBrands();
                } catch (e) {
                  // Обработка серверных ошибок с кодом 422
                  if (e is ClientException) {
                    final responseData = e.response;
                    if (responseData.containsKey('data')) {
                      final errors = responseData['data'] as Map<String, dynamic>;
                      setStateDialog(() {
                        nameError = errors['name']?['message'];
                        countryError = errors['country']?['message'];
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
        ),
      ),
    );
  }

  Future<void> _deleteBrand(Brand brand) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удаление'),
        content: Text('Точно удалить бренд "${brand.name}"?'),
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
        await context.read<ShoeRepository>().deleteBrand(brand.id);
        _loadBrands();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка удаления: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedIds.isNotEmpty ? 'Выбрано: ${_selectedIds.length}' : 'Управление брендами'),
        actions: [
          if (_selectedIds.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              tooltip: 'Удалить выбранные',
              onPressed: _bulkDeleteBrands,
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showBrandDialog(),
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _brands.length,
              itemBuilder: (context, index) {
                final brand = _brands[index];
                final isSelected = _selectedIds.contains(brand.id);

                return Card(
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
                                _selectedIds.add(brand.id);
                              } else {
                                _selectedIds.remove(brand.id);
                              }
                            });
                          },
                        ),
                        brand.hasValidLogo
                            ? Image.network(brand.logoUrl!, width: 50, height: 50, fit: BoxFit.contain)
                            : const CircleAvatar(
                                backgroundColor: Colors.transparent,
                                child: Icon(Icons.branding_watermark, color: Colors.blueGrey),
                              ),
                      ],
                    ),
                    title: Text(brand.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(brand.country), 
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _showBrandDialog(brand: brand),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteBrand(brand),
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